// SPDownloadManager.mm
// (c) 2017 - 2019 opa334

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import "SPDownloadManager.h"

#import "../Defines.h"
#import "../SafariPlus.h"
#import "../Util.h"
#import "../Classes/AVActivityButton.h"
#import "SPDirectoryPickerNavigationController.h"
#import "SPDownload.h"
#import "SPDownloadInfo.h"
#import "SPLocalizationManager.h"
#import "SPPreferenceManager.h"
#import "SPCommunicationManager.h"
#import "SPCacheManager.h"
#import "SPStatusBarNotification.h"
#import "SPStatusBarNotificationWindow.h"
#import "SPFileManager.h"

#import "Extensions.h"

#import <WebKit/WKWebView.h>

@implementation SPDownloadManager

+ (instancetype)sharedInstance
{
	static SPDownloadManager* sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^
	{
		//Initialise instance
		sharedInstance = [[SPDownloadManager alloc] init];
	});
	return sharedInstance;
}

- (instancetype)init
{
	self = [super init];

	[self setUpDefaultDownloadURL];

	[self migrateFromSandbox];

	if(!preferenceManager.disableBarNotificationsEnabled)
	{
		//Init notification window for status bar notifications
		self.notificationWindow = [[SPStatusBarNotificationWindow alloc] init];
	}

	[self verifyDownloadStorageRevision];

	//Get downloads from file
	[self loadDownloadsFromDisk];

	//Configure session
	[self configureSession];

	return self;
}

- (void)setUpDefaultDownloadURL
{
	if(preferenceManager.customDefaultPathEnabled && preferenceManager.customDefaultPath && rocketBootstrapWorks)
	{
		self.defaultDownloadURL = [fileManager resolveSymlinkForURL:[NSURL fileURLWithPath:[@"/var" stringByAppendingString:preferenceManager.customDefaultPath]]];

		if([self createDownloadDirectoryIfNeeded])
		{
			return;
		}
	}
	else if(!rocketBootstrapWorks)
	{
		self.defaultDownloadURL = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingString:@"/Documents/Downloads"]];

		if([self createDownloadDirectoryIfNeeded])
		{
			return;
		}
	}

	self.defaultDownloadURL = [fileManager resolveSymlinkForURL:[NSURL fileURLWithPath:defaultDownloadPath]];
	[self createDownloadDirectoryIfNeeded];
}

- (BOOL)createDownloadDirectoryIfNeeded
{
	if(![fileManager fileExistsAtURL:self.defaultDownloadURL error:nil] || ![fileManager isDirectoryAtURL:self.defaultDownloadURL error:nil])
	{
		//Downloads directory doesn't exist -> try to create it
		return [fileManager createDirectoryAtURL:self.defaultDownloadURL withIntermediateDirectories:YES attributes:nil error:nil];
	}

	return YES;
}

- (void)migrateFromSandbox
{
  #ifndef NO_ROCKETBOOTSTRAP
	if(rocketBootstrapWorks)
	{
		NSURL* oldDownloadURL = [NSURL fileURLWithPath:oldDownloadPath];

		if([fileManager fileExistsAtURL:oldDownloadURL error:nil])
		{
			NSArray* fileURLs = [fileManager contentsOfDirectoryAtURL:oldDownloadURL
					     includingPropertiesForKeys:nil
					     options:0
					     error:nil];

			NSError* error;

			for(NSURL* fileURL in fileURLs)
			{
				[fileManager moveItemAtURL:fileURL toURL:[self.defaultDownloadURL URLByAppendingPathComponent:fileURL.lastPathComponent] error:&error];
			}

			if(!error)
			{
				[fileManager removeItemAtURL:oldDownloadURL error:nil];

				sendSimpleAlert([localizationManager localizedSPStringForKey:@"MIGRATION_TITLE"],
						[NSString stringWithFormat:[localizationManager localizedSPStringForKey:@"MIGRATION_MESSAGE"], oldDownloadPath, self.defaultDownloadURL.path]);
			}
		}
	}
  #endif
}

- (void)verifyDownloadStorageRevision
{
	if([cacheManager downloadStorageRevision] != currentDownloadStorageRevision)
	{
		[cacheManager clearDownloadCache];

		[cacheManager setDownloadStorageRevision:currentDownloadStorageRevision];
	}
}

- (NSURLSession*)sharedDownloadSession
{
	return self.downloadSession;
}

- (void)configureSession
{
	//Create background configuration for shared session
	NSURLSessionConfiguration* config = [NSURLSessionConfiguration
					     backgroundSessionConfigurationWithIdentifier:@"com.opa334.SafariPlus.sharedSession"];

	//Configure cellular access
	config.allowsCellularAccess = !preferenceManager.onlyDownloadOnWifiEnabled;

	//Create shared session with configuration
	self.downloadSession = [NSURLSession sessionWithConfiguration:config
				delegate:self delegateQueue:nil];

	self.errorCount = 0;	//Counts how many errors exists
	self.processedErrorCount = 0;	//Counts how many errors are processed

	[self.downloadSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks)
	{
		for(NSURLSessionDownloadTask* task in downloadTasks)
		{
			//Reconnect sessions that are still running (for example after a respring)
			if(task.state == NSURLSessionTaskStateRunning)
			{
				SPDownload* download = [self downloadWithTaskIdentifier:task.taskIdentifier];

				download.downloadTask = task;
			}
			else
			{
				//Count how often didCompleteWithError will get called
				self.errorCount++;
			}
		}

		if(self.errorCount == 0)
		{
			//If didCompleteWithError will not get called at all, we need to manually invoke resumeDownloadsFromDiskLoad
			[self resumeDownloadsFromDiskLoad];
		}
	}];
}

- (void)clearTempFiles
{
	[self clearTempFilesIgnorePendingDownloads:NO];
}

- (void)clearTempFilesIgnorePendingDownloads:(BOOL)ignorePendingDownloads
{
	//NOTE: Sometimes temp files are saved in /tmp and sometimes in caches

	//Get files in tmp directory
	NSArray* tmpFiles = [[NSFileManager defaultManager]
			     contentsOfDirectoryAtURL:[NSURL fileURLWithPath:NSTemporaryDirectory()]
			     includingPropertiesForKeys:nil
			     options:0
			     error:nil];

	//Get files in caches directory
	NSArray* cacheFiles = [[NSFileManager defaultManager]
			       contentsOfDirectoryAtURL:[NSURL fileURLWithPath:[NSHomeDirectory()
										stringByAppendingString:@"/Library/Caches/com.apple.nsurlsessiond/Downloads/com.apple.mobilesafari"]]
			       includingPropertiesForKeys:nil
			       options:0
			       error:nil];

	//Join arrays
	NSArray* fileURLs = [tmpFiles arrayByAddingObjectsFromArray:cacheFiles];

	for(NSURL* fileURL in fileURLs)
	{
		if([fileURL.lastPathComponent containsString:@"CFNetworkDownload"])
		{
			BOOL shouldDelete = YES;

			if(ignorePendingDownloads)
			{
				for(SPDownload* download in self.pendingDownloads)
				{
					if(download.resumeData)
					{
						NSString* tmpPath = [self pathForResumeData:download.resumeData];

						if([tmpPath isEqualToString:[fileURL path]])
						{
							shouldDelete = NO;
							break;
						}
					}
				}
			}

			if(shouldDelete)
			{
				//File is cached download -> remove it
				[[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
			}
		}
	}
}

- (void)cancelAllDownloads
{
	dlog(@"cancelAllDownloads");
	dlogDownloadManager();

	//Cancel all downloads
	[self.pendingDownloads makeObjectsPerformSelector:@selector(cancelDownload)];
}

- (void)clearDownloadHistory
{
	//Reinitialise array
	self.finishedDownloads = [NSMutableArray new];

	//Save changes
	[self saveDownloadsToDisk];

	//Reload download list
	[self.navigationControllerDelegate reloadDownloadList];
}

- (void)resumeDownloadsFromDiskLoad
{
	dlog(@"resumeDownloadsFromDiskLoad");
	dlogDownloadManager();

	//Resume / Start all downloads
	for(SPDownload* download in self.pendingDownloads)
	{
		[download startDownload];
	}
}

- (void)forceCancelDownload:(SPDownload*)download
{
	dlog(@"forceCancelDownload");
	dlogDownloadManager();

	[self downloadFinished:download];

	//Reload table
	[self.navigationControllerDelegate reloadEverything];
}

- (void)downloadFinished:(SPDownload*)download
{
	dlog(@"downloadFinished");
	dlogDownloadManager();

	if(download.resumeData)
	{
		[self removeTemporaryFileForResumeData:download.resumeData];
	}

	[self.finishedDownloads insertObject:download atIndex:0];
	[self.pendingDownloads removeObject:download];

	[self saveDownloadsToDisk];
}

- (void)removeDownloadFromHistory:(SPDownload*)download
{
	dlog(@"removeDownloadFromHistory");
	dlogDownloadManager();

	[self.finishedDownloads removeObject:download];

	[self saveDownloadsToDisk];

	[self.navigationControllerDelegate reloadDownloadList];
}

//Retrieves temp path from resumeData
- (NSString*)pathForResumeData:(NSData*)resumeData
{
	//Parse resumeData
	NSDictionary* resumeDataDict = [NSPropertyListSerialization
					propertyListWithData:resumeData options:NSPropertyListImmutable
					format:nil error:nil];

	if([[resumeDataDict objectForKey:@"$archiver"] isEqualToString:@"NSKeyedArchiver"])
	{
		resumeDataDict = decodeResumeData12(resumeData);
	}

	NSString* filename = [resumeDataDict objectForKey:@"NSURLSessionResumeInfoTempFileName"];

	if(filename)
	{
		return [NSTemporaryDirectory() stringByAppendingString:filename];
	}
	else
	{
		return [resumeDataDict objectForKey:@"NSURLSessionResumeInfoLocalPath"];
	}
}

//Removes the temp file after a download has been cancelled
- (void)removeTemporaryFileForResumeData:(NSData*)resumeData
{
	dlog(@"removeTemporaryFileForResumeData");
	dlogDownloadManager();

	NSString* resumeDataPath = [self pathForResumeData:resumeData];

	if(resumeDataPath)
	{
		NSURL* tmpFileURL = [NSURL fileURLWithPath:resumeDataPath];

		[fileManager removeItemAtURL:tmpFileURL error:nil];
	}
}

- (void)loadDownloadsFromDisk
{
	dlog(@"loadDownloadsFromDisk");

	NSDictionary* downloadCache = [cacheManager loadDownloadCache];

	self.pendingDownloads = [[downloadCache objectForKey:@"pendingDownloads"] mutableCopy];
	if(!self.pendingDownloads)
	{
		self.pendingDownloads = [NSMutableArray new];
	}

	self.finishedDownloads = [[downloadCache objectForKey:@"finishedDownloads"] mutableCopy];
	if(!self.finishedDownloads)
	{
		self.finishedDownloads = [NSMutableArray new];
	}

	for(SPDownload* download in self.pendingDownloads)
	{
		//Set downloadManagerDelegate for all downloads
		download.downloadManagerDelegate = self;
	}

	dlogDownloadManager();
}

- (void)saveDownloadsToDisk
{
	[cacheManager saveDownloadCache:@{@"pendingDownloads" : [self.pendingDownloads copy], @"finishedDownloads" : [self.finishedDownloads copy]}];
}

- (void)sendNotificationWithText:(NSString*)text
{
	if([[UIApplication sharedApplication] applicationState] == 0 &&
	   !preferenceManager.disableBarNotificationsEnabled && self.notificationWindow)
	{
		//Application is active -> Use status bar notification if not disabled
		//Dissmiss current status notification (if one exists)
		[self.notificationWindow dismissWithCompletion:^
		{
			//Dispatch status notification with given text
			[self.notificationWindow dispatchNotification:[SPStatusBarNotification downloadStyleWithText:text]];
		}];
	}
	else if([[UIApplication sharedApplication] applicationState] != 0 &&
		!preferenceManager.disablePushNotificationsEnabled)
	{
		//Application is inactive -> Use push notification if not disabled
		[communicationManager dispatchPushNotificationWithIdentifier:@"com.apple.mobilesafari" title:@"Safari" message:text];
	}
}

- (int64_t)freeDiscspace
{
	int64_t freeSpace;	//Free space of device
	int64_t occupiedDownloadSpace = 0;	//Space that's 'reserved' for downloads
	int64_t totalFreeSpace;	//Total usable space

	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSDictionary* attributes = [fileManager attributesOfFileSystemForPath:[paths lastObject] error:nil];

	if(attributes)
	{
		freeSpace = ((NSNumber*)[attributes objectForKey:NSFileSystemFreeSize]).longLongValue;
	}

	for(SPDownload* download in [self.pendingDownloads copy])
	{
		occupiedDownloadSpace += [download remainingBytes];
	}

	totalFreeSpace = freeSpace - occupiedDownloadSpace;

	return totalFreeSpace;
}

- (BOOL)enoughDiscspaceForDownloadInfo:(SPDownloadInfo*)downloadInfo
{
	return downloadInfo.filesize <= [self freeDiscspace];
}

//When a download url was opened in a new tab, the tab will stay
//blank after an option was selected, this method closes that tab
- (void)closeDocumentIfObsoleteWithDownloadInfo:(SPDownloadInfo*)downloadInfo;
{
	if(downloadInfo)
	{
		if(![downloadInfo.sourceDocument URL] && !downloadInfo.sourceDocument.blankDocument)
		{
			[downloadInfo.sourceDocument _closeTabDocumentAnimated:YES];
		}
	}
}

- (SPDownload*)downloadWithTaskIdentifier:(NSUInteger)identifier
{
	for(SPDownload* download in [self.pendingDownloads copy])
	{
		if(download.taskIdentifier == identifier)
		{
			//Download taskIdentifier matches -> return download
			return download;
		}
	}
	return nil;
}

- (NSMutableArray*)downloadsAtURL:(NSURL*)url
{
	//Create mutable array
	NSMutableArray* downloadsAtURL = [NSMutableArray new];

	for(SPDownload* download in [self.pendingDownloads copy])
	{
		if([[fileManager resolveSymlinkForURL:download.targetURL].path isEqualToString:[fileManager resolveSymlinkForURL:url].path])
		{
			//Download is at specified URL -> add it to array
			[downloadsAtURL addObject:download];
		}
	}

	//Return array
	return downloadsAtURL;
}

- (BOOL)downloadExistsAtURL:(NSURL*)url
{
	for(SPDownload* download in [self.pendingDownloads copy])
	{
		//Get URL of download
		NSURL* downloadURL = [download.targetURL URLByAppendingPathComponent:download.filename];

		if([[fileManager resolveSymlinkForURL:downloadURL].path isEqualToString:[fileManager resolveSymlinkForURL:url].path])
		{
			//Download with URL exists
			return YES;
		}
	}
	//Download with URL doesn't exist
	return NO;
}

- (void)configureDownloadWithInfo:(SPDownloadInfo*)downloadInfo
{
	dlogDownloadInfo(downloadInfo, @"configureDownloadWithInfo");

	if(downloadInfo.customPath)
	{
		//Check if downloadInfo needs a custom path
		if(preferenceManager.pinnedLocationsEnabled)
		{
			//Pinned Locations enabled -> present them
			[self presentPinnedLocationsWithDownloadInfo:downloadInfo];
		}
		else
		{
			//Pinned Locations not enabled -> present directory picker
			[self presentDirectoryPickerWithDownloadInfo:downloadInfo];
		}
	}
	else
	{
		downloadInfo.targetURL = self.defaultDownloadURL;

		if([downloadInfo fileExists] || [self downloadExistsAtURL:[downloadInfo pathURL]])
		{
			//File or download exists -> present alert
			[self presentFileExistsAlertWithDownloadInfo:downloadInfo];
		}
		else if(![self enoughDiscspaceForDownloadInfo:downloadInfo])
		{
			//Not enough space for download
			[self presentNotEnoughSpaceAlertWithDownloadInfo:downloadInfo];
		}
		else
		{
			//All good -> start download
			[self startDownloadWithInfo:downloadInfo];
		}
	}
}

- (void)startDownloadWithInfo:(SPDownloadInfo*)downloadInfo
{
	dlogDownloadInfo(downloadInfo, @"startDownloadWithInfo");
	dlogDownloadManager();

	if(downloadInfo.image)
	{
		//Download is image -> Save it directly
		[self saveImageWithInfo:downloadInfo];
	}
	else if(downloadInfo.request)
	{
		//Create instance of SPDownload
		SPDownload* download = [[SPDownload alloc] initWithDownloadInfo:downloadInfo];

		//Set delegate for communication
		download.downloadManagerDelegate = self;

		//Start download
		[download startDownload];

		//Add download to array
		[self.pendingDownloads insertObject:download atIndex:0];

		//Save array to disk
		[self saveDownloadsToDisk];

		//Send notification
		[self sendNotificationWithText:[NSString stringWithFormat:@"%@: %@",
						[localizationManager localizedSPStringForKey:@"DOWNLOAD_STARTED"], downloadInfo.filename]];

		if(self.navigationControllerDelegate)
		{
			[self.navigationControllerDelegate reloadEverything];
		}
	}

	dlogDownloadManager();
}

- (void)saveImageWithInfo:(SPDownloadInfo*)downloadInfo
{
	//Remove existing file (if one exists)
	[downloadInfo removeExistingFile];

	//Write image to file
	NSURL* tmpURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:downloadInfo.filename];
	[UIImagePNGRepresentation(downloadInfo.image) writeToURL:tmpURL atomically:YES];
	[fileManager moveItemAtURL:tmpURL toURL:[downloadInfo pathURL] error:nil];

	//Send notification
	[self sendNotificationWithText:[NSString
					stringWithFormat:@"%@: %@", [localizationManager
								     localizedSPStringForKey:@"SAVED_IMAGE"], downloadInfo.filename]];
}

- (void)presentViewController:(UIViewController*)viewController withDownloadInfo:(SPDownloadInfo*)downloadInfo
{
	if(downloadInfo.presentationController)
	{
		if([viewController isKindOfClass:[UIAlertController class]])
		{
			UIAlertController* alertController = (UIAlertController*)viewController;

			if(alertController.preferredStyle == UIAlertControllerStyleActionSheet)
			{
				//Set sourceView (iPad)
				alertController.popoverPresentationController.sourceView =
					downloadInfo.presentationController.view;

				if(CGRectIsEmpty(downloadInfo.sourceRect))
				{
					//Fallback iPad positions to middle of screen (because no sourceRect was specified)
					alertController.popoverPresentationController.sourceRect =
						CGRectMake(downloadInfo.presentationController.view.bounds.size.width / 2,
							   downloadInfo.presentationController.view.bounds.size.height / 2, 1.0, 1.0);
				}
				else
				{
					//Set iPad positions to specified sourceRect
					alertController.popoverPresentationController.sourceRect = downloadInfo.sourceRect;
				}
			}
		}

		dispatch_async(dispatch_get_main_queue(), ^
		{
			[downloadInfo.presentationController presentViewController:viewController animated:YES completion:nil];
		});
	}
}

- (void)presentDownloadAlertWithDownloadInfo:(SPDownloadInfo*)downloadInfo
{
	if(downloadInfo.sourceVideo)
	{
		[downloadInfo.sourceVideo.downloadButton setSpinning:NO];
	}

	if(preferenceManager.instantDownloadsEnabled)
	{
		if(preferenceManager.instantDownloadsOption == 1)
		{
			//Start download
			[self configureDownloadWithInfo:downloadInfo];
		}
		else
		{
			//Start download with custom path
			downloadInfo.customPath = YES;
			[self configureDownloadWithInfo:downloadInfo];
		}

		[self closeDocumentIfObsoleteWithDownloadInfo:downloadInfo];
	}
	else
	{
		NSString* title;

		if(downloadInfo.filesize < 0)
		{
			//Size unknown (Happens on Google Drive for example)
			title = [NSString stringWithFormat:@"%@ (%@)", downloadInfo.filename,
				 [localizationManager localizedSPStringForKey:@"SIZE_UNKNOWN"]];
		}
		else if(downloadInfo.filesize)
		{
			//Filesize exists -> add it to title
			title = [NSString stringWithFormat:@"%@ (%@)", downloadInfo.filename,
				 [NSByteCountFormatter stringFromByteCount:downloadInfo.filesize
				  countStyle:NSByteCountFormatterCountStyleFile]];
		}
		else
		{
			//Filesize doesn't exist, just use filename as title
			title = downloadInfo.filename;
		}

		UIAlertController* downloadAlert = [UIAlertController
						    alertControllerWithTitle:title message:nil
						    preferredStyle:UIAlertControllerStyleActionSheet];

		//Download option
		UIAlertAction *downloadAction = [UIAlertAction
						 actionWithTitle:[localizationManager
								  localizedSPStringForKey:@"DOWNLOAD"]
						 style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
		{
			//Start download
			[self configureDownloadWithInfo:downloadInfo];
			[self closeDocumentIfObsoleteWithDownloadInfo:downloadInfo];
		}];

		[downloadAlert addAction:downloadAction];

		//Download to... option
		UIAlertAction *downloadToAction = [UIAlertAction
						   actionWithTitle:[localizationManager
								    localizedSPStringForKey:@"DOWNLOAD_TO"]
						   style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
		{
			//Start download with custom path
			downloadInfo.customPath = YES;
			[self configureDownloadWithInfo:downloadInfo];
			[self closeDocumentIfObsoleteWithDownloadInfo:downloadInfo];
		}];

		[downloadAlert addAction:downloadToAction];

		//Open option (not on videos)
		if(!downloadInfo.sourceVideo)
		{
			UIAlertAction *openAction = [UIAlertAction actionWithTitle:[localizationManager
										    localizedSPStringForKey:@"OPEN"]
						     style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
			{
				//Load request again and avoid another alert
				showAlert = NO;
				[downloadInfo.sourceDocument.webView loadRequest:downloadInfo.request];
			}];

			[downloadAlert addAction:openAction];
		}

		//Copy link options
		UIAlertAction *copyLinkAction = [UIAlertAction
						 actionWithTitle:[localizationManager
								  localizedSPStringForKey:@"COPY_LINK"]
						 style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
		{
			[UIPasteboard generalPasteboard].string = downloadInfo.request.URL.absoluteString;
		}];

		[downloadAlert addAction:copyLinkAction];

		//Cancel option
		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[localizationManager
									      localizedSPStringForKey:@"CANCEL"]
					       style:UIAlertActionStyleCancel handler:^(UIAlertAction * action)
		{
			[self closeDocumentIfObsoleteWithDownloadInfo:downloadInfo];
		}];
		[downloadAlert addAction:cancelAction];

		[self presentViewController:downloadAlert withDownloadInfo:downloadInfo];
	}
}

- (void)prepareVideoDownloadForDownloadInfo:(SPDownloadInfo*)downloadInfo
{
	if(downloadInfo.sourceVideo)
	{
		[downloadInfo.sourceVideo.downloadButton setSpinning:YES];
	}

	NSString* fetchVideoURL = [NSString stringWithFormat:
				   @"var videos = document.querySelectorAll('video');"
				   @"var i = 0;"
				   @"while(i < videos.length)"
				   @"{"
				   @"if(videos[i].webkitDisplayingFullscreen)"
				   @"{"
				   @"videos[i].currentSrc;"
				   @"break;"
				   @"}"
				   @"i++;"
				   @"}"];

	NSArray<SafariWebView*>* webViews = activeWebViews();

	unsigned int webViewCount = [webViews count];
	__block unsigned int webViewPos = 0;
	__weak SPDownloadInfo* _downloadInfo = downloadInfo;

	//Check all active webViews (2 at most) for the video URL
	for(SafariWebView* webView in webViews)
	{
		[webView evaluateJavaScript:fetchVideoURL completionHandler:^(id result, NSError *error)
		{
			webViewPos++;
			if(result)
			{
				NSURL* videoURL = [NSURL URLWithString:result];
				downloadInfo.request = [NSURLRequest requestWithURL:videoURL];

				[downloadManager prepareDownloadFromRequestForDownloadInfo:downloadInfo];
			}
			else if(webViewPos == webViewCount)
			{
				[_downloadInfo.sourceVideo setBackgroundPlaybackActiveWithCompletion:^
				{
					MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef information)
								       {
									       NSDictionary* info = (__bridge NSDictionary*)(information);

										//This whole method of retrieving the video url only works because it is set as the title by Safari / WebKit, hopefully that doesn't change in the future
										//Plot Twist: It did change in iOS 12 :(
									       NSURL* videoURL = [NSURL URLWithString:[info objectForKey:(__bridge NSString*)(kMRMediaRemoteNowPlayingInfoTitle)]];

									       if(videoURL)
									       {
										       _downloadInfo.request = [NSURLRequest requestWithURL:videoURL];

										       [downloadManager prepareDownloadFromRequestForDownloadInfo:downloadInfo];
									       }
									       else
									       {
										       if(downloadInfo.sourceVideo)
										       {
											       [downloadInfo.sourceVideo.downloadButton setSpinning:NO];
										       }
										       [self presentVideoURLNotFoundErrorWithDownloadInfo:downloadInfo];
									       }
								       });
				}];
			}
		}];
	}
}

- (void)prepareDownloadFromRequestForDownloadInfo:(SPDownloadInfo*)downloadInfo
{
	dlogDownloadInfo(downloadInfo, @"prepareDownloadFromRequestForDownloadInfo");
	dlogDownloadManager();

	if(!self.requestFetchDownloadInfo)
	{
		NSURLSession* session = self.downloadSession;

		NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:downloadInfo.request];

		self.requestFetchDownloadInfo = downloadInfo;

		[dataTask resume];

		//After 5 seconds we cancel the task and error out
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^
		{
			if(dataTask.state == NSURLSessionTaskStateRunning)
			{
				[dataTask cancel];
				self.requestFetchDownloadInfo = nil;

				if(downloadInfo.sourceVideo)
				{
					[downloadInfo.sourceVideo.downloadButton setSpinning:NO];
				}

				UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"ERROR"]
								 message:[localizationManager localizedSPStringForKey:@"UNABLE_TO_FETCH_FILE_INFORMATION"] preferredStyle:UIAlertControllerStyleAlert];

				UIAlertAction* closeAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CLOSE"] style:UIAlertActionStyleDefault handler:nil];

				[errorAlert addAction:closeAction];

				[downloadInfo.presentationController presentViewController:errorAlert animated:YES completion:nil];
			}
		});
	}
}

- (void)presentDirectoryPickerWithDownloadInfo:(SPDownloadInfo*)downloadInfo
{
	SPDirectoryPickerNavigationController* directoryPicker =
		[[SPDirectoryPickerNavigationController alloc] initWithStartURL:self.defaultDownloadURL];

	directoryPicker.pickerDelegate = self;
	directoryPicker.placeholderFilename = downloadInfo.filename;

	self.pickerDownloadInfo = downloadInfo;

	[self presentViewController:directoryPicker withDownloadInfo:downloadInfo];
}

- (void)presentPinnedLocationsWithDownloadInfo:(SPDownloadInfo*)downloadInfo
{
	//Get pinned locations
	NSArray* pinnedLocations = preferenceManager.pinnedLocations;

	UIAlertController* pinnedLocationAlert = [UIAlertController
						  alertControllerWithTitle:[localizationManager
									    localizedSPStringForKey:@"PINNED_LOCATIONS"] message:nil
						  preferredStyle:UIAlertControllerStyleActionSheet];

	for(NSDictionary* pinnedLocation in pinnedLocations)
	{
		//Add option for each location
		[pinnedLocationAlert addAction:[UIAlertAction actionWithTitle:[pinnedLocation objectForKey:@"name"]
						style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
		{
			//Get index of tapped action
			NSInteger index = [pinnedLocationAlert.actions indexOfObject:action];

			//Get URL from index
			__block NSURL* pathURL = [NSURL fileURLWithPath:[pinnedLocations[index] objectForKey:@"path"]];

			//Alert for filename
			UIAlertController* filenameAlert = [UIAlertController
							    alertControllerWithTitle:[localizationManager
										      localizedSPStringForKey:@"CHOOSE_FILENAME"] message:nil
							    preferredStyle:UIAlertControllerStyleAlert];

			//Add textfield
			[filenameAlert addTextFieldWithConfigurationHandler:^(UITextField *textField)
			{
				textField.placeholder = [localizationManager
							 localizedSPStringForKey:@"FILENAME"];
				textField.textColor = [UIColor blackColor];
				textField.clearButtonMode = UITextFieldViewModeWhileEditing;
				textField.borderStyle = UITextBorderStyleNone;
				textField.text = downloadInfo.filename;
			}];

			//Choose option
			UIAlertAction* chooseAction = [UIAlertAction actionWithTitle:
						       [localizationManager localizedSPStringForKey:@"CHOOSE"]
						       style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
			{
				downloadInfo.filename = filenameAlert.textFields[0].text;

				//Resolve possible symlinks
				pathURL = [fileManager resolveSymlinkForURL:pathURL];

				//Set selected path
				downloadInfo.targetURL = pathURL;

				[self pathSelectionResponseWithDownloadInfo:downloadInfo];
			}];

			[filenameAlert addAction:chooseAction];

			//Cancel option
			UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:
						       [localizationManager localizedSPStringForKey:@"CANCEL"]
						       style:UIAlertActionStyleCancel handler:nil];

			[filenameAlert addAction:cancelAction];

			//Present filename alert
			[self presentViewController:filenameAlert withDownloadInfo:downloadInfo];
		}]];
	}

	//Browse option
	UIAlertAction* browseAction = [UIAlertAction actionWithTitle:
				       [localizationManager localizedSPStringForKey:@"BROWSE"]
				       style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
	{
		//Present directory picker
		[self presentDirectoryPickerWithDownloadInfo:downloadInfo];
	}];

	[pinnedLocationAlert addAction:browseAction];

	//Cancel option
	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:
				       [localizationManager localizedSPStringForKey:@"CANCEL"]
				       style:UIAlertActionStyleCancel handler:nil];

	[pinnedLocationAlert addAction:cancelAction];

	//Present pinned location sheet
	[self presentViewController:pinnedLocationAlert withDownloadInfo:downloadInfo];
}

- (void)presentFileExistsAlertWithDownloadInfo:(SPDownloadInfo*)downloadInfo
{
	//Create error alert
	UIAlertController *errorAlert = [UIAlertController
					 alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"ERROR"]
					 message:[localizationManager localizedSPStringForKey:@"FILE_EXISTS_MESSAGE"]
					 preferredStyle:UIAlertControllerStyleAlert];

	//Replace action
	UIAlertAction *replaceAction = [UIAlertAction
					actionWithTitle:[localizationManager localizedSPStringForKey:@"REPLACE_FILE"]
					style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
	{
		[self startDownloadWithInfo:downloadInfo];
	}];

	//Change path action
	UIAlertAction *changePathAction = [UIAlertAction
					   actionWithTitle:[localizationManager localizedSPStringForKey:@"CHANGE_PATH"]
					   style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
	{
		downloadInfo.customPath = YES;
		[self configureDownloadWithInfo:downloadInfo];
	}];

	//Do nothing
	UIAlertAction *cancelAction = [UIAlertAction
				       actionWithTitle:[localizationManager localizedSPStringForKey:@"CANCEL"]
				       style:UIAlertActionStyleCancel handler:nil];

	//Add actions to alert
	[errorAlert addAction:replaceAction];
	[errorAlert addAction:changePathAction];
	[errorAlert addAction:cancelAction];

	//Present alert
	[self presentViewController:errorAlert withDownloadInfo:downloadInfo];
}

- (void)presentNotEnoughSpaceAlertWithDownloadInfo:(SPDownloadInfo*)downloadInfo
{
	//Create error alert
	UIAlertController *errorAlert = [UIAlertController
					 alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"ERROR"]
					 message:[localizationManager localizedSPStringForKey:@"NOT_ENOUGH_SPACE_MESSAGE"]
					 preferredStyle:UIAlertControllerStyleAlert];

	//Do nothing
	UIAlertAction *cancelAction = [UIAlertAction
				       actionWithTitle:[localizationManager localizedSPStringForKey:@"CLOSE"]
				       style:UIAlertActionStyleCancel handler:nil];

	[errorAlert addAction:cancelAction];

	//Present alert
	[self presentViewController:errorAlert withDownloadInfo:downloadInfo];
}

- (void)presentVideoURLNotFoundErrorWithDownloadInfo:(SPDownloadInfo*)downloadInfo
{
	UIAlertController *errorAlert = [UIAlertController
					 alertControllerWithTitle:[localizationManager
								   localizedSPStringForKey:@"ERROR"] message:[localizationManager
													      localizedSPStringForKey:@"VIDEO_URL_NOT_FOUND"]
					 preferredStyle:UIAlertControllerStyleAlert];

	UIAlertAction *closeAction = [UIAlertAction actionWithTitle:[localizationManager
								     localizedSPStringForKey:@"CLOSE"]
				      style:UIAlertActionStyleCancel handler:nil];

	[errorAlert addAction:closeAction];

	dispatch_async(dispatch_get_main_queue(), ^
	{
		[downloadInfo.presentationController presentViewController:errorAlert animated:YES completion:nil];
	});
}

- (void)directoryPicker:(id)directoryPicker didSelectDirectoryAtURL:(NSURL*)selectedURL withFilename:(NSString*)filename
{
	if(!selectedURL)
	{
		self.pickerDownloadInfo = nil;
		return;
	}

	SPDownloadInfo* downloadInfo = self.pickerDownloadInfo;
	self.pickerDownloadInfo = nil;

	downloadInfo.filename = filename;
	downloadInfo.targetURL = selectedURL;

	[self pathSelectionResponseWithDownloadInfo:downloadInfo];
}

- (void)pathSelectionResponseWithDownloadInfo:(SPDownloadInfo*)downloadInfo
{
	if([downloadInfo fileExists] || [self downloadExistsAtURL:[downloadInfo pathURL]])
	{
		//File or download already exists -> present file exists alert
		[self presentFileExistsAlertWithDownloadInfo:downloadInfo];
	}
	else if(![self enoughDiscspaceForDownloadInfo:downloadInfo])
	{
		//Not enough space for download
		[self presentNotEnoughSpaceAlertWithDownloadInfo:downloadInfo];
	}
	else
	{
		//Nothing exists -> start download
		[self startDownloadWithInfo:downloadInfo];
	}
}

- (void)URLSession:(NSURLSession *)session
	downloadTask:(NSURLSessionDownloadTask *)downloadTask
	didFinishDownloadingToURL:(NSURL *)location
{
	dlog(@"URLSession:%@ downloadTask:%@ didFinishDownloadingToURL:%@", session, downloadTask, location);
	dlogDownloadManager();

	//Get finished download
	SPDownload* download = [self downloadWithTaskIdentifier:downloadTask.taskIdentifier];

	download.didFinish = YES;

	//Get real file size and apply it to download
	NSNumber* size;
	[fileManager URLResourceValue:&size forKey:NSURLFileSizeKey forURL:location error:nil];
	download.filesize = [size longLongValue];

	//Get downloadInfo from download
	SPDownloadInfo* downloadInfo = [[SPDownloadInfo alloc] initWithDownload:download];

	//Remove file if it exists
	[downloadInfo removeExistingFile];

	//Move downloaded file to desired location
	[fileManager moveItemAtURL:location toURL:[downloadInfo pathURL] error:nil];

	//Dispatch status bar / push notification
	[self sendNotificationWithText:[NSString stringWithFormat:@"%@: %@",
					[localizationManager localizedSPStringForKey:@"DOWNLOAD_SUCCESS"], download.filename]];

	//Mark download as finished
	[self downloadFinished:download];

	//Reload browser and downloads
	[self.navigationControllerDelegate reloadBrowser];
	[self.navigationControllerDelegate reloadDownloadList];

	//Save array
	[self saveDownloadsToDisk];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
	didCompleteWithError:(NSError *)error
{
	dlog(@"URLSession:%@ task:%@ didCompleteWithError:%@", session, task, error);
	dlogDownloadManager();

	if(error)
	{
		//Get download
		SPDownload* download = [self downloadWithTaskIdentifier:task.taskIdentifier];

		if(!download)
		{
			return;
		}

		if(error.code == -999)
		{
			if([error.localizedDescription isEqualToString:@"cancelled"])
			{
				if(download.didFinish)
				{
					//Remove download from array
					[self downloadFinished:download];
					[self.navigationControllerDelegate reloadEverything];
				}
			}
			else
			{
				//Get resumeData
				NSData* resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];

				//Connect resumeData with download
				download.resumeData = resumeData;

				//Count how often this method was called
				self.processedErrorCount++;

				if(self.processedErrorCount == self.errorCount)
				{
					//Function was called as often as expected -> resume all downloads
					[self resumeDownloadsFromDiskLoad];
				}
			}
		}
		else
		{
			NSData* resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];

			if(resumeData)
			{
				download.resumeData = resumeData;
			}

			[download setPaused:YES forced:YES];
		}

		//Save downloads to disk
		[self saveDownloadsToDisk];
	}
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
	didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten
	totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
	//Get download that needs updating
	SPDownload* targetDownload = [self downloadWithTaskIdentifier:downloadTask.taskIdentifier];

	//Send data to download
	[targetDownload updateProgress:totalBytesWritten totalFilesize:totalBytesExpectedToWrite];
}

//Get response for the request and present the download alert
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
	dlog(@"URLSession:%@ session:%@ didReceiveResponse:%@", session, dataTask, response);
	dlogDownloadManager();

	completionHandler(NSURLSessionResponseCancel);

	SPDownloadInfo* downloadInfo = self.requestFetchDownloadInfo;
	self.requestFetchDownloadInfo = nil;

	NSInteger statusCode = ((NSHTTPURLResponse*)response).statusCode;

	if(statusCode < 400)	//No error
	{
		downloadInfo.filesize = response.expectedContentLength;
		downloadInfo.filename = response.suggestedFilename;

		[self presentDownloadAlertWithDownloadInfo:downloadInfo];
	}
	else	//Error
	{
		UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"ERROR"]
						 message:[NSString stringWithFormat:@"%lli: %@", (long long)statusCode, [NSHTTPURLResponse localizedStringForStatusCode:statusCode]] preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction* closeAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CLOSE"] style:UIAlertActionStyleDefault handler:nil];

		[errorAlert addAction:closeAction];

		[downloadInfo.presentationController presentViewController:errorAlert animated:YES completion:nil];

		if(downloadInfo.sourceVideo)
		{
			[downloadInfo.sourceVideo.downloadButton setSpinning:NO];
		}
	}
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
	dlog(@"URLSessionDidFinishEventsForBackgroundURLSession:%@", session);
	dlogDownloadManager();

	if(self.applicationBackgroundSessionCompletionHandler)
	{
		void (^completionHandler)() = self.applicationBackgroundSessionCompletionHandler;
		self.applicationBackgroundSessionCompletionHandler = nil;

		dispatch_async(dispatch_get_main_queue(), completionHandler);
	}
}

@end
