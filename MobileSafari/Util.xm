// Util.xm
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

#import "SafariPlus.h"

#import "Util.h"
#import "Defines.h"
#import "Classes/SPFileManager.h"
#import "Classes/SPPreferenceManager.h"
#import "Classes/SPLocalizationManager.h"
#import "Classes/SPCommunicationManager.h"
#import "Classes/SPCacheManager.h"

#import "../Shared/SPPreferenceMerger.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <sys/socket.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

NSBundle* MSBundle = [NSBundle mainBundle];
NSBundle* SPBundle = [NSBundle bundleWithPath:SPBundlePath];

SPCommunicationManager* communicationManager;
SPFileManager* fileManager;
SPPreferenceManager* preferenceManager;
SPLocalizationManager* localizationManager = [SPLocalizationManager sharedInstance];
SPDownloadManager* downloadManager;
SPCacheManager* cacheManager = [SPCacheManager sharedInstance];
BOOL rocketBootstrapWorks;

#ifdef DEBUG_LOGGING

#import "Classes/SPDownload.h"
#import "Classes/SPDownloadInfo.h"
#import "Classes/SPDownloadManager.h"

NSFileHandle* debugLogFileHandle;

void initDebug()
{
	NSString* dateString;

	NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.dateStyle = NSDateFormatterMediumStyle;
	dateFormatter.timeStyle = NSDateFormatterMediumStyle;
	dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];

	dateString = [dateFormatter stringFromDate:[NSDate date]];

	NSString* debugLogDirectoryPath = [SPCachePath stringByAppendingString:@"/Logs"];

	NSString* debugLogPath = [NSString stringWithFormat:@"%@/%@.log", debugLogDirectoryPath, dateString];

	if(![[NSFileManager defaultManager] fileExistsAtPath:debugLogDirectoryPath])
	{
		[[NSFileManager defaultManager] createDirectoryAtPath:debugLogDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
	}

	if(![[NSFileManager defaultManager] fileExistsAtPath:debugLogPath])
	{
		[[NSFileManager defaultManager] createFileAtPath:debugLogPath contents:nil attributes:nil];
	}

	debugLogFileHandle = [NSFileHandle fileHandleForWritingAtPath:debugLogPath];
	[debugLogFileHandle seekToEndOfFile];
}

void _dlog(NSString* fString, ...)
{
	va_list va;
	va_start(va, fString);
	NSString* msg = [[NSString alloc] initWithFormat:fString arguments:va];
	va_end(va);

	[debugLogFileHandle writeData:[[msg stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	NSLog(@"%@", msg);
}

void _dlogDownload(SPDownload* download, NSString* message)
{
	dlog(@"----------");
	dlog(@"DOWNLOAD %@", download);
	dlog(message);
	dlog(@"----------");
	dlog(@"request: %@", download.request);
	dlog(@"image: %@", download.image);
	dlog(@"filesize: %lli", download.filesize);
	dlog(@"filename: %@", download.filename);
	dlog(@"targetURL: %@", download.targetURL);
	dlog(@"paused: %i", download.paused);
	dlog(@"lastSpeedRefreshTime: %llu", download.lastSpeedRefreshTime);
	dlog(@"speedTimer: %@", download.speedTimer);
	dlog(@"startBytes: %lli", download.startBytes);
	dlog(@"totalBytesWritten: %lli", download.totalBytesWritten);
	dlog(@"bytesPerSecond: %lli", download.bytesPerSecond);
	dlog(@"resumeData length: %llu", (unsigned long long)download.resumeData.length);
	dlog(@"paused: %llu", (unsigned long long)download.taskIdentifier);
	dlog(@"downloadTask: %@", download.downloadTask);
	dlog(@"didFinish: %i", download.didFinish);
	dlog(@"wasCancelled: %i", download.wasCancelled);
	dlog(@"downloadManagerDelegate: %@", download.downloadManagerDelegate);
	dlog(@"browserCellDelegate: %@", download.browserCellDelegate);
	dlog(@"listCellDelegate: %@", download.listCellDelegate);
	dlog(@"----------");
}

void _dlogDownloadInfo(SPDownloadInfo* downloadInfo, NSString* message)
{
	dlog(@"----------");
	dlog(@"DOWNLOADINFO %@", downloadInfo);
	dlog(message);
	dlog(@"----------");
	dlog(@"request: %@", downloadInfo.request);
	dlog(@"image: %@", downloadInfo.image);
	dlog(@"filesize: %lli", downloadInfo.filesize);
	dlog(@"filename: %@", downloadInfo.filename);
	dlog(@"targetURL: %@", downloadInfo.targetURL);
	dlog(@"customPath: %i", downloadInfo.customPath);
	dlog(@"sourceVideo: %@", downloadInfo.sourceVideo);
	dlog(@"sourceDocument: %@", downloadInfo.sourceDocument);
	dlog(@"presentationController: %@", downloadInfo.presentationController);
	dlog(@"sourceRect: %@", NSStringFromCGRect(downloadInfo.sourceRect));
	dlog(@"----------");
}

void _dlogDownloadManager()
{
	dlog(@"----------");
	dlog(@"DOWNLOADMANAGER %@", downloadManager);
	dlog(@"----------");
	dlog(@"pendingDownloads: %@", downloadManager.pendingDownloads);
	dlog(@"finishedDownloads: %@", downloadManager.finishedDownloads);
	dlog(@"notificationWindow: %@", downloadManager.notificationWindow);
	dlog(@"downloadSession: %@", downloadManager.downloadSession);
	dlog(@"errorCount: %lli", downloadManager.errorCount);
	dlog(@"processedErrorCount: %lli", downloadManager.processedErrorCount);
	dlog(@"defaultDownloadURL: %@", downloadManager.defaultDownloadURL);
	dlog(@"processedVideoDownloadInfo: %@", downloadManager.processedVideoDownloadInfo);
	[downloadManager.downloadSession getAllTasksWithCompletionHandler:^(NSArray<__kindof NSURLSessionTask *> *tasks)
	{
		dlog(@"tasks: %@", tasks);
	}];
	dlog(@"----------");
}

#endif

//Return current browsing status
BOOL privateBrowsingEnabled(BrowserController* controller)
{
	BOOL privateBrowsingEnabled;

	if([controller respondsToSelector:@selector(isPrivateBrowsingEnabled)])
	{
		privateBrowsingEnabled = [controller isPrivateBrowsingEnabled];
	}
	else
	{
		privateBrowsingEnabled = controller.privateBrowsingEnabled;
	}

	return privateBrowsingEnabled;
}

//Toggle private mode
void togglePrivateBrowsing(BrowserController* controller)
{
	if([controller respondsToSelector:@selector(togglePrivateBrowsingEnabled)])
	{
		[controller togglePrivateBrowsingEnabled];
	}
	else
	{
		[controller togglePrivateBrowsing];
	}
}

void setPrivateBrowsing(BrowserController* controller, BOOL enabled, void (^completion)(void))
{
	if([controller respondsToSelector:@selector(_setPrivateBrowsingEnabled:showModalAuthentication:completion:)])
	{
		[controller _setPrivateBrowsingEnabled:enabled showModalAuthentication:NO completion:completion];
	}
	else	//if that method does not exists, toggling is the only way to properly switch between browsing modes
	{
		BOOL privateBrowsing = privateBrowsingEnabled(controller);
		if(privateBrowsing != enabled)
		{
			togglePrivateBrowsing(controller);
		}
		if(completion)
		{
			//It takes about 0.1 seconds to switch between browsing modes
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), completion);
		}
	}
}

//Get active webViews
NSArray<SafariWebView*>* activeWebViews()
{
	NSMutableArray<SafariWebView*>* webViews = [NSMutableArray new];
	for(BrowserController* controller in browserControllers())
	{
		[webViews addObject:controller.tabController.activeTabDocument.webView];
	}
	return [webViews copy];
}

//Return array of all browsercontrollers
NSArray<BrowserController*>* browserControllers()
{
	NSArray* browserControllers;

	Application* sharedApplication = (Application*)[%c(Application) sharedApplication];

	if([sharedApplication respondsToSelector:@selector(browserControllers)])
	{
		browserControllers = sharedApplication.browserControllers;
	}
	else	//8,9
	{
		browserControllers = @[MSHookIvar<BrowserController*>(sharedApplication,"_controller")];
	}

	return browserControllers;
}

//Get browserController from tabDocument
BrowserController* browserControllerForTabDocument(TabDocument* document)
{
	BrowserController* browserController;

	if([document respondsToSelector:@selector(browserController)])
	{
		browserController = document.browserController;
	}
	else
	{
		browserController = MSHookIvar<BrowserController*>(document, "_browserController");
	}

	return browserController;
}

//Get rootViewController from browserController
BrowserRootViewController* rootViewControllerForBrowserController(BrowserController* controller)
{
	BrowserRootViewController* rootViewController;

	if([controller respondsToSelector:@selector(rootViewController)])
	{
		rootViewController = controller.rootViewController;
	}
	else
	{
		rootViewController = MSHookIvar<BrowserRootViewController*>(controller, "_rootViewController");
	}

	return rootViewController;
}


//Get rootViewController from tabDocument
BrowserRootViewController* rootViewControllerForTabDocument(TabDocument* document)
{
	return rootViewControllerForBrowserController(browserControllerForTabDocument(document));
}

//Only add object to dict if it's not nil (to combat crashes)
void addToDict(NSMutableDictionary* dict, NSObject* object, id<NSCopying> key)
{
	if(object)
	{
		[dict setObject:object forKey:key];
	}
}

void requestAuthentication(NSString* reason, void (^successHandler)(void))
{
	BOOL mainThread = [NSThread isMainThread];
	LAContext* myContext = [[LAContext alloc] init];
	NSError* authError = nil;
	if([myContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError])
	{
		[myContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
		 localizedReason:reason reply:^(BOOL success, NSError* error)
		{
			if(success)
			{
				if(mainThread)
				{
					dispatch_async(dispatch_get_main_queue(), successHandler);
				}
				else
				{
					dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), successHandler);
				}
			}
		}];
	}
}

//Send a simple alert that just has a close button with title and message
void sendSimpleAlert(NSString* title, NSString* message)
{
	UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
				    message:message
				    preferredStyle:UIAlertControllerStyleAlert];

	UIAlertAction* closeAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CLOSE"]
				      style:UIAlertActionStyleDefault handler:nil];

	[alert addAction:closeAction];

	[rootViewControllerForBrowserController(browserControllers().firstObject) presentViewController:alert animated:YES completion:nil];
}

//I literally had to reverse engineer CFNetwork / Foundation to figure out how to unarchive the resume data on iOS 12, no joke
NSDictionary* decodeResumeData12(NSData* resumeData)
{
	NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:resumeData error:nil];
	[unarchiver setDecodingFailurePolicy:NO];
	id obj = [unarchiver decodeObjectOfClasses:[[NSSet alloc] initWithArray:@[[NSString class],[NSNumber class],[NSURL class],[NSURLRequest class],[NSArray class],[NSData class],[NSDictionary class]]] forKey:@"NSKeyedArchiveRootObjectKey"];

	[unarchiver finishDecoding];

	if([obj isKindOfClass:[NSDictionary class]])
	{
		return (NSDictionary*)obj;
	}
	else
	{
		return nil;
	}
}

BOOL isUsingCellularData()
{
	struct sockaddr_in zeroAddress;
	bzero(&zeroAddress, sizeof(zeroAddress));
	zeroAddress.sin_len = sizeof(zeroAddress);
	zeroAddress.sin_family = AF_INET;

	SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (sockaddr*)&zeroAddress);
	SCNetworkReachabilityFlags flags;

	SCNetworkReachabilityGetFlags(reachability, &flags);

	if((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
	{
		return YES;
	}

	return NO;
}



/*NSURL* videoURLFromWebAVPlayerController(WebAVPlayerController* playerController)
{
	NSLog(@"playerController = %@",playerController);

	WebCore::PlaybackSessionModelMediaElement* mediaElementModel = MSHookIvar<WebCore::PlaybackSessionModelMediaElement*>(playerController, "_delegate");

	NSLog(@"mediaElementModel = %p", mediaElementModel);

	NSLog(@"trying to pause!");

	mediaElementModel->pause();

	NSLog(@"paused??");

	WebCore::HTMLMediaElement* mediaElement = mediaElementModel->m_mediaElement;

	NSLog(@"mediaElement = %p", mediaElement);

	const WebCore::URL* url = (const WebCore::URL*)(((intptr_t)mediaElement) + m_currentSrc_off);

	NSLog(@"url = %p", url);

	NSURL* videoURL = (__bridge NSURL*)url;

	NSLog(@"videoURL=%@", videoURL);

	/*bool valid = url.isValid();

	   NSLog(@"valid = %i", valid);*/

	/*const WTF::String& string = url.m_string;

	   NSLog(@"string:%p", &string);

	   WTF::StringImpl* stringImpl = string.m_impl;

	   NSLog(@"stringImpl:%p", &stringImpl);

	   const char* litString = stringImpl->m_data8Char;

	   NSLog(@"pointer: %p", &litString);

	   NSLog(@"length: %u", stringImpl->m_length);
	   NSLog(@"hashAndFlags:%u", stringImpl->m_hashAndFlags);
	   NSLog(@"is8Bit:%i", stringImpl->m_hashAndFlags & (1u << 2));

	   NSLog(@"test:%c", stringImpl->m_data16Char[0]);*/

	/*char* urlCString = NULL;

	   strcpy(urlCString, litString);

	   NSString* URLGANG = [NSString stringWithCString:urlCString encoding:NSUTF8StringEncoding];

	   NSLog(@"URL String GANG %@", URLGANG);*/

	//return nil;

	/*CFURLRef videoURL = url.createCFURL();

	   return (__bridge NSURL*)videoURL;*/
//}

/****** One constructor that inits all hooks ******/

extern void initApplication();
extern void initAVFullScreenPlaybackControlsViewController();
extern void initAVPlaybackControlsView();
extern void initBookmarkFavoritesActionsView();
extern void initBrowserController();
extern void initBrowserRootViewController();
extern void initBrowserToolbar();
extern void initCatalogViewController();
extern void initColors();
extern void initFeatureManager();
extern void initTabController();
extern void initTabDocument();
extern void initTabOverview();
extern void initTabOverviewItemLayoutInfo();
extern void initTabThumbnailView();
extern void initTiltedTabItemLayoutInfo();
extern void initTiltedTabView();
extern void initWKFileUploadPanel();

%ctor
{
  #ifdef DEBUG_LOGGING
	initDebug();
  #endif

	communicationManager = [SPCommunicationManager sharedInstance];
	rocketBootstrapWorks = [communicationManager testConnection];

	fileManager = [SPFileManager sharedInstance];

	#ifndef SIMJECT
	[SPPreferenceMerger mergeIfNeeded];
	#endif

	preferenceManager = [SPPreferenceManager sharedInstance];

	if(preferenceManager.tweakEnabled)	//Only initialise hooks if tweak is enabled
	{
		initApplication();
		initAVFullScreenPlaybackControlsViewController();
		initAVPlaybackControlsView();
		initBookmarkFavoritesActionsView();
		initBrowserController();
		initBrowserRootViewController();
		initBrowserToolbar();
		initCatalogViewController();
		initColors();
		initFeatureManager();
		initTabController();
		initTabDocument();
		initTabOverview();
		initTabOverviewItemLayoutInfo();
		initTabThumbnailView();
		initTiltedTabItemLayoutInfo();
		initTiltedTabView();
		initWKFileUploadPanel();
	}
}
