// TabDocument.xm
// (c) 2018 opa334

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

//Desktop mode user agent (set once)
static NSString *desktopUserAgent;

%hook TabDocument

%property (nonatomic,assign) NSInteger desktopMode;
//%property (nonatomic,assign) BOOL locked;
%property (nonatomic,assign) BOOL accessAuthenticated;

%new
- (BOOL)locked
{
	return [cacheManager isTabWithUUIDLocked:castedSelf.UUID];
}

%new
- (void)setLocked:(BOOL)locked
{
	[cacheManager setLocked:locked forTabWithUUID:castedSelf.UUID];
}

%new
- (BOOL)updateDesktopMode
{
	if(preferenceManager.desktopButtonEnabled)
	{
		static dispatch_once_t onceToken = 0;
		dispatch_once(&onceToken, ^	//Dynamically generate the appropriate desktop user agent for the current device
		{
			NSArray<NSString*>* userAgentComponents = [castedSelf.webView._applicationNameForUserAgent componentsSeparatedByString:@" "];

			//userAgentComponents[0] = Version/<iOS Version>
			//userAgentComponents[1] = Mobile/<Build Number> (Not needed for desktop agent)
			//userAgentComponents[2] = Safari/<Safari Version>

			NSString* webKitVersion = [userAgentComponents[2] componentsSeparatedByString:@"/"].lastObject;	//Same as Safari Version

			desktopUserAgent = [NSString stringWithFormat:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/%@ (KHTML, like Gecko) %@ %@", webKitVersion, userAgentComponents[0], userAgentComponents[2]];
		});

		if(!castedSelf.isHibernated)
		{
			BOOL desktopButtonSelected;

			desktopButtonSelected = browserControllerForTabDocument(castedSelf).tabController.desktopButtonSelected;

			NSInteger newDesktopMode = (NSInteger)desktopButtonSelected + 1;

			if(castedSelf.desktopMode != newDesktopMode)
			{
				castedSelf.desktopMode = newDesktopMode;

				if(desktopButtonSelected)
				{
					castedSelf.customUserAgent = desktopUserAgent;
				}
				else
				{
					castedSelf.customUserAgent = @"";
				}

				return YES;
			}
		}
	}

	return NO;
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
			//Cancel site load
			decisionHandler(WKNavigationActionPolicyCancel);

			//Correctly handle launching external applications if needed
			if(NSClassFromString(@"LSAppLink"))
			{
				if(navigationAction._shouldOpenAppLinks && navigationAction.targetFrame.isMainFrame)
				{
					__block LSAppLink *appLink;

					dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
					[%c(LSAppLink) getAppLinkWithURL:navigationAction.request.URL completionHandler:^(LSAppLink* _appLink, NSError* error)
					{
						appLink = _appLink;

						dispatch_semaphore_signal(semaphore);
					}];
					dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

					if(appLink.openStrategy == 2)	//1: Open in browser, 2: Open in app (NO WARRANTY IMPLIED)
					{
						NSDictionary* browserState = @
									     {
										     @"browserReuseTab" : @1,
										     @"updateAppLinkOpenStrategy" : @YES
						};

						if([castedSelf respondsToSelector:@selector(_openAppLinkInApp:fromOriginalRequest:updateAppLinkStrategy:webBrowserState:completionHandler:)])	//Works on iOS 11
						{
							[castedSelf _openAppLinkInApp:appLink fromOriginalRequest:navigationAction.request updateAppLinkStrategy:YES webBrowserState:browserState completionHandler:nil];
						}
						else	//Works on iOS 10 and 9
						{
							[appLink openInWebBrowser:NO setOpenStrategy:2 webBrowserState:browserState completionHandler:nil];
						}

						return NO;
					}
				}
			}

			BrowserController* controller = browserControllerForTabDocument(castedSelf);

			BOOL inBackground = preferenceManager.alwaysOpenNewTabInBackgroundEnabled;

			//Load URL in new tab
			if([controller respondsToSelector:@selector(loadURLInNewTab:inBackground:animated:)])
			{
				[controller loadURLInNewTab:navigationAction.request.URL
				 inBackground:inBackground animated:YES];
			}
			else
			{
				[controller loadURLInNewWindow:navigationAction.request.URL
				 inBackground:inBackground animated:YES];
			}

			if(inBackground)
			{
				if(!controller.isShowingTabBar)
				{
					if([castedSelf.webView respondsToSelector:@selector(_requestActivatedElementAtPosition:completionBlock:)])	//Sorry iOS < 11, you're not getting that fancy animation :(
					{
						[castedSelf.webView _requestActivatedElementAtPosition:navigationAction._clickLocationInRootViewCoordinates completionBlock:^(_WKActivatedElementInfo *element)
						{
							[self _animateElement:element toToolbarButton:0];
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
- (BOOL)handleDesktopModeForNavigationAction:(WKNavigationAction*)navigationAction
	decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
	if(navigationAction.targetFrame.mainFrame)
	{
		BOOL needsReload = [castedSelf updateDesktopMode];

		if(needsReload)
		{
			decisionHandler(WKNavigationActionPolicyCancel);
			if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0)
			{
				[castedSelf _loadURLInternal:navigationAction.request.URL userDriven:NO];
			}
			else
			{
				[((TabDocument8*)self) _loadURLInternal:navigationAction.request.URL userDriven:NO];
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
	//Get MIMEType
	NSString* MIMEType = navigationResponse.response.MIMEType;

	//Check if MIMEType indicates that link can be downloaded
	if(showAlert && (!navigationResponse.canShowMIMEType ||
			 [MIMEType rangeOfString:@"video/"].location != NSNotFound ||
			 [MIMEType rangeOfString:@"audio/"].location != NSNotFound ||
			 [MIMEType isEqualToString:@"application/pdf"]))
	{
		//Cancel loading
		decisionHandler(WKNavigationResponsePolicyCancel);

		//Fix for some sites (dropbox etc.), credits to https://stackoverflow.com/a/34740466
		NSHTTPURLResponse *response = (NSHTTPURLResponse *)navigationResponse.response;
		NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[response allHeaderFields] forURL:response.URL];
		for(NSHTTPCookie *cookie in cookies)
		{
			[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
		}

		//Get browserController and rootViewController
		BrowserController* controller = browserControllerForTabDocument(castedSelf);
		BrowserRootViewController* rootViewController = rootViewControllerForBrowserController(controller);

		//Create download info and configure it
		SPDownloadInfo* downloadInfo = [[SPDownloadInfo alloc] initWithRequest:navigationResponse._request];
		downloadInfo.filesize = navigationResponse.response.expectedContentLength;
		downloadInfo.filename = navigationResponse.response.suggestedFilename;
		downloadInfo.presentationController = rootViewController;
		downloadInfo.sourceDocument = self;

		if(IS_PAD)
		{
			//Set iPad positions to download button
			UIView* button = MSHookIvar<UIView*>(controller.activeToolbar._downloadsItem, "_view");
			downloadInfo.sourceRect = [[button superview] convertRect:button.frame toView:rootViewController.view];
		}

		//Present download alert
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
	if(element.URL && ![element.URL.absoluteString isEqualToString:@""])
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
				TabDocument* tabDocument;

				tabDocument = [[%c(TabDocument) alloc] initWithTitle:nil URL:element.URL UUID:[NSUUID UUID] privateBrowsingEnabled:!privateBrowsing hibernated:YES bookmark:nil browserController:browserController];

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

					if([browserController.tabController.activeTabDocument isBlankDocument])
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

			}];

			[actions insertObject:openInOppositeModeAction atIndex:2];
		}

		if(preferenceManager.bothTabOpenActionsEnabled)
		{
			//Only needed when there is no tabBar
			if(!browserController.tabController.usesTabBar)
			{
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

				shouldFakeOpenLinksKey = NO;
				fakeOpenLinksValue = NO;

				[actions removeObjectAtIndex:1];
				[actions insertObject:openInBackgroundAction atIndex:1];
				[actions insertObject:openInNewTabAction atIndex:1];
			}
		}
	}

	if(preferenceManager.enhancedDownloadsEnabled)
	{
		if(element.URL && ![element.URL.absoluteString isEqualToString:@""] && preferenceManager.downloadSiteToActionEnabled)
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

				//Call SPDownloadManager with image
				[downloadManager configureDownloadWithInfo:downloadInfo];
			}];

			[actions addObject:downloadImageToAction];
		}
	}
}

//Force HTTPS + Always open in new tab option
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

	if(preferenceManager.desktopButtonEnabled)
	{
		if(![self handleDesktopModeForNavigationAction:navigationAction decisionHandler:decisionHandler])
		{
			return;
		}
	}

	%orig;
}

//Present download alert if clicked link is a downloadable file
- (void)webView:(WKWebView *)webView
	decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse
	decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
	if(preferenceManager.enhancedDownloadsEnabled)
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

%group iOS10Up

//Supress mailTo alert
- (void)dialogController:(_SFDialogController*)dialogController
	willPresentDialog:(_SFDialog*)dialog
{
	if(preferenceManager.suppressMailToDialog && [[castedSelf URL].scheme isEqualToString:@"mailto"])
	{
		//Simulate press on yes button
		[dialog finishWithPrimaryAction:YES text:dialog.defaultText];

		//Dismiss dialog
		[dialogController _dismissDialog];
	}
	else
	{
		%orig;
	}
}

%end

%group iOS9Up

//Extra 'Open in new Tab' option + 'Open in opposite Mode' option + 'Download to' option
- (NSMutableArray*)_actionsForElement:(_WKActivatedElementInfo*)element
	defaultActions:(NSArray*)arg2 previewViewController:(id)arg3
{
	if(!arg3 && (preferenceManager.enhancedDownloadsEnabled ||
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
	if(preferenceManager.enhancedDownloadsEnabled ||
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

- (instancetype)_initWithTitle:(id)arg1 URL:(id)arg2 UUID:(NSUUID*)UUID privateBrowsingEnabled:(BOOL)arg4 bookmark:(id)arg5 browserController:(id)arg6 createDocumentView:(id)arg7
{

	TabDocument* orig = %orig;

	orig.desktopMode = 0;
	orig.accessAuthenticated = NO;

	return orig;
}

%end

void initTabDocument()
{
	Class TabDocumentClass;

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0)
	{
		TabDocumentClass = objc_getClass("TabDocument");
		%init(iOS9Up, TabDocument=TabDocumentClass);
	}
	else
	{
		TabDocumentClass = objc_getClass("TabDocumentWK2");
		%init(iOS8, TabDocument=TabDocumentClass);
	}

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0)
	{
		%init(iOS10Up, TabDocument=TabDocumentClass);
	}

	%init(TabDocument=TabDocumentClass);
}
