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

#import "../Classes/SPPreferenceManager.h"
#import "../Classes/SPLocalizationManager.h"
#import "../Classes/SPDownload.h"
#import "../Classes/SPDownloadInfo.h"
#import "../Classes/SPDownloadManager.h"
#import "../Defines.h"
#import "../Shared.h"
#import "../Enums.h"

#import <WebKit/WKFrameInfo.h>
#import <WebKit/WKNavigationAction.h>
#import <WebKit/WKNavigationDelegate.h>

#define castedSelf ((TabDocument*)self)

BOOL showAlert = YES;

%hook TabDocument

%property(assign,nonatomic) BOOL desktopMode;

%new
- (void)updateDesktopMode
{
  if(castedSelf.webView)
  {
    BOOL desktopButtonSelected;

    desktopButtonSelected = browserControllerForTabDocument(castedSelf).tabController.desktopButtonSelected;

    castedSelf.desktopMode = desktopButtonSelected;

    if(desktopButtonSelected)
    {
      castedSelf.customUserAgent = desktopUserAgent;
    }
    else
    {
      castedSelf.customUserAgent = @"";
    }
  }
}

//This method creates the SafariWebView
- (void)_createDocumentViewWithConfiguration:(id)arg1
{
  %orig;

  //Change user agent of the webView right after it is created
  [castedSelf updateDesktopMode];
}

/*
- (void)setClosed:(BOOL)closed userDriven:(BOOL)userDriven
{
  if(!(castedSelf.tiltedTabItem.layoutInfo.contentView.isLocked ||
    castedSelf.tabOverviewItem.layoutInfo.itemView.isLocked))
  {
    %orig;
  }
}
*/

//Always open in new tab option
- (void)webView:(WKWebView *)webView
  decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
  decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
  if(preferenceManager.alwaysOpenNewTabEnabled)
  {
    if(navigationAction.navigationType == WKNavigationTypeLinkActivated)
    {
      //Stripped string of current url
      NSString* oldStripped = [[castedSelf URL].absoluteString stringStrippedByStrings:@[@"#",@"?"]];

      //Stripped string of new url
      NSString* newStripped = [navigationAction.request.URL.absoluteString stringStrippedByStrings:@[@"#",@"?"]];

      if(![newStripped isEqualToString:oldStripped]) //Link doesn't contain current URL
      {
        //Cancel site load
        decisionHandler(WKNavigationResponsePolicyCancel);

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

            if(appLink.openStrategy == 2) //1: Open in browser, 2: Open in app (NO WARRANTY IMPLIED)
            {
              NSDictionary* browserState = @
              {
                @"browserReuseTab" : @1,
                @"updateAppLinkOpenStrategy" : @YES
              };

              if([castedSelf respondsToSelector:@selector(_openAppLinkInApp:fromOriginalRequest:updateAppLinkStrategy:webBrowserState:completionHandler:)]) //Works on iOS 11
              {
                [castedSelf _openAppLinkInApp:appLink fromOriginalRequest:navigationAction.request updateAppLinkStrategy:YES webBrowserState:browserState completionHandler:nil];
              }
              else //Works on iOS 10 and 9
              {
                [appLink openInWebBrowser:NO setOpenStrategy:2 webBrowserState:browserState completionHandler:nil];
              }

              return;
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

        return;
      }
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

      return;
    }
    else if(!showAlert)
    {
      showAlert = YES;
    }

    %orig;
  }
  else
  {
    %orig;
  }
}

- (void)_loadStartedDuringSimulatedClickForURL:(NSURL*)URL
{
  if(preferenceManager.forceHTTPSEnabled && [self shouldRequestHTTPS:URL])
  {
    NSURL* newURL = [URL httpsURL];
    if(![[newURL absoluteString] isEqualToString:[URL absoluteString]])
    {
      //arg1 and newURL are not the same -> load newURL
      [castedSelf loadURL:newURL userDriven:NO];
      return;
    }
  }

  %orig;
}

- (void)reload
{
  if(preferenceManager.forceHTTPSEnabled)
  {
    NSURL* currentURL = [castedSelf URL];
    if(currentURL && [self shouldRequestHTTPS:currentURL])
    {
      NSURL* tmpURL = [currentURL httpsURL];
      if(![[tmpURL absoluteString] isEqualToString:[currentURL absoluteString]])
      {
        //currentURL and tmpURL are not the same -> load tmpURL
        [castedSelf loadURL:tmpURL userDriven:NO];
        return;
      }
    }
  }

  %orig;
}

//Checks through exceptions whether https should be forced or not
%new
- (BOOL)shouldRequestHTTPS:(NSURL*)URL
{
  if(!URL)
  {
    return NO;
  }

  for(NSString* exception in [preferenceManager forceHTTPSExceptions])
  {
    if([[URL host] rangeOfString:exception].location != NSNotFound)
    {
      //Exception list contains host -> return false
      return NO;
    }
  }
  //Exception list doesn't contain host -> return false
  return YES;
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
    preferenceManager.openInNewTabOptionEnabled ||
    preferenceManager.openInOppositeModeOptionEnabled))
  {
    NSMutableArray* actions = %orig;

    //Get browserController
    BrowserController* browserController = browserControllerForTabDocument(castedSelf);

    //URL long pressed
    if(element.URL && ![element.URL.absoluteString isEqualToString:@""])
    {
      if(preferenceManager.openInOppositeModeOptionEnabled)
      {
        //Variable for title
        NSString* title;

        //Get browsing status
        BOOL privateBrowsing = privateBrowsingEnabled(browserController);

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
          elementActionWithTitle:title actionHandler:
        ^{
          //Toggle browsing mode
          togglePrivateBrowsing(browserController);

          //After 0.1 seconds, open URL in new tab
          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(),
          ^{
            if([browserController.tabController.activeTabDocument isBlankDocument])
            {
              [browserController setFavoritesState:0 animated:YES]; //Dismisses the bookmark favorites grid view
              [browserController.tabController.activeTabDocument loadURL:element.URL userDriven:NO];
            }
            else
            {
              if([browserController respondsToSelector:@selector(loadURLInNewTab:inBackground:)])
              {
                [browserController loadURLInNewTab:element.URL inBackground:NO];
              }
              else
              {
                [browserController loadURLInNewWindow:element.URL inBackground:NO];
              }
            }
          });
        }];

        [actions insertObject:openInOppositeModeAction atIndex:2];
      }

      if(preferenceManager.openInNewTabOptionEnabled)
      {
        //Only needed when there is no tabBar
        if(!browserController.tabController.usesTabBar)
        {
          _WKElementAction* openInNewTabAction = [%c(_WKElementAction)
            elementActionWithTitle:[localizationManager
            localizedMSStringForKey:@"Open Link in New Tab"] actionHandler:
          ^{
            //Open URL in new tab
            if([browserController respondsToSelector:@selector(loadURLInNewTab:inBackground:)])
            {
              [browserController loadURLInNewTab:element.URL inBackground:NO];
            }
            else
            {
              [browserController loadURLInNewWindow:element.URL inBackground:NO];
            }
          }];

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
    return actions;
  }
  return %orig;
}

//desktop mode + ForceHTTPS
- (id)_loadURLInternal:(NSURL*)URL userDriven:(BOOL)arg2
{
  if(preferenceManager.forceHTTPSEnabled && [self shouldRequestHTTPS:URL])
  {
    return %orig([URL httpsURL], arg2);
  }
  return %orig;
}

- (id)loadURL:(NSURL*)URL fromBookmark:(id)arg2
{
  if(preferenceManager.forceHTTPSEnabled && [self shouldRequestHTTPS:URL])
  {
    return %orig([URL httpsURL], arg2);
  }
  return %orig;
}

//Exception because method uses NSString instead of NSURL
- (NSString*)loadUserTypedAddress:(NSString*)arg1
{
  if(preferenceManager.forceHTTPSEnabled || preferenceManager.desktopButtonEnabled)
  {
    NSString* newURL = arg1;
    if((preferenceManager.forceHTTPSEnabled && newURL) &&
      ([newURL rangeOfString:@"https://"].location == NSNotFound))
    {
      if([newURL rangeOfString:@"://"].location == NSNotFound)
      {
        //URL has not scheme -> Default to http://
        newURL = [@"http://" stringByAppendingString:newURL];
      }

      if([self shouldRequestHTTPS:[NSURL URLWithString:newURL]])
      {
        //Set scheme to https://
        newURL = [newURL stringByReplacingOccurrencesOfString:@"http://"
          withString:@"https://"];
      }
    }

    return %orig(newURL);
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
    preferenceManager.openInNewTabOptionEnabled ||
    preferenceManager.openInOppositeModeOptionEnabled)
  {
    NSMutableArray* actions = %orig;

    //Get browserController
    BrowserController* browserController = browserControllerForTabDocument(castedSelf);

    //URL long pressed
    if(element.URL && ![element.URL.absoluteString isEqualToString:@""])
    {
      if(preferenceManager.openInOppositeModeOptionEnabled)
      {
        //Variable for title
        NSString* title;

        //Get browsing status
        BOOL privateBrowsing = privateBrowsingEnabled(browserController);

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
          elementActionWithTitle:title actionHandler:
        ^{
          //Toggle browsing mode
          togglePrivateBrowsing(browserController);

          [NSTimer scheduledTimerWithTimeInterval:0.1
            target:[NSBlockOperation blockOperationWithBlock:^
            {
              //After 0.1 seconds, open URL in new tab
              [browserController loadURLInNewWindow:element.URL inBackground:NO];
            }]
            selector:@selector(main)
            userInfo:nil
            repeats:NO];
        }];

        [actions insertObject:openInOppositeModeAction atIndex:2];
      }

      if(preferenceManager.openInNewTabOptionEnabled)
      {
        //Only needed when there is no tabBar
        if(!browserController.tabController.usesTabBar)
        {
          _WKElementAction* openInNewTabAction = [%c(_WKElementAction)
            elementActionWithTitle:[localizationManager
            localizedMSStringForKey:@"Open Link in New Tab"] actionHandler:
          ^{
            //Open URL in new tab
            [browserController loadURLInNewWindow:element.URL inBackground:NO];
          }];

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

        if(element.type == ElementInfoImage)
        {
          [actions insertObject:downloadSiteToAction atIndex:[actions count] - 2];
        }
        else
        {
          [actions addObject:downloadSiteToAction];
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
    return actions;
  }
  return %orig;
}

- (void)loadURL:(NSURL*)URL userDriven:(BOOL)arg2
{
  if(preferenceManager.forceHTTPSEnabled && [self shouldRequestHTTPS:URL])
  {
    %orig([URL httpsURL], arg2);
    return;
  }

  %orig;
}

- (void)loadURL:(NSURL*)URL fromBookmark:(id)arg2
{
  if(preferenceManager.forceHTTPSEnabled && [self shouldRequestHTTPS:URL])
  {
    %orig([URL httpsURL], arg2);
    return;
  }

  %orig;
}

//Exception because method uses NSString instead of NSURL
- (void)loadUserTypedAddress:(NSString*)arg1
{
  if(preferenceManager.forceHTTPSEnabled || preferenceManager.desktopButtonEnabled)
  {
    NSString* newURL = arg1;
    if((preferenceManager.forceHTTPSEnabled && newURL) &&
      ([newURL rangeOfString:@"https://"].location == NSNotFound))
    {
      if([newURL rangeOfString:@"://"].location == NSNotFound)
      {
        //URL has not scheme -> Default to http://
        newURL = [@"http://" stringByAppendingString:newURL];
      }

      if([self shouldRequestHTTPS:[NSURL URLWithString:newURL]])
      {
        //Set scheme to https://
        newURL = [newURL stringByReplacingOccurrencesOfString:@"http://"
          withString:@"https://"];
      }
    }

    return %orig(newURL);
  }
  return %orig;
}

%end

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
