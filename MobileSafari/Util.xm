// Copyright (c) 2017-2021 Lars Fröder

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
#import <mach-o/dyld.h>

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

NSString* getSafariTmpPath()
{
	return [getSafariTmpURL() path];
}

NSURL* getSafariTmpURL()
{
	static NSURL* tmpURL = nil;
	if(!tmpURL)
	{
		NSString* homeDirectory = NSHomeDirectory();
		if(!homeDirectory)
		{
			return nil;
		}
		tmpURL = [NSURL fileURLWithPath:[homeDirectory stringByAppendingPathComponent:@"tmp"].stringByStandardizingPath isDirectory:YES];

		//shouldn't ever happen
		if(![tmpURL checkResourceIsReachableAndReturnError:nil])
		{
			[[NSFileManager defaultManager] createDirectoryAtURL:tmpURL withIntermediateDirectories:NO attributes:nil error:nil];
		}
	}
	return tmpURL;
}

NSString* getInjectionPlatform()
{
	static NSString* injectionPlatform = nil;

	if(!injectionPlatform)
	{
		for (uint32_t i = 0; i < _dyld_image_count(); i++)
		{
			const char *pathC = _dyld_get_image_name(i);
			NSString* path = [NSString stringWithUTF8String:pathC];

			if([path isEqualToString:@"/usr/lib/substitute-inserter.dylib"])
			{
				injectionPlatform = @"Substitute";
			}
			else if([path isEqualToString:@"/usr/lib/TweakInject.dylib"])
			{
				injectionPlatform = @"libhooker";
			}
			else if([path isEqualToString:@"/usr/lib/substrate/SubstrateInserter.dylib"])
			{
				injectionPlatform = @"Substrate";
			}
		}
	}

	return injectionPlatform;
}

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
		privateBrowsingEnabled = [controller privateBrowsingEnabled];
	}

	return privateBrowsingEnabled;
}

BOOL privateBrowsingEnabledForTabDocument(TabDocument* tabDocument)
{
	if([tabDocument respondsToSelector:@selector(isPrivateBrowsingEnabled)])
	{
		return [tabDocument isPrivateBrowsingEnabled];
	}
	else if([tabDocument respondsToSelector:@selector(privateBrowsingEnabled)])
	{
		return [tabDocument privateBrowsingEnabled];
	}
	else if([tabDocument respondsToSelector:@selector(configuration)])
	{
		return [tabDocument.configuration isPrivateBrowsingEnabled];
	}

	return NO;
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
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0)
	{
		if(privateBrowsingEnabled(controller) != enabled)
		{
			[controller setPrivateBrowsingEnabled:enabled];
		}
		
		if(completion)
		{
			//It takes about 0.1 seconds to switch between browsing modes
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), completion);
		}
	}
	else if([controller respondsToSelector:@selector(_setPrivateBrowsingEnabled:showModalAuthentication:completion:)])
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
	if(!document) return nil;

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
	if(!controller) return nil;

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
	if(!browserController) return nil;

	if([browserController respondsToSelector:@selector(navigationBar)])
	{
		return browserController.navigationBar;
	}
	else
	{
		return rootViewControllerForBrowserController(browserController).navigationBar;
	}
}

BrowserToolbar* activeToolbarOrToolbarForBarItemForBrowserController(BrowserController* browserController, NSInteger barItem)
{
	if(!browserController) return nil;

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0)
	{
		BrowserRootViewController* rootVC = rootViewControllerForBrowserController(browserController);
		if([rootVC.bottomToolbar.barRegistration containsBarItem:barItem])
		{
			return rootVC.bottomToolbar;
		}
		else 
		{
			if([rootVC.navigationBar respondsToSelector:@selector(_toolbarForBarItem:)])
			{
				return [rootVC.navigationBar _toolbarForBarItem:barItem];
			}
			else //iOS 14
			{
				_SFToolbar* leadingToolbar = [rootVC.navigationBar valueForKey:@"_leadingToolbar"];
				_SFToolbar* trailingToolbar = [rootVC.navigationBar valueForKey:@"_trailingToolbar"];

				if([leadingToolbar.barRegistration containsBarItem:barItem])
				{
					return (BrowserToolbar*)leadingToolbar;
				}

				if([trailingToolbar.barRegistration containsBarItem:barItem])
				{
					return (BrowserToolbar*)trailingToolbar;
				}

				return nil;
			}
		}
	}
	else
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
}

BrowserController* browserControllerForBrowserToolbar(BrowserToolbar* browserToolbar)
{
	if(!browserToolbar) return nil;

	if([browserToolbar respondsToSelector:@selector(browserDelegate)])
	{
		return browserToolbar.browserDelegate;
	}
	else
	{
		return MSHookIvar<_SFBarManager*>(MSHookIvar<SFBarRegistration*>(browserToolbar, "_barRegistration"), "_barManager").delegate;
	}
}

#define sp_extraButtonsOffset 10

NSInteger safariPlusOrderItemForBarButtonItem(NSInteger barItem)
{
	if(barItem >= 10)
	{
		return barItem - sp_extraButtonsOffset;
	}
	else
	{
		return barItem;
	}
}

NSInteger barButtonItemForSafariPlusOrderItem(NSInteger orderItem)
{
	if(orderItem < 6)
	{
		return orderItem;
	}
	else
	{
		return orderItem + sp_extraButtonsOffset;
	}
}

TabDocument* tabDocumentForTabThumbnailView(TabThumbnailView* tabThumbnailView)
{
	for(BrowserController* bc in browserControllers())
	{
		for(TabOverviewItem* item in bc.tabController.tabOverview.items)
		{
			if([item.layoutInfo valueForKey:@"_itemView"] == tabThumbnailView)
			{
				return tabDocumentForItem(bc.tabController, item);
			}
		}

		for(TiltedTabItem* item in bc.tabController.tiltedTabView.items)
		{
			if([item.layoutInfo valueForKey:@"_contentView"] == tabThumbnailView)
			{
				return tabDocumentForItem(bc.tabController, item);
			}
		}
	}

	return nil;
}

BOOL browserControllerIsShowingTabView(BrowserController* browserController)
{
	if(!browserController) return NO;

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
		return MSHookIvar<BOOL>(browserController, "_showingTabView");
	}
}

void closeTabDocuments(TabController* tabController, NSArray<TabDocument*>* tabDocuments, BOOL animated)
{
	if(!tabController || !tabDocuments || [tabDocuments count] <= 0) return;

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
		BOOL privateTab = privateBrowsingEnabledForTabDocument(tabDocument);

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

BOOL isTabDocumentBlank(TabDocument* tabDocument)
{
	if([tabDocument respondsToSelector:@selector(isBlankDocument)])
	{
		return [tabDocument isBlankDocument];
	}
	else
	{
		return [tabDocument isBlank];
	}
}

//Modify tab expose alert for locked tabs (purely cosmetical) return: did anything?
BOOL updateTabExposeActionsForLockedTabs(BrowserController* browserController, UIAlertController* tabExposeAlertController)
{
	if(!tabExposeAlertController || !browserController) return NO;

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

	dispatch_async(dispatch_get_main_queue(), ^
	{
		[rootViewControllerForBrowserController(browserControllers().firstObject) presentViewController:alert animated:YES completion:nil];
	});
}

//I literally had to reverse engineer CFNetwork / Foundation to figure out how to unarchive the resume data on iOS 12, not a joke
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

	BOOL cellularData = NO;

	SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (sockaddr*)&zeroAddress);
	if(reachability)
	{
		SCNetworkReachabilityFlags flags;

		SCNetworkReachabilityGetFlags(reachability, &flags);

		if((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
		{
			cellularData = YES;
		}

		CFRelease(reachability);
	}

	return cellularData;
}