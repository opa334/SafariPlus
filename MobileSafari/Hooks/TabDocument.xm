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

#import "../SafariPlus.h"
#import "Extensions.h"

#import "../Classes/SPPreferenceManager.h"
#import "../Classes/SPCacheManager.h"
#import "../Classes/SPLocalizationManager.h"
#import "../Classes/SPDownload.h"
#import "../Classes/SPDownloadInfo.h"
#import "../Classes/SPDownloadManager.h"
#import "../Classes/SPTabManagerTableViewCell.h"
#import "../Defines.h"
#import "../Util.h"
#import "../Enums.h"

#import <libundirect/libundirect_dynamic.h>
#import <libundirect/libundirect_hookoverwrite.h>

#import <WebKit/WKFrameInfo.h>
#import <WebKit/WKNavigationAction.h>
#import <WebKit/WKNavigationDelegate.h>

#define castedSelf ((TabDocument*)self)

BOOL showAlert = YES;

static BOOL shouldFakeOpenLinksKey = NO;
static BOOL fakeOpenLinksValue = NO;

%hook NSUserDefaults

- (BOOL)boolForKey:(NSString*)key
{
	/*if([key isEqualToString:@"OpenLinksInBackground"])
	{
		NSLog(@"%@", [NSThread callStackSymbols]);
	}*/

	if(shouldFakeOpenLinksKey)
	{
		if([key isEqualToString:@"OpenLinksInBackground"])
		{
			return fakeOpenLinksValue;
		}
	}

	return %orig;
}

%end

/*
-[_SFLinkPreviewHelper menuElementsForSuggestedActions:]
-[_SFLinkPreviewHelper openInNewTabActionForURL:preActionHandler:]
_SFNavigationIntent: + (NSInteger)defaultTabOrder
*/

@interface _SFLinkPreviewHelper : NSObject
- (UIAction*)openInNewTabActionForURL:(NSURL*)arg1 preActionHandler:(void (^)(id))blockNamearg2;
- (NSURL*)url;
@end

typedef void (^UIActionHandler)(__kindof UIAction *action);
@interface UIAction (Private)
@property (nonatomic) UIActionHandler handler;
@end

%hook _SFLinkPreviewHelper

- (NSArray<UIAction*>*)menuElementsForSuggestedActions:(id)arg1
{
	NSArray<UIAction*>* menuElements = %orig;
	NSMutableArray<UIAction*>* menuElementsM = [menuElements mutableCopy];

	TabDocument* tabDocument = [self valueForKey:@"_handler"];
	BrowserController* browserController = browserControllerForTabDocument(tabDocument);
	BOOL privateBrowsing = privateBrowsingEnabled(browserController);

	if(preferenceManager.openInOppositeModeOptionEnabled && ([browserController isPrivateBrowsingAvailable] || privateBrowsing))
	{
		//Variable for title
		NSString* title;

		//Set title based on browsing mode
		if(privateBrowsing)
		{
			title = [localizationManager localizedSPStringForKey:@"OPEN_IN_NORMAL_MODE"];
		}
		else
		{
			title = [localizationManager localizedSPStringForKey:@"OPEN_IN_PRIVATE_MODE"];
		}

		UIAction* openInOppositeModeAction = [UIAction actionWithTitle:title
			image:[UIImage systemImageNamed:@"arrow.uturn.right.square"]
			identifier:nil
			handler:^(__kindof UIAction* action)
		{
			TabDocument* newDocument = [browserController.tabController _insertNewBlankTabDocumentWithPrivateBrowsing:!privateBrowsing inBackground:NO animated:YES];
			[newDocument loadURL:[self url] userDriven:YES];
		}];

		[menuElementsM insertObject:openInOppositeModeAction atIndex:2];
	}

	if(preferenceManager.bothTabOpenActionsEnabled)
	{
		shouldFakeOpenLinksKey = YES;
		fakeOpenLinksValue = NO;
		UIAction* openInNewTabAction = [self openInNewTabActionForURL:[self url] preActionHandler:nil];

		UIActionHandler prevNewTabHandler = openInNewTabAction.handler;
		openInNewTabAction.handler = ^(__kindof UIAction* action)
		{
			shouldFakeOpenLinksKey = YES;
			fakeOpenLinksValue = NO;

			prevNewTabHandler(action);

			shouldFakeOpenLinksKey = NO;
		};

		fakeOpenLinksValue = YES;
		UIAction* openInBackgroundAction = [self openInNewTabActionForURL:[self url] preActionHandler:nil];

		UIActionHandler prevBackgroundHandler = openInBackgroundAction.handler;
		openInBackgroundAction.handler = ^(__kindof UIAction* action)
		{
			shouldFakeOpenLinksKey = YES;
			fakeOpenLinksValue = YES;

			prevBackgroundHandler(action);

			shouldFakeOpenLinksKey = NO;
		};

		shouldFakeOpenLinksKey = NO;

		[menuElementsM removeObjectAtIndex:1];
		[menuElementsM insertObject:openInBackgroundAction atIndex:1];
		[menuElementsM insertObject:openInNewTabAction atIndex:1];
	}

	return [menuElementsM copy];
}

%end

%group iOS13to13_3_1

%hook _WKElementAction

+ (UIImage *)imageForElementActionType:(NSInteger)actionType //icon for "Open in Opposite Mode" action on iOS 13
{
	if(actionType == 100)
	{
		return [UIImage systemImageNamed:@"arrow.uturn.right.square"];
	}
	else
	{
		return %orig;
	}
}

%end

%end

%hook TabDocument

//%property (nonatomic,assign) BOOL locked;
%property (nonatomic,assign) BOOL accessAuthenticated;

%new
- (void)updateLockStateFromCache
{
	BOOL locked = [cacheManager isTabWithUUIDLocked:castedSelf.UUID];
	NSNumber* lockedN = [NSNumber numberWithBool:locked];
	objc_setAssociatedObject(self, @selector(locked), lockedN, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new
- (BOOL)locked
{
	NSNumber* lockedN = objc_getAssociatedObject(self, @selector(locked));

	if(!lockedN)
	{
		[self updateLockStateFromCache];
		lockedN = objc_getAssociatedObject(self, @selector(locked));
	}

	return [lockedN boolValue];
}

%new
- (void)writeLockStateToCache
{
	[cacheManager setLocked:castedSelf.locked forTabWithUUID:castedSelf.UUID];
}

%new
- (void)setLocked:(BOOL)locked
{
	NSNumber* lockedN = [NSNumber numberWithBool:locked];
	objc_setAssociatedObject(self, @selector(locked), lockedN, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

	[self writeLockStateToCache];

	[self updateLockButtons];

	if(preferenceManager.tabManagerEnabled && castedSelf.tabManagerViewCell)
	{
		[castedSelf.tabManagerViewCell updateContent];
	}
}

%new
- (void)updateLockButtons
{
	if(castedSelf.tiltedTabItem)
	{
		TabThumbnailView* thumbnailView;

		if([castedSelf.tiltedTabItem respondsToSelector:@selector(contentView)])
		{
			thumbnailView = castedSelf.tiltedTabItem.contentView;
		}
		else
		{
			thumbnailView = castedSelf.tiltedTabItem.layoutInfo.contentView;
		}

		thumbnailView.lockButton.selected = castedSelf.locked;

		[castedSelf.tiltedTabItem.tiltedTabView _layoutItemsWithTransition:0];	//Update close button
	}

	if(castedSelf.tabOverviewItem)
	{
		TabThumbnailView* thumbnailView;

		if([castedSelf.tabOverviewItem respondsToSelector:@selector(_thumbnailView)])
		{
			thumbnailView = castedSelf.tabOverviewItem.thumbnailView;
		}
		else
		{
			thumbnailView = castedSelf.tabOverviewItem.layoutInfo.itemView;
		}

		thumbnailView.lockButton.selected = castedSelf.locked;

		if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_14_0)
		{
			[castedSelf.tabOverviewItem.tabOverview setNeedsLayout];
		}
	}

	if(castedSelf.tabBarItem)
	{
		if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0)
		{
			if([castedSelf.tabBarItem.layoutInfo respondsToSelector:@selector(rightView)])
			{
				castedSelf.tabBarItem.layoutInfo.rightView.lockButton.selected = castedSelf.locked;
			}

			if([castedSelf.tabBarItem.layoutInfo respondsToSelector:@selector(leftView)])
			{
				castedSelf.tabBarItem.layoutInfo.leftView.lockButton.selected = castedSelf.locked;
			}

			if([castedSelf.tabBarItem.layoutInfo respondsToSelector:@selector(trailingView)])
			{
				castedSelf.tabBarItem.layoutInfo.trailingView.lockButton.selected = castedSelf.locked;
			}

			if([castedSelf.tabBarItem.layoutInfo respondsToSelector:@selector(leadingView)])
			{
				castedSelf.tabBarItem.layoutInfo.leadingView.lockButton.selected = castedSelf.locked;
			}

			if([castedSelf.tabBarItem.layoutInfo respondsToSelector:@selector(tabBarItemView)])
			{
				castedSelf.tabBarItem.layoutInfo.tabBarItemView.lockButton.selected = castedSelf.locked;
			}

			BrowserController* browserController = browserControllerForTabDocument(castedSelf);
			BOOL canClose;

			if([browserController.tabController respondsToSelector:@selector(tabCollectionView:canCloseItem:)])
			{
				canClose = [browserController.tabController tabCollectionView:browserController.tabController.tabBar canCloseItem:castedSelf.tabBarItem];
			}
			else
			{
				canClose = [browserController.tabController tabBar:browserController.tabController.tabBar canCloseItem:castedSelf.tabBarItem];
			}

			[castedSelf.tabBarItem.layoutInfo setCanClose:canClose];	//Update close button
		}
		else
		{
			BrowserController* browserController = browserControllerForTabDocument(castedSelf);

			MSHookIvar<TabBarItemView*>(castedSelf.tabBarItem, "_rightView").closeButton.hidden = ![browserController.tabController tabBar:browserController.tabController.tabBar canCloseItem:castedSelf.tabBarItem];
			MSHookIvar<TabBarItemView*>(castedSelf.tabBarItem, "_leftView").closeButton.hidden = ![browserController.tabController tabBar:browserController.tabController.tabBar canCloseItem:castedSelf.tabBarItem];
		}
	}
}

%new
- (BOOL)handleAlwaysOpenInNewTabForNavigationAction:(WKNavigationAction *)navigationAction
	decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
	if(navigationAction.navigationType == WKNavigationTypeLinkActivated)
	{
		//Stripped string of current url
		NSString* oldStripped = [[castedSelf URL].absoluteString stringStrippedByStrings:@[@"#",@"?"]];

		//Stripped string of new url
		NSString* newStripped = [navigationAction.request.URL.absoluteString stringStrippedByStrings:@[@"#",@"?"]];

		if(![newStripped isEqualToString:oldStripped])	//Link doesn't contain current URL
		{
			//Correctly handle launching external applications if needed
			if(NSClassFromString(@"LSAppLink"))
			{
				if(navigationAction._shouldOpenAppLinks && navigationAction.targetFrame.isMainFrame)
				{
					__block LSAppLink* b_appLink;

					dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
					[%c(LSAppLink) getAppLinkWithURL:navigationAction.request.URL completionHandler:^(LSAppLink* appLink, NSError* error)
					{
						b_appLink = appLink;
						dispatch_semaphore_signal(semaphore);
					}];
					dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

					if(b_appLink.openStrategy == 2)	//1: Open in browser, 2: Open in app (NO WARRANTY IMPLIED)
					{
						//Just run orig to open the application
						return YES;
					}
				}
			}

			//Cancel site load
			decisionHandler(WKNavigationActionPolicyCancel);

			BrowserController* controller = browserControllerForTabDocument(castedSelf);

			BOOL inBackground = preferenceManager.alwaysOpenNewTabInBackgroundEnabled;

			//Load URL in new tab
			if([controller respondsToSelector:@selector(loadURLInNewTab:inBackground:animated:)])
			{
				[controller loadURLInNewTab:navigationAction.request.URL inBackground:inBackground animated:YES];
			}
			else
			{
				[controller loadURLInNewWindow:navigationAction.request.URL inBackground:inBackground animated:YES];
			}

			if(inBackground)
			{
				BOOL showingTabBar;

				if([controller respondsToSelector:@selector(isShowingTabBar)])
				{
					showingTabBar = controller.isShowingTabBar;
				}
				else
				{
					showingTabBar = rootViewControllerForBrowserController(controller).isShowingTabBar;
				}

				if(!showingTabBar)
				{
					if([castedSelf.webView respondsToSelector:@selector(_requestActivatedElementAtPosition:completionBlock:)])	//Sorry iOS < 11, you're not getting that fancy animation :(
					{
						[castedSelf.webView _requestActivatedElementAtPosition:navigationAction._clickLocationInRootViewCoordinates completionBlock:^(_WKActivatedElementInfo *element)
						{
							if([self respondsToSelector:@selector(_animateElement:toToolbarButton:)])
							{
								[self _animateElement:element toToolbarButton:0];
							}
							else if([self respondsToSelector:@selector(_animateElement:toBarItem:)])
							{
								[self _animateElement:element toBarItem:5];
							}
							else if([self respondsToSelector:@selector(animateElement:toBarItem:)])
							{
								[self animateElement:element toBarItem:5];
							}
						}];
					}
				}
			}

			return NO;
		}
	}

	return YES;
}

%new
- (BOOL)handleForceHTTPSForNavigationAction:(WKNavigationAction*)navigationAction
	decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
	if(navigationAction.targetFrame.mainFrame)
	{
		NSURLRequest* request = navigationAction.request;

		if([request.URL.scheme isEqualToString:@"http"])
		{
			if(![preferenceManager isURLOnHTTPSExceptionsList:request.URL])
			{
				decisionHandler(WKNavigationActionPolicyCancel);

				NSMutableURLRequest* requestM = [request mutableCopy];

				requestM.URL = [requestM.URL httpsURL];

				//Load https site instead
				[castedSelf.webView loadRequest:requestM];

				return NO;
			}
		}
	}

	return YES;
}

%new
- (BOOL)handleDownloadAlertForNavigationResponse:(WKNavigationResponse *)navigationResponse
	decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
	NSString* MIMEType = navigationResponse.response.MIMEType;

	// Fix for profile add alert not appearing
	if([MIMEType isEqualToString:@"application/x-apple-aspen-config"])
	{
		return YES;
	}

	// Blob files are unsupported (it's theoretically possible to support them via JS fuckery but I'm lazy)
	if([navigationResponse.response.URL.scheme isEqualToString:@"blob"])
	{
		return YES;
	}

	//Check if MIMEType indicates that link can be downloaded
	if(showAlert && (!navigationResponse.canShowMIMEType ||
		[MIMEType containsString:@"video/"] ||
		[MIMEType containsString:@"audio/"] ||
		[MIMEType isEqualToString:@"application/pdf"]))
	{
		// Cancel loading, this request will be handled by Safari Plus
		decisionHandler(WKNavigationResponsePolicyCancel);

		// Copy the responses cookies into NSHTTPCookieStorage which NSURLSession uses
		// Fixes dropbox, etc.
		NSHTTPURLResponse *response = (NSHTTPURLResponse *)navigationResponse.response;
		NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[response allHeaderFields] forURL:response.URL];
		for(NSHTTPCookie *cookie in cookies)
		{
			[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
		}

		// Copy the WKWebView cookies into NSHTTPCookieStorage which NSURLSession uses
		// Only works on iOS 11ish and up
		// Adds support for sites that use authentication
		collectCookiesFromWebView(castedSelf.webView);

		BrowserController* controller = browserControllerForTabDocument(castedSelf);
		BrowserRootViewController* rootViewController = rootViewControllerForBrowserController(controller);

		//Create download info and configure it
		SPDownloadInfo* downloadInfo = [[SPDownloadInfo alloc] initWithRequest:navigationResponse._request];
		[downloadInfo updateHLSForSuggestedFilename:navigationResponse.response.suggestedFilename];
		downloadInfo.filesize = navigationResponse.response.expectedContentLength;
		downloadInfo.filename = navigationResponse.response.suggestedFilename;
		downloadInfo.presentationController = rootViewController;
		downloadInfo.sourceDocument = self;

		if(IS_PAD)
		{
			//Set iPad positions to download button
			BrowserToolbar* toolbar = activeToolbarOrToolbarForBarItemForBrowserController(controller, barButtonItemForSafariPlusOrderItem(BrowserToolbarDownloadsItem));
			if(toolbar)
			{
				UIView* buttonView = [toolbar._downloadsItem valueForKey:@"_view"];
				downloadInfo.sourceRect = [[buttonView superview] convertRect:buttonView.frame toView:rootViewController.view];
			}
			else
			{
				downloadInfo.sourceRect = CGRectZero;
			}
		}

		[downloadManager presentDownloadAlertWithDownloadInfo:downloadInfo];

		return NO;
	}
	else if(!showAlert)
	{
		showAlert = YES;
	}

	return YES;
}

%new
- (void)addAdditionalActionsForElement:(_WKActivatedElementInfo*)element toActions:(NSMutableArray*)actions
{
	//Get browserController
	BrowserController* browserController = browserControllerForTabDocument(castedSelf);

	//URL long pressed
	if(element.URL && ![element.URL.absoluteString isEqualToString:@""] && ![element.URL.absoluteString hasPrefix:@"javascript:"])
	{
		//Get browsing status
		BOOL privateBrowsing = privateBrowsingEnabled(browserController);

		if(preferenceManager.openInOppositeModeOptionEnabled && ([browserController isPrivateBrowsingAvailable] || privateBrowsing))
		{
			//Variable for title
			NSString* title;

			//Set title based on browsing mode
			if(privateBrowsing)
			{
				title = [localizationManager localizedSPStringForKey:@"OPEN_IN_NORMAL_MODE"];
			}
			else
			{
				title = [localizationManager localizedSPStringForKey:@"OPEN_IN_PRIVATE_MODE"];
			}

			_WKElementAction* openInOppositeModeAction = [%c(_WKElementAction)
				elementActionWithTitle:title actionHandler:^
			{
				if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0)
				{
					TabDocument* newDocument = [browserController.tabController _insertNewBlankTabDocumentWithPrivateBrowsing:!privateBrowsing inBackground:NO animated:YES];
					
					[newDocument loadURL:element.URL userDriven:YES];
				}
				else
				{
					TabDocument* tabDocument = [[%c(TabDocument) alloc] initWithTitle:nil URL:element.URL UUID:[NSUUID UUID] privateBrowsingEnabled:!privateBrowsing hibernated:YES bookmark:nil browserController:browserController];

					//iOS 11.2 and below somehow manage to open a private tab in normal mode if we don't manually switch
					if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_11_3)
					{
						BOOL animationsEnabled = [UIView areAnimationsEnabled];

						[UIView setAnimationsEnabled:NO];

						if([browserController respondsToSelector:@selector(dismissTransientUIAnimated:)])
						{
							[browserController dismissTransientUIAnimated:NO];
						}

						togglePrivateBrowsing(browserController);

						if(isTabDocumentBlank(browserController.tabController.activeTabDocument))
						{
							[browserController setFavoritesState:0 animated:YES];	//Dismisses the bookmark favorites grid view
							[browserController.tabController.activeTabDocument loadURL:element.URL userDriven:NO];
						}
						else
						{
							[browserController.tabController insertNewTabDocument:tabDocument openedFromTabDocument:castedSelf inBackground:NO animated:NO];
						}

						[UIView setAnimationsEnabled:animationsEnabled];
					}
					else
					{
						[browserController.tabController insertNewTabDocument:tabDocument openedFromTabDocument:castedSelf inBackground:NO animated:YES];			
					}
				}
			}];

			[openInOppositeModeAction setValue:@100 forKey:@"_type"];

			if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0)
			{
				[actions insertObject:openInOppositeModeAction atIndex:1];
			}
			else
			{
				[actions insertObject:openInOppositeModeAction atIndex:2];
			}			
		}

		if(preferenceManager.bothTabOpenActionsEnabled)
		{
			BOOL usesTabBar = NO;

			if([browserController.tabController respondsToSelector:@selector(usesTabBar)])
			{
				usesTabBar = browserController.tabController.usesTabBar;
			}
			else
			{
				usesTabBar = browserController.usesTabBar;
			}

			_WKElementAction* openInNewTabAction;
			_WKElementAction* openInBackgroundAction;

			shouldFakeOpenLinksKey = YES;
			fakeOpenLinksValue = NO;

			if([castedSelf respondsToSelector:@selector(_openInNewPageActionForElement:)])
			{
				openInNewTabAction = [self _openInNewPageActionForElement:element];
			}
			else
			{
				openInNewTabAction = [self _openInNewPageActionForElement:element previewViewController:nil];
			}

			fakeOpenLinksValue = YES;

			if([castedSelf respondsToSelector:@selector(_openInNewPageActionForElement:)])
			{
				openInBackgroundAction = [self _openInNewPageActionForElement:element];
			}
			else
			{
				openInBackgroundAction = [self _openInNewPageActionForElement:element previewViewController:nil];
			}

			//If a tabBar is used, the action returned by _openInNewPageActionForElement will always
			//have the title 'Open in New Tab', even if it should be 'Open in Background'
			//Therefore we need to manually set it to 'Open in Background'
			if(usesTabBar)
			{
				MSHookIvar<NSString*>(openInBackgroundAction, "_title") = [localizationManager localizedMSStringForKey:@"Open Link in Background Tab"];
			}

			shouldFakeOpenLinksKey = NO;
			fakeOpenLinksValue = NO;

			if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0)
			{
				[actions removeObjectAtIndex:0];
				[actions insertObject:openInBackgroundAction atIndex:0];
				[actions insertObject:openInNewTabAction atIndex:0];
			}
			else
			{
				[actions removeObjectAtIndex:1];
				[actions insertObject:openInBackgroundAction atIndex:1];
				[actions insertObject:openInNewTabAction atIndex:1];
			}
		}
	}

	if(preferenceManager.downloadManagerEnabled && kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_13_0)
	{
		if(element.URL && ![element.URL.absoluteString isEqualToString:@""] && ![element.URL.absoluteString hasPrefix:@"javascript:"] && preferenceManager.downloadSiteToActionEnabled)
		{
			_WKElementAction* downloadSiteToAction;

			downloadSiteToAction = [%c(_WKElementAction)
						elementActionWithTitle:[localizationManager
									localizedSPStringForKey:@"DOWNLOAD_SITE_TO"] actionHandler:^
			{
				//Create download request from URL
				NSURLRequest* downloadRequest = [NSURLRequest requestWithURL:element.URL];

				//Create downloadInfo
				SPDownloadInfo* downloadInfo = [[SPDownloadInfo alloc] initWithRequest:downloadRequest];

				//Set filename
				downloadInfo.filename = @"site.html";
				downloadInfo.customPath = YES;
				downloadInfo.presentationController = rootViewControllerForTabDocument(castedSelf);
				downloadInfo.sourceDocument = self;

				//Call downloadManager
				[downloadManager configureDownloadWithInfo:downloadInfo];
			}];

			if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0)
			{
				if(element.type == ElementInfoImage)
				{
					[actions insertObject:downloadSiteToAction atIndex:[actions count] - 4];
				}
				else
				{
					[actions insertObject:downloadSiteToAction atIndex:[actions count] - 1];
				}
			}
			else
			{
				if(element.type == ElementInfoImage)
				{
					[actions insertObject:downloadSiteToAction atIndex:[actions count] - 2];
				}
				else
				{
					[actions addObject:downloadSiteToAction];
				}
			}
		}

		if(element.type == ElementInfoImage && preferenceManager.downloadImageToActionEnabled)
		{
			_WKElementAction* downloadImageToAction;
			downloadImageToAction = [%c(_WKElementAction)
						 elementActionWithTitle:[localizationManager
									 localizedSPStringForKey:@"DOWNLOAD_IMAGE_TO"] actionHandler:^
			{
				//Create downloadInfo
				SPDownloadInfo* downloadInfo = [[SPDownloadInfo alloc] initWithImage:element.image];

				downloadInfo.filename = @"image.png";
				downloadInfo.customPath = YES;
				downloadInfo.presentationController = rootViewControllerForTabDocument(castedSelf);
				downloadInfo.sourceDocument = self;

				//Call SPDownloadManager with image
				[downloadManager configureDownloadWithInfo:downloadInfo];
			}];

			[actions addObject:downloadImageToAction];
		}
	}
}

//Force HTTPS + Always open in new tab option
%group iOS12_1_4Down

- (void)webView:(WKWebView *)webView
	decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
	decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
	if(preferenceManager.alwaysOpenNewTabEnabled)
	{
		if(![self handleAlwaysOpenInNewTabForNavigationAction:navigationAction decisionHandler:decisionHandler])
		{
			return;
		}
	}

	if(preferenceManager.forceHTTPSEnabled)
	{
		if(![self handleForceHTTPSForNavigationAction:navigationAction decisionHandler:decisionHandler])
		{
			return;
		}
	}

	%orig;
}

%end

//Present download alert if clicked link is a downloadable file
- (void)webView:(WKWebView *)webView
	decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse
	decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
	if(preferenceManager.downloadManagerEnabled)
	{
		if(![self handleDownloadAlertForNavigationResponse:navigationResponse decisionHandler:decisionHandler])
		{
			return;
		}
	}

	%orig;
}

%property (nonatomic, retain) SPTabManagerTableViewCell *tabManagerViewCell;
%property (nonatomic, retain) UIImage *currentTabIcon;

- (void)updateTabTitle
{
	if(preferenceManager.tabManagerEnabled && castedSelf.tabManagerViewCell)
	{
		[castedSelf.tabManagerViewCell updateContent];
	}

	%orig;
}

- (void)_setIcon:(UIImage*)icon isMonogram:(BOOL)arg2	//iOS 12 and up
{
	%orig;

	if(preferenceManager.tabManagerEnabled)
	{
		castedSelf.currentTabIcon = icon;

		if(castedSelf.tabManagerViewCell)
		{
			[castedSelf.tabManagerViewCell updateContent];
		}
	}
}

- (void)_createDocumentViewWithConfiguration:(WKWebViewConfiguration*)config
{
	%orig;

	if(preferenceManager.desktopButtonEnabled || preferenceManager.customUserAgentEnabled)
	{
		[castedSelf.webView sp_updateCustomUserAgent];
	}
}

%group iOS10Up

//Suppress mailTo alert
- (void)dialogController:(_SFDialogController*)dialogController willPresentDialog:(_SFDialog*)dialog
{
	if(preferenceManager.suppressMailToDialog && [[castedSelf URL].scheme isEqualToString:@"mailto"])
	{
		//Simulate press on yes button
		if([dialog respondsToSelector:@selector(finishWithPrimaryAction:text:)])
		{
			[dialog finishWithPrimaryAction:YES text:dialog.defaultText];

			if([dialogController respondsToSelector:@selector(_dismissDialog)])
			{
				[dialogController _dismissDialog];
			}
		}
		else if([dialogController respondsToSelector:@selector(_dismissCurrentDialogWithResponse:)])
		{
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^
			{
				[dialogController _dismissCurrentDialogWithResponse:@{@"password" : @"", @"selectedActionIndex" : @0, @"text" : @""}];
			});
		}
	}
	else
	{
		%orig;
	}
}

%end

%group iOS13Up

- (void)webView:(id)arg1 decidePolicyForNavigationAction:(id)navigationAction preferences:(id)arg3 decisionHandler:(void (^)(WKNavigationActionPolicy, _WKWebsitePolicies*))decisionHandler
{
	if(preferenceManager.alwaysOpenNewTabEnabled)
	{
		if(![self handleAlwaysOpenInNewTabForNavigationAction:navigationAction decisionHandler:^(WKNavigationActionPolicy policy)
		{
			//Wrap around new decisionHandler that takes 2 args now
			decisionHandler(policy, [[%c(_WKWebsitePolicies) alloc] init]);
		}])
		{
			return;
		}
	}

	if(preferenceManager.forceHTTPSEnabled)
	{
		if(![self handleForceHTTPSForNavigationAction:navigationAction decisionHandler:^(WKNavigationActionPolicy policy)
		{
			//Wrap around new decisionHandler that takes 2 args now
			decisionHandler(policy, [[%c(_WKWebsitePolicies) alloc] init]);
		}])
		{
			return;
		}
	}

	%orig;
}

%end

%group iOS12_2_to_13_3_1

- (NSMutableArray*)_actionsForElement:(_WKActivatedElementInfo*)element orFallbackURL:(id)arg2 defaultActions:(id)arg3 previewViewController:(id)arg4
{
	if((!arg4 || kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0) && (preferenceManager.downloadManagerEnabled ||
		     preferenceManager.bothTabOpenActionsEnabled ||
		     preferenceManager.openInOppositeModeOptionEnabled))
	{
		NSMutableArray* actions = %orig;

		[self addAdditionalActionsForElement:element toActions:actions];

		return actions;
	}

	return %orig;
}

%end

%group iOS12_2Up

- (void)_webView:(WKWebView *)webView
	decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
	userInfo:(NSDictionary*)userInfo
	decisionHandler:(void (^)(WKNavigationActionPolicy, _WKWebsitePolicies*))decisionHandler
{
	if(preferenceManager.alwaysOpenNewTabEnabled)
	{
		if(![self handleAlwaysOpenInNewTabForNavigationAction:navigationAction decisionHandler:^(WKNavigationActionPolicy policy)
		{
			//Wrap around new decisionHandler that takes 2 args now
			decisionHandler(policy, [[%c(_WKWebsitePolicies) alloc] init]);
		}])
		{
			return;
		}
	}

	if(preferenceManager.forceHTTPSEnabled)
	{
		if(![self handleForceHTTPSForNavigationAction:navigationAction decisionHandler:^(WKNavigationActionPolicy policy)
		{
			//Wrap around new decisionHandler that takes 2 args now
			decisionHandler(policy, [[%c(_WKWebsitePolicies) alloc] init]);
		}])
		{
			return;
		}
	}

	%orig;
}

%end

%group iOS9to12_1_4

//Extra 'Open in new Tab' option + 'Open in opposite Mode' option + 'Download to' option
- (NSMutableArray*)_actionsForElement:(_WKActivatedElementInfo*)element
	defaultActions:(NSArray*)arg2 previewViewController:(id)arg3
{
	if(!arg3 && (preferenceManager.downloadManagerEnabled ||
		     preferenceManager.bothTabOpenActionsEnabled ||
		     preferenceManager.openInOppositeModeOptionEnabled))
	{
		NSMutableArray* actions = %orig;

		[self addAdditionalActionsForElement:element toActions:actions];

		return actions;
	}

	return %orig;
}

%end

%group iOS8

//Extra 'Open in new Tab' option + 'Open in opposite Mode' option + 'Download to' option
- (NSMutableArray*)actionsForElement:(_WKActivatedElementInfo*)element
	defaultActions:(NSArray*)arg2
{
	if(preferenceManager.downloadManagerEnabled ||
	   preferenceManager.bothTabOpenActionsEnabled ||
	   preferenceManager.openInOppositeModeOptionEnabled)
	{
		NSMutableArray* actions = %orig;

		[self addAdditionalActionsForElement:element toActions:actions];

		return actions;
	}

	return %orig;
}

%end

- (instancetype)_initWithTitle:(id)arg1 URL:(id)arg2 UUID:(id)arg3 privateBrowsingEnabled:(BOOL)arg4 controlledByAutomation:(BOOL)arg5 bookmark:(id)arg6 browserController:(id)arg7 createDocumentView:(id)arg8
{
	TabDocument* orig = %orig;

	orig.accessAuthenticated = NO;

	return orig;
}

- (instancetype)_initWithTitle:(id)arg1 URL:(id)arg2 UUID:(NSUUID*)UUID privateBrowsingEnabled:(BOOL)arg4 bookmark:(id)arg5 browserController:(id)arg6 createDocumentView:(id)arg7
{
	TabDocument* orig = %orig;

	orig.accessAuthenticated = NO;

	return orig;
}

/*- (instancetype)_initWithTitle:(id)arg1 URL:(id)arg2 UUID:(NSUUID*)UUID privateBrowsingEnabled:(BOOL)arg4 bookmark:(id)arg5 browserController:(id)arg6
{
	NSLog(@"initWithTitle");
	TabDocument* orig = %orig;

	orig.accessAuthenticated = NO;

	return orig;
}*/

%end

%hook NSError

// Invoked by -[TabDocument canShowPageFormatMenu]
// If there's an error loading the site, the page format button normally doesn't show
// As Force HTTPS can be the issue for the loading failure and there's a button
// to add an exception inside the format page, we want to force it to show in that case
- (BOOL)_sf_recoverableByPageFormatMenu
{
	BOOL orig = %orig;

	if(preferenceManager.forceHTTPSEnabled)
	{
		return YES;
	}
	
	return orig;
}

%end

void initTabDocument()
{
	Class TabDocumentClass;

	if(kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_8_0)
	{
		TabDocumentClass = objc_getClass("TabDocument");
	}
	else
	{
		TabDocumentClass = objc_getClass("TabDocumentWK2");
	}

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0)
	{
		%init(iOS13Up, TabDocument=TabDocumentClass);
		
		if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_13_4)
		{
			%init(iOS13to13_3_1);
		}
	}

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_12_2)
	{
		%init(iOS12_2Up, TabDocument=TabDocumentClass);

		if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_13_4)
		{
			%init(iOS12_2_to_13_3_1, TabDocument=TabDocumentClass);
		}
	}
	else if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0)
	{
		%init(iOS9to12_1_4, TabDocument=TabDocumentClass);
	}
	else
	{
		%init(iOS8, TabDocument=TabDocumentClass);
	}

	if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_12_2)
	{
		%init(iOS12_1_4Down, TabDocument=TabDocumentClass);
	}

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0)
	{
		%init(iOS10Up, TabDocument=TabDocumentClass);
	}

	%init(TabDocument=TabDocumentClass);
}
