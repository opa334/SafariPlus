// Copyright (c) 2017-2019 Lars Fröder

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import "SPDownloadManager.h"

#import "../Defines.h"
#import "../SafariPlus.h"
#import "../Util.h"
#import "../Classes/UIButton+ActivityIndicator.h"
#import "../../Shared/NSFileManager+DirectorySize.h"
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
#import "SPMediaFetcher.h"

#import "Extensions.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <WebKit/WKWebView.h>
#import <UserNotifications/UserNotifications.h>
#import <AVFoundation/AVFoundation.h>

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

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0)
	{
		self.HLSSupported = YES;
	}

	_observerDelegates = [NSHashTable weakObjectsHashTable];

	[self setUpDefaultDownloadURL];

	[self migrateFromSandbox];

	if(preferenceManager.statusBarNotificationsEnabled)
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
			NSArray* fileURLs = [fileManager contentsOfDirectoryAtURL:oldDownloadURL includingPropertiesForKeys:nil options:0 error:nil];

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

- (AVAssetDownloadURLSession*)sharedAVDownloadSession
{
	return self.avDownloadSession;
}

- (void)configureSession
{
	//Create background configuration for shared session
	NSURLSessionConfiguration* config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.opa334.SafariPlus.sharedSession"];

	//Configure cellular access
	config.allowsCellularAccess = !preferenceManager.onlyDownloadOnWifiEnabled;

	//Create shared session with configuration
	self.downloadSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];

	[self reconnectDownloads];

	if(self.HLSSupported)
	{
		//Create background configuration for shared HLS session
		NSURLSessionConfiguration* HLSConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.opa334.SafariPlus.sharedSession.HLS"];

		//Configure cellular access
		HLSConfig.allowsCellularAccess = !preferenceManager.onlyDownloadOnWifiEnabled;

		self.avDownloadSession = [NSClassFromString(@"AVAssetDownloadURLSession") sessionWithConfiguration:HLSConfig assetDownloadDelegate:self delegateQueue:nil];

		[self reconnectHLSDownloads];
	}
}

- (void)reconnectDownloads
{
	self.errorCount = 0;	//Counts how many errors exists
	self.processedErrorCount = 0;	//Counts how many errors are processed

	[self.downloadSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks)
	{
		self.isReconnectingDownloads = YES;
		for(NSURLSessionDownloadTask* task in downloadTasks)
		{
			//Reconnect sessions that are still running (for example after a respring)
			if(task.state == NSURLSessionTaskStateRunning)
			{
				SPDownload* download = [self downloadWithTask:task];

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
			//If didCompleteWithError will not get called at all, we need to manually invoke didFinishReconnectingDownloads
			[self didFinishReconnectingDownloads];
		}
	}];
}

- (void)reconnectHLSDownloads
{
	[self.avDownloadSession getAllTasksWithCompletionHandler:^(NSArray<__kindof NSURLSessionTask*>* tasks)
	{
		for(AVAssetDownloadTask* task in tasks)
		{
			//Reconnect sessions that are still running (for example after a respring)
			if(task.state == NSURLSessionTaskStateRunning)
			{
				SPDownload* download = [self downloadWithTask:task];

				download.downloadTask = task;
			}
		}

		[self didFinishReconnectingHLSDownloads];
	}];
}

- (void)didFinishReconnectingDownloads
{
	dlog(@"didFinishReconnectingDownloads");
	dlogDownloadManager();

	self.isReconnectingDownloads = NO;

	//Resume / Start all downloads
	for(SPDownload* download in self.pendingDownloads)
	{
		if(!download.isHLSDownload)
		{
			[download startDownload];
		}
	}
}

- (void)didFinishReconnectingHLSDownloads
{
	for(SPDownload* download in self.pendingDownloads)
	{
		if(download.isHLSDownload)
		{
			[download startDownload];
		}
	}
}

- (void)clearTempFiles
{
	[self clearTempFilesIgnorePendingDownloads:NO];
}

- (void)clearTempFilesIgnorePendingDownloads:(BOOL)ignorePendingDownloads
{
	//NOTE: Sometimes temp files are saved in /tmp and sometimes in caches

	//Get files in tmp directory
	NSArray* tmpFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:NSTemporaryDirectory()] includingPropertiesForKeys:nil options:0 error:nil];

	//Get files in caches directory
	NSArray* cacheFiles = [[NSFileManager defaultManager]
			       contentsOfDirectoryAtURL:[NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingString:@"/Library/Caches/com.apple.nsurlsessiond/Downloads/com.apple.mobilesafari"]]
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

- (void)forceCancelDownload:(SPDownload*)download
{
	dlog(@"forceCancelDownload");
	dlogDownloadManager();

	[self downloadFinished:download];
}

- (void)downloadFinished:(SPDownload*)download
{
	dlog(@"downloadFinished");
	dlogDownloadManager();

	if(download.resumeData)
	{
		[self removeTemporaryFileForResumeData:download.resumeData];
	}

	[self moveDownloadFromPendingToHistory:download];

	if(!download.wasCancelled)
	{
		//Dispatch status bar / push notification
		[self sendNotificationWithTitle:[localizationManager localizedSPStringForKey:@"DOWNLOAD_SUCCEEDED"] message:download.filename];
	}
}

- (void)downloadFailed:(SPDownload*)download withError:(NSError*)error
{
	NSData* resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];

	if(resumeData)	//Download is recoverable, just set it to paused
	{
		download.resumeData = resumeData;
		[download setPaused:YES forced:YES];
	}
	else	//Download is not recoverable, end it
	{
		[self moveDownloadFromPendingToHistory:download];

		[self sendNotificationWithTitle:[localizationManager localizedSPStringForKey:@"DOWNLOAD_FAILED"] message:download.filename];
	}
}

- (void)moveDownloadFromPendingToHistory:(SPDownload*)download
{
	if(!(download.startedFromPrivateBrowsingMode && preferenceManager.privateModeDownloadHistoryDisabled))
	{
		[self.finishedDownloads insertObject:download atIndex:0];
	}

	[self.pendingDownloads removeObject:download];
	[self saveDownloadsToDisk];
	[self.navigationControllerDelegate reloadEverything];
	[self runningDownloadsCountDidChange];
	[self updateApplicationBadge];
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
}

- (void)saveDownloadsToDisk
{
	[cacheManager saveDownloadCache:@{@"pendingDownloads" : [self.pendingDownloads copy], @"finishedDownloads" : [self.finishedDownloads copy]}];
}

- (void)sendNotificationWithTitle:(NSString*)title message:(NSString*)message
{
	NSString* titleAndMessage = [NSString stringWithFormat:@"%@: %@", title, message];

	if([[UIApplication sharedApplication] applicationState] == 0 &&
	   preferenceManager.statusBarNotificationsEnabled && self.notificationWindow)
	{
		//Application is active -> Use status bar notification if enabled
		//Dissmiss current status notification (if one exists)
		[self.notificationWindow dismissWithCompletion:^
		{
			//Dispatch status notification with given text
			[self.notificationWindow dispatchNotification:[SPStatusBarNotification downloadStyleWithText:titleAndMessage]];
		}];
	}
	else if([[UIApplication sharedApplication] applicationState] != 0 &&
		preferenceManager.pushNotificationsEnabled)
	{
		if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0)
		{
			UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
			content.title = title;
			content.body = message;
			content.sound = [UNNotificationSound defaultSound];

			UNTimeIntervalNotificationTrigger* trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
			UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:[[NSUUID UUID] UUIDString] content:content trigger:trigger];

			[[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:nil];
		}
		else
		{
			UILocalNotification* notification = [[UILocalNotification alloc] init];
			notification.alertBody = titleAndMessage;
			notification.applicationIconBadgeNumber = self.pendingDownloads.count;
			[[UIApplication sharedApplication] presentLocalNotificationNow:notification];
		}
	}
}

- (void)updateApplicationBadge
{
	if(preferenceManager.applicationBadgeEnabled)
	{
		[UIApplication sharedApplication].applicationIconBadgeNumber = self.pendingDownloads.count;
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

- (float)progressOfAllRunningDownloads
{
	int64_t totalFilesize = 0, totalBytesWritten = 0;
	CGFloat totalExpectedDuration = 0, totalSecondsLoaded = 0;

	BOOL normalDownloadExists = NO, HLSDownloadExists = NO;

	for(SPDownload* download in [self.pendingDownloads copy])
	{
		if(!download.isHLSDownload)
		{
			if(!download.paused && download.filesize > 0)
			{
				normalDownloadExists = YES;
				totalFilesize += download.filesize;
				totalBytesWritten += download.totalBytesWritten;
			}
		}
		else
		{
			if(!download.paused && download.expectedDuration > 0)
			{
				HLSDownloadExists = YES;
				totalExpectedDuration += download.expectedDuration;
				totalSecondsLoaded += download.secondsLoaded;
			}
		}
	}

	float downloadProgress = (float)totalBytesWritten / (float)totalFilesize;
	float downloadHLSProgress = (float)totalSecondsLoaded / (float)totalExpectedDuration;

	if(normalDownloadExists && HLSDownloadExists)
	{
		return (downloadProgress + downloadHLSProgress) / (float)2;
	}
	else if(normalDownloadExists)
	{
		return downloadProgress;
	}
	else if(HLSDownloadExists)
	{
		return downloadHLSProgress;
	}
	else
	{
		return 0;
	}
}

- (NSUInteger)runningDownloadsCount
{
	NSUInteger runningDownloadsCount = 0;

	for(SPDownload* download in [self.pendingDownloads copy])
	{
		if(!download.paused)
		{
			runningDownloadsCount++;
		}
	}

	return runningDownloadsCount;
}

- (void)addObserverDelegate:(id<DownloadsObserverDelegate>)observerDelegate
{
	if(![self.observerDelegates containsObject:observerDelegate])
	{
		[self.observerDelegates addObject:observerDelegate];
	}
}

- (void)removeObserverDelegate:(id<DownloadsObserverDelegate>)observerDelegate
{
	if([self.observerDelegates containsObject:observerDelegate])
	{
		[self.observerDelegates removeObject:observerDelegate];
	}
}

- (void)totalProgressDidChange
{
	for(id<DownloadsObserverDelegate> observerDelegate in self.observerDelegates)
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{
			[observerDelegate totalProgressDidChangeForDownloadManager:self];
		});
	}
}

- (void)runningDownloadsCountDidChange
{
	for(id<DownloadsObserverDelegate> observerDelegate in self.observerDelegates)
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{
			[observerDelegate runningDownloadsCountDidChangeForDownloadManager:self];
		});
	}
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

- (SPDownload*)downloadWithTask:(__kindof NSURLSessionTask*)task
{
	BOOL isHLS = NO;

	if(self.HLSSupported)
	{
		if([task isKindOfClass:NSClassFromString(@"AVAssetDownloadTask")])
		{
			isHLS = YES;
		}
	}

	return [self downloadWithTaskIdentifier:task.taskIdentifier isHLS:isHLS];
}

- (SPDownload*)downloadWithTaskIdentifier:(NSUInteger)identifier isHLS:(BOOL)isHLS
{
	for(SPDownload* download in [self.pendingDownloads copy])
	{
		if(download.taskIdentifier == identifier)
		{
			if(download.isHLSDownload == isHLS)
			{
				//Download taskIdentifier matches -> return download
				return download;
			}
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
		[self sendNotificationWithTitle:[localizationManager localizedSPStringForKey:@"DOWNLOAD_STARTED"] message:downloadInfo.filename];
		[self updateApplicationBadge];

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

	if(preferenceManager.autosaveToMediaLibraryEnabled)
	{
		UIImageWriteToSavedPhotosAlbum(downloadInfo.image, nil, nil, nil);
	}

	//Write image to file
	NSURL* tmpURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:downloadInfo.filename];
	[UIImagePNGRepresentation(downloadInfo.image) writeToURL:tmpURL atomically:YES];
	[fileManager moveItemAtURL:tmpURL toURL:[downloadInfo pathURL] error:nil];

	//Send notification
	[self sendNotificationWithTitle:[localizationManager localizedSPStringForKey:@"SAVED_IMAGE"] message:downloadInfo.filename];
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

// maybe useful: https://github.com/WebKit/webkit/blob/c9953af06bcf8707a0764a84a4a03a581dbe18a0/Source/WebKitLegacy/mac/Misc/WebDownload.mm#L97
/*
- (void)URLSession:(NSURLSession *)session 
              task:(NSURLSessionTask *)task 
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge 
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
	NSLog(@"didReceiveChallenge:%@", challenge);
	NSLog(@"authenticationMethod:%@", challenge.protectionSpace.authenticationMethod);

	//completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
}
*/
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

		if(downloadInfo.isHLSDownload)
		{
			title = downloadInfo.filename;
		}
		else if(downloadInfo.filesize < 0)
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

		if(downloadInfo.isHLSDownload)
		{
			UIAlertAction *downloadM3UAction = [UIAlertAction
						   actionWithTitle:[NSString stringWithFormat:[localizationManager
								    localizedSPStringForKey:@"DOWNLOAD_PLAYLIST_TO"], downloadInfo.playlistExtension]
						   style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
			{
				//Undo HLS related changes to the download info
				downloadInfo.isHLSDownload = NO;
				downloadInfo.filename = [[downloadInfo.filename stringByDeletingPathExtension] stringByAppendingPathExtension:downloadInfo.playlistExtension];

				//Start download with custom path
				downloadInfo.customPath = YES;
				[self configureDownloadWithInfo:downloadInfo];
				[self closeDocumentIfObsoleteWithDownloadInfo:downloadInfo];
			}];

			[downloadAlert addAction:downloadM3UAction];
		}

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

	[SPMediaFetcher getURLForCurrentlyPlayingMediaWithCompletionHandler:^(NSURL* URL, int pid)
	{
		if(URL)
		{
			downloadInfo.request = [NSURLRequest requestWithURL:URL];

			TabDocument* tabDocumentForVideo;

			for(BrowserController* bc in browserControllers())
			{
				if(bc.tabController.activeTabDocument.webView._webProcessIdentifier == pid)
				{
					tabDocumentForVideo = bc.tabController.activeTabDocument;
				}
			}

			downloadInfo.sourceDocument = tabDocumentForVideo;

			if(preferenceManager.videoDownloadingUseTabTitleAsFilenameEnabled)
			{
				downloadInfo.title = downloadInfo.sourceDocument.title;
			}

			[self prepareDownloadFromRequestForDownloadInfo:downloadInfo];
		}
		else
		{
			if(downloadInfo.sourceVideo)
			{
				[downloadInfo.sourceVideo.downloadButton setSpinning:NO];
			}
			[self presentVideoURLNotFoundErrorWithDownloadInfo:downloadInfo];
		}
	}];
}

- (void)prepareDownloadFromRequestForDownloadInfo:(SPDownloadInfo*)downloadInfo
{
	dlogDownloadInfo(downloadInfo, @"prepareDownloadFromRequestForDownloadInfo");
	dlogDownloadManager();

	if(!self.requestFetchDownloadInfo)
	{
		NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
		config.timeoutIntervalForResource = 5;

		self.fetchSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];

		NSURLSessionDataTask* dataTask = [self.fetchSession dataTaskWithRequest:downloadInfo.request];

		self.requestFetchDownloadInfo = downloadInfo;

		[dataTask resume];

		//After 5 seconds we cancel the task and error out
		/*dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^
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
		   });*/
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

	[self handleFinishedTask:downloadTask location:location];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
	dlog(@"URLSession:%@ task:%@ didCompleteWithError:%@", session, task, error);
	dlogDownloadManager();

	if([task isKindOfClass:[NSURLSessionDataTask class]] && self.requestFetchDownloadInfo)
	{
		self.fetchSession = nil;

		SPDownloadInfo* downloadInfo = self.requestFetchDownloadInfo;
		self.requestFetchDownloadInfo = nil;

		if(downloadInfo.sourceVideo)
		{
			[downloadInfo.sourceVideo.downloadButton setSpinning:NO];
		}

		UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"ERROR"]
						 message:[NSString stringWithFormat:@"%@: %@", [localizationManager localizedSPStringForKey:@"UNABLE_TO_FETCH_FILE_INFORMATION"], error.description] preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction* closeAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CLOSE"] style:UIAlertActionStyleDefault handler:nil];

		[errorAlert addAction:closeAction];

		[downloadInfo.presentationController presentViewController:errorAlert animated:YES completion:nil];

		return;
	}

	//Get download
	SPDownload* download = [self downloadWithTask:task];

	if(!download)
	{
		return;
	}

	if(self.isReconnectingDownloads)
	{
		NSData* resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];

		//Connect resumeData with download
		download.resumeData = resumeData;

		//Count how often this method was called
		self.processedErrorCount++;

		if(self.processedErrorCount == self.errorCount)
		{
			//Function was called as often as expected -> resume all downloads
			[self didFinishReconnectingDownloads];
		}
	}
	else
	{
		if(download.wasCancelled)
		{
			[self downloadFinished:download];
		}
		if(error && error.code != -999)		//Download was not paused
		{
			//At this point we can be sure that some sort of connection error occured
			[self downloadFailed:download withError:error];
		}
	}

}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
	didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten
	totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
	//Get download that needs updating
	SPDownload* targetDownload = [self downloadWithTask:downloadTask];

	//Send data to download
	[targetDownload updateProgressForTotalBytesWritten:totalBytesWritten totalFilesize:totalBytesExpectedToWrite];
}

//Get response for the request and present the download alert
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
	dlog(@"URLSession:%@ session:%@ didReceiveResponse:%@", session, dataTask, response);
	dlogDownloadManager();

	completionHandler(NSURLSessionResponseCancel);

	self.fetchSession = nil;

	SPDownloadInfo* downloadInfo = self.requestFetchDownloadInfo;
	self.requestFetchDownloadInfo = nil;

	NSInteger statusCode = ((NSHTTPURLResponse*)response).statusCode;

	if(statusCode < 400)	//No error
	{
		[downloadInfo updateHLSForSuggestedFilename:response.suggestedFilename];

		downloadInfo.filesize = response.expectedContentLength;
		downloadInfo.filename = response.suggestedFilename;

		if(downloadInfo.title)
		{
			downloadInfo.filename = [downloadInfo filenameForTitle];
		}

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

- (void)mediaImport:(NSString*)path didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo
{
	[fileManager resetHardLinks];
}

- (void)URLSession:(NSURLSession *)session assetDownloadTask:(AVAssetDownloadTask *)assetDownloadTask didLoadTimeRange:(CMTimeRange)timeRange totalTimeRangesLoaded:(NSArray<NSValue *> *)loadedTimeRanges timeRangeExpectedToLoad:(CMTimeRange)timeRangeExpectedToLoad
{
	CGFloat expectedDuration = CMTimeGetSeconds(timeRangeExpectedToLoad.duration);
	CGFloat secondsLoaded = 0;

	for(NSValue* value in loadedTimeRanges)
	{
		CMTimeRange timeRange = value.CMTimeRangeValue;
		secondsLoaded += CMTimeGetSeconds(timeRange.duration);
	}

	//Get download that needs updating
	SPDownload* targetDownload = [self downloadWithTask:assetDownloadTask];

	[targetDownload updateProgressForSecondsLoaded:secondsLoaded expectedDuration:expectedDuration];
}

- (void)URLSession:(NSURLSession *)session assetDownloadTask:(AVAssetDownloadTask *)assetDownloadTask didFinishDownloadingToURL:(NSURL *)location
{
	[self handleFinishedTask:assetDownloadTask location:location];
}

- (void)handleFinishedTask:(__kindof NSURLSessionTask*)task location:(NSURL *)location
{
	//Get finished download
	SPDownload* download = [self downloadWithTask:task];

	if(!download)
	{
		return;
	}

	if(download.wasCancelled)
	{
		[fileManager removeItemAtURL:location error:nil];
		return;
	}

	//Get real file size and apply it to download
	if(download.isHLSDownload)
	{
		download.filesize = [fileManager sizeOfDirectoryAtURL:location];
	}
	else
	{
		NSNumber* size;
		[fileManager URLResourceValue:&size forKey:NSURLFileSizeKey forURL:location error:nil];
		download.filesize = [size longLongValue];
	}

	//Get downloadInfo from download
	SPDownloadInfo* downloadInfo = [[SPDownloadInfo alloc] initWithDownload:download];

	//Remove file if it exists
	[downloadInfo removeExistingFile];

	//Move downloaded file to picked location
	[fileManager moveItemAtURL:location toURL:[downloadInfo pathURL] error:nil];

	[self downloadFinished:download];

	if(preferenceManager.autosaveToMediaLibraryEnabled)
	{
		CFStringRef fileExtension = (__bridge CFStringRef)[[downloadInfo pathURL] pathExtension];
		CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);

		NSURL* hardLinkedURL;

		if(UTTypeConformsTo(uti, kUTTypeImage))
		{
			hardLinkedURL = [fileManager accessibleHardLinkForFileAtURL:[downloadInfo pathURL] forced:NO];

			UIImage* image = [UIImage imageWithContentsOfFile:hardLinkedURL.path];
			UIImageWriteToSavedPhotosAlbum(image, self, @selector(mediaImport:didFinishSavingWithError:contextInfo:), nil);
		}
		else if(UTTypeConformsTo(uti, kUTTypeAudiovisualContent))
		{
			hardLinkedURL = [fileManager accessibleHardLinkForFileAtURL:[downloadInfo pathURL] forced:NO];

			if(UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(hardLinkedURL.path))
			{
				UISaveVideoAtPathToSavedPhotosAlbum(hardLinkedURL.path, self, @selector(mediaImport:didFinishSavingWithError:contextInfo:), nil);
			}
			else
			{
				[fileManager resetHardLinks];
			}
		}

		if(uti) CFRelease(uti);
	}
}

- (NSString*)fileTypeOfMovpkgAtURL:(NSURL*)movpkgURL
{
	NSArray<NSString*>* subItems = [fileManager contentsOfDirectoryAtPath:[movpkgURL path] error:nil];

	for(NSString* itemName in subItems)
	{
		NSURL* folderURL = [movpkgURL URLByAppendingPathComponent:itemName];

		if([itemName hasPrefix:@"0"] && [fileManager isDirectoryAtURL:folderURL error:nil])
		{
			NSURL* playlistURL;

			for(NSString* filename in [fileManager contentsOfDirectoryAtPath:[folderURL path] error:nil])
			{
				if([[filename stringByDeletingPathExtension] isEqualToString:itemName])
				{
					playlistURL = [folderURL URLByAppendingPathComponent:filename];
					break;
				}
			}

			if(playlistURL)
			{
				NSString* playlistString = [NSString stringWithContentsOfURL:playlistURL encoding:NSUTF8StringEncoding error:nil];

				if([playlistString containsString:@"#EXT-X-MAP:URI="]) //This should be the best way to distinguish between fmp4 and ts
				{
					return @"mp4";
				}
			}

			return @"ts";
		}
	}

	return @"";
}

- (void)mergeMovpkgAtURL:(NSURL*)movpkgURL toFileAtURL:(NSURL*)targetURL
{
	NSArray<NSString*>* subItems = [fileManager contentsOfDirectoryAtPath:[movpkgURL path] error:nil];

	for(NSString* itemName in subItems)
	{
		NSURL* folderURL = [movpkgURL URLByAppendingPathComponent:itemName];

		if([itemName hasPrefix:@"0"] && [fileManager isDirectoryAtURL:folderURL error:nil])
		{
			[self mergeSegmentsAtURL:folderURL toFileAtURL:targetURL];
		}
	}
}

- (void)mergeSegmentsAtURL:(NSURL*)segmentURL toFileAtURL:(NSURL*)targetURL
{
	NSArray<NSURL*>* fragments = [fileManager contentsOfDirectoryAtURL:segmentURL includingPropertiesForKeys:nil options:nil error:nil];

	NSMutableArray<NSURL*>* fragmentsM = [fragments mutableCopy];

	//filter out everything that is no fragment
	for(NSURL* item in [fragments reverseObjectEnumerator])
	{
		if(!([[item pathExtension] isEqualToString:@"frag"] || [[item pathExtension] isEqualToString:@"initfrag"]))
		{
			[fragmentsM removeObject:item];
		}
	}

	//sort alphabetically
	[fragmentsM sortUsingComparator:^NSComparisonResult (NSURL* a, NSURL* b)
	{
		if([a.pathExtension isEqualToString:@"initfrag"])
		{
			return (NSComparisonResult)NSOrderedAscending;
		}

		if([b.pathExtension isEqualToString:@"initfrag"])
		{
			return (NSComparisonResult)NSOrderedDescending;
		}

		NSString* aIndexStringWithBrackets = [a.lastPathComponent componentsSeparatedByString:@"_"].firstObject;
		NSString* bIndexStringWithBrackets = [b.lastPathComponent componentsSeparatedByString:@"_"].firstObject;

		NSString* aIndexString;
		NSString* bIndexString;

		if(aIndexStringWithBrackets.length > 2)
		{
			aIndexString = [aIndexStringWithBrackets substringWithRange:NSMakeRange(1,aIndexStringWithBrackets.length-2)];
		}

		if(bIndexStringWithBrackets.length > 2)
		{
			bIndexString = [bIndexStringWithBrackets substringWithRange:NSMakeRange(1,bIndexStringWithBrackets.length-2)];
		}

		NSInteger aInt = [aIndexString integerValue];
		NSInteger bInt = [bIndexString integerValue];

		if(aInt > bInt)
		{
			return (NSComparisonResult)NSOrderedDescending;
		}
		else if(aInt == bInt)
		{
			return (NSComparisonResult)NSOrderedSame;
		}
		else
		{
			return (NSComparisonResult)NSOrderedAscending;
		}
	}];

	if(fragmentsM.count == 0)
	{
		return;
	}

	//merge everything
	NSMutableData* data;

	BOOL first = YES;

	for(NSURL* fragment in fragmentsM)
	{
		if(first)
		{
			first = NO;
			data = [NSMutableData dataWithContentsOfURL:fragment];
			continue;
		}

		[data appendData:[NSData dataWithContentsOfURL:fragment]];
	}

	NSURL* tmpURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:[targetURL lastPathComponent]];
	[data writeToURL:tmpURL atomically:YES];

	[fileManager moveItemAtURL:tmpURL toURL:targetURL error:nil];
}

@end
