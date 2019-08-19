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
#import "SPPreferenceUpdater.h"

#import <LocalAuthentication/LocalAuthentication.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <sys/socket.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

NSBundle* MSBundle = [NSBundle mainBundle];
NSBundle* SPBundle = [NSBundle bundleWithPath:SPBundlePath];

SPCommunicationManager* communicationManager = [SPCommunicationManager sharedInstance];
SPFileManager* fileManager = [SPFileManager sharedInstance];
SPPreferenceManager* preferenceManager;
SPLocalizationManager* localizationManager = [SPLocalizationManager sharedInstance];
SPDownloadManager* downloadManager;
SPCacheManager* cacheManager = [SPCacheManager sharedInstance];
BOOL rocketBootstrapWorks = NO;
BOOL skipBiometricProtection = NO;

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
	dlog(@"wasCancelled: %i", download.wasCancelled);
	dlog(@"downloadManagerDelegate: %@", download.downloadManagerDelegate);
	dlog(@"observerDelegates: %@", download.observerDelegates);
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
	dlog(@"requestFetchDownloadInfo: %@", downloadManager.requestFetchDownloadInfo);
	dlog(@"pickerDownloadInfo: %@", downloadManager.pickerDownloadInfo);
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

NavigationBar* navigationBarForBrowserController(BrowserController* browserController)
{
	if([browserController respondsToSelector:@selector(navigationBar)])
	{
		return browserController.navigationBar;
	}
	else
	{
		return rootViewControllerForBrowserController(browserController).navigationBar;
	}
}

BrowserToolbar* activeToolbarForBrowserController(BrowserController* browserController)
{
	if([browserController respondsToSelector:@selector(activeToolbar)])
	{
		return browserController.activeToolbar;
	}
	else
	{
		BrowserRootViewController* rootVC = rootViewControllerForBrowserController(browserController);
		if(rootVC.toolbarPlacement == 1)
		{
			return rootVC.bottomToolbar;
		}
		else
		{
			return rootVC.navigationBar.sp_toolbar;
		}
	}
}

BrowserController* browserControllerForBrowserToolbar(BrowserToolbar* browserToolbar)
{
	if([browserToolbar respondsToSelector:@selector(browserDelegate)])
	{
		return browserToolbar.browserDelegate;
	}
	else
	{
		return MSHookIvar<_SFBarManager*>(MSHookIvar<SFBarRegistration*>(browserToolbar, "_barRegistration"), "_barManager").delegate;
	}
}

BOOL browserControllerIsShowingTabView(BrowserController* browserController)
{
	BrowserRootViewController* rootViewController = rootViewControllerForBrowserController(browserController);
	if([rootViewController respondsToSelector:@selector(tabThumbnailCollectionView)])
	{
		NSInteger presentationState = rootViewController.tabThumbnailCollectionView.presentationState;
		//0: not showing tab view, 1: in animation, 2: inside tabView
		return (presentationState == 1) || (presentationState == 2);
	}
	else if([browserController respondsToSelector:@selector(isShowingTabView)])
	{
		return [browserController isShowingTabView];
	}
	else
	{
		NSLog(@"2");
		return MSHookIvar<BOOL>(browserController, "_showingTabView");
	}
}

void closeTabDocuments(TabController* tabController, NSArray<TabDocument*>* tabDocuments, BOOL animated)
{
	if([tabDocuments count] <= 0)
	{
		return;
	}

	BrowserController* browserController = MSHookIvar<BrowserController*>(tabController, "_browserController");

	if(tabController.tiltedTabView && kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_12_2)
	{
		NSMutableSet* tabDocumentsAboutToBeClosedInTiltedTabView = MSHookIvar<NSMutableSet*>(tabController, "_tabDocumentsAboutToBeClosedInTiltedTabView");
		[tabDocumentsAboutToBeClosedInTiltedTabView addObjectsFromArray:[tabDocuments copy]];
		[tabController _updateTiltedTabViewItemsAnimated:animated];
	}

	NSMutableArray* privateTabDocuments = [NSMutableArray new];
	NSMutableArray* normalTabDocuments = [NSMutableArray new];

	for(TabDocument* tabDocument in tabDocuments)
	{
		BOOL privateTab = NO;

		if([tabDocument respondsToSelector:@selector(privateBrowsingEnabled)])
		{
			privateTab = [tabDocument privateBrowsingEnabled];
		}
		else
		{
			privateTab = [tabDocument isPrivateBrowsingEnabled];
		}

		if(privateTab)
		{
			[privateTabDocuments addObject:tabDocument];
		}
		else
		{
			[normalTabDocuments addObject:tabDocument];
		}
	}

	NSArray* currentModeTabs;
	NSArray* otherModeTabs;

	if(privateBrowsingEnabled(browserController))
	{
		currentModeTabs = [privateTabDocuments copy];
		otherModeTabs = [normalTabDocuments copy];
	}
	else
	{
		currentModeTabs = [normalTabDocuments copy];
		otherModeTabs = [privateTabDocuments copy];
	}

	if(currentModeTabs.count >= 1)
	{
		if([tabController respondsToSelector:@selector(_closeTabDocuments:animated:temporarily:allowAddingToRecentlyClosedTabs:keepWebViewAlive:)])
		{
			[tabController _closeTabDocuments:currentModeTabs animated:animated temporarily:NO allowAddingToRecentlyClosedTabs:YES keepWebViewAlive:NO];
		}
		else
		{
			for(TabDocument* tabDocument in [currentModeTabs reverseObjectEnumerator])
			{
				[tabController closeTabDocument:tabDocument animated:animated];
			}
		}
	}

	if(otherModeTabs.count >= 1)
	{
		togglePrivateBrowsing(browserController);

		if([tabController respondsToSelector:@selector(_closeTabDocuments:animated:temporarily:allowAddingToRecentlyClosedTabs:keepWebViewAlive:)])
		{
			[tabController _closeTabDocuments:otherModeTabs animated:animated temporarily:NO allowAddingToRecentlyClosedTabs:YES keepWebViewAlive:NO];
		}
		else
		{
			for(TabDocument* tabDocument in [otherModeTabs reverseObjectEnumerator])
			{
				[tabController closeTabDocument:tabDocument animated:animated];
			}
		}

		togglePrivateBrowsing(browserController);
	}
}

TabDocument* tabDocumentForItem(TabController* tabController, id<TabCollectionItem> item)
{
	if([tabController respondsToSelector:@selector(_tabDocumentRepresentedByTiltedTabItem:)])
	{
		if([item isKindOfClass:[%c(TabBarItem) class]])
		{
			return [tabController _tabDocumentRepresentedByTabBarItem:item];
		}
		else if ([item isKindOfClass:[%c(TiltedTabItem) class]])
		{
			return [tabController _tabDocumentRepresentedByTiltedTabItem:item];
		}
		else if ([item isKindOfClass:[%c(TabOverviewItem) class]])
		{
			return [tabController _tabDocumentRepresentedByTabOverviewItem:item];
		}
	}
	else if([tabController respondsToSelector:@selector(tabDocumentWithUUID:)])
	{
		return [tabController tabDocumentWithUUID:[item UUID]];
	}

	return nil;
}

//Modify tab expose alert for locked tabs (purely cosmetical) return: did anything?
BOOL updateTabExposeActionsForLockedTabs(BrowserController* browserController, UIAlertController* tabExposeAlertController)
{
	if(!tabExposeAlertController)
	{
		return NO;
	}

	NSUInteger nonLockedTabCount = 0;

	NSMutableArray<UIAlertAction*>* actions = MSHookIvar<NSMutableArray<UIAlertAction*>*>(tabExposeAlertController, "_actions");

	NSString* searchTerm = nil;
	BOOL hasSearchTerm = NO;
	BOOL reloadActions = NO;

	if([browserController.tabController respondsToSelector:@selector(searchTerm)])
	{
		searchTerm = browserController.tabController.searchTerm;
	}
	else if([browserController.tabController respondsToSelector:@selector(tabThumbnailCollectionView)])
	{
		searchTerm = browserController.tabController.tabThumbnailCollectionView.searchTerm;
	}

	if(searchTerm)
	{
		hasSearchTerm = (searchTerm.length > 0);
	}

	if(!hasSearchTerm)
	{
		for(TabDocument* document in browserController.tabController.currentTabDocuments)
		{
			if(!document.locked)
			{
				nonLockedTabCount++;
			}
		}

		if(browserController.tabController.currentTabDocuments.count == nonLockedTabCount)
		{
			return NO;	//No tabs locked, nothing else to do
		}

		UIAlertAction* closeAllTabsAction;
		UIAlertAction* closeTabAction;

		BOOL isShowingTabView = browserControllerIsShowingTabView(browserController);

		if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0 && !isShowingTabView)
		{
			if(browserController.tabController.currentTabDocuments.count > 1)
			{
				closeTabAction = [actions objectAtIndex:1];
			}
			else
			{
				closeTabAction = actions.firstObject;
			}
		}

		if(isShowingTabView || browserController.tabController.currentTabDocuments.count > 1)
		{
			if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0)
			{
				closeAllTabsAction = actions.firstObject;
			}
			else
			{
				closeAllTabsAction = [actions objectAtIndex:actions.count - 2];
			}

			//If there are no nonlocked tabs outside of the current active tab, we remove the option to close all tabs, otherwise we change the title
			if(nonLockedTabCount > 1)
			{
				[closeAllTabsAction setTitle:[NSString stringWithFormat:[localizationManager localizedSPStringForKey:@"CLOSE_NON_LOCKED_TABS"], nonLockedTabCount]];
			}
			else if((isShowingTabView || browserController.tabController.activeTabDocument.locked || kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_11_0) && nonLockedTabCount == 1)
			{
				[closeAllTabsAction setTitle:[localizationManager localizedSPStringForKey:@"CLOSE_NON_LOCKED_TAB"]];
			}
			else
			{
				[actions removeObject:closeAllTabsAction];
				reloadActions = YES;
			}
		}

		//If the active tab is locked, we remove the option to close it
		if(browserController.tabController.activeTabDocument.locked && closeTabAction)
		{
			[actions removeObject:closeTabAction];
			reloadActions = YES;
		}
	}
	else if(hasSearchTerm)
	{
		UIAlertAction* closeMatchingTabsAction = actions.firstObject;

		for(TabDocument* document in browserController.tabController.tabDocumentsMatchingSearchTerm)
		{
			if(!document.locked)
			{
				nonLockedTabCount++;
			}
		}

		if(browserController.tabController.tabDocumentsMatchingSearchTerm.count == nonLockedTabCount)
		{
			return NO;	//No matching tabs locked, nothing else to do
		}

		if(nonLockedTabCount == 0)
		{
			[actions removeObject:closeMatchingTabsAction];
			reloadActions = YES;
		}
		else if(nonLockedTabCount == 1)
		{
			[closeMatchingTabsAction setTitle:[NSString stringWithFormat:[localizationManager localizedSPStringForKey:@"CLOSE_NON_LOCKED_TAB_MATCHING"], searchTerm]];
		}
		else
		{
			[closeMatchingTabsAction setTitle:[NSString stringWithFormat:[localizationManager localizedSPStringForKey:@"CLOSE_NON_LOCKED_TABS_MATCHING"], nonLockedTabCount, searchTerm]];
		}
	}

	//If any action has been removed, we need to manually remove and readd all actions so that the UI actually updates
	if(reloadActions)
	{
		NSArray* newActions = [actions copy];
		[tabExposeAlertController _removeAllActions];
		[tabExposeAlertController _setActions:newActions];
	}

	return YES;
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
	if(skipBiometricProtection)
	{
		successHandler();
		return;
	}

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
			else if(error.code != -2)
			{
				dispatch_async(dispatch_get_main_queue(), ^
					       {
						       sendSimpleAlert([localizationManager localizedSPStringForKey:@"AUTHENTICATION_ERROR"], [NSString stringWithFormat:@"%li: %@", (long)error.code, error.localizedDescription]);
					       });
			}
		}];
	}
	else
	{
		sendSimpleAlert([localizationManager localizedSPStringForKey:@"AUTHENTICATION_ERROR"], [NSString stringWithFormat:@"%li: %@", (long)authError.code, authError.localizedDescription]);
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
	[unarchiver setDecodingFailurePolicy:NSDecodingFailurePolicyRaiseException];
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
extern void initNavigationBar();
extern void initNavigationBarItem();
extern void initSafariWebView();
extern void initSearchEngineController();
extern void initSPTabManagerBookmarkPicker();
extern void initTabItemLayoutInfo();
extern void initTabBarItemView();
extern void initTabController();
extern void initTabDocument();
extern void initTabExposeActionsController();
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
		initNavigationBar();
		initNavigationBarItem();
		initSafariWebView();
		initSearchEngineController();
		initSPTabManagerBookmarkPicker();
		initTabItemLayoutInfo();
		initTabBarItemView();
		initTabController();
		initTabDocument();
		initTabExposeActionsController();
		initTabOverview();
		initTabOverviewItemLayoutInfo();
		initTabThumbnailView();
		initTiltedTabItemLayoutInfo();
		initTiltedTabView();
		initWKFileUploadPanel();
	}
}
