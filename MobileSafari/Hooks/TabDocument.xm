// TabDocument.xm
// (c) 2017 opa334

#import "../SafariPlus.h"

#import "../Classes/SPPreferenceManager.h"
#import "../Classes/SPLocalizationManager.h"
#import "../Classes/SPDownload.h"
#import "../Classes/SPDownloadInfo.h"
#import "../Classes/SPDownloadManager.h"
#import "../Defines.h"
#import "../Shared.h"

#import <WebKit/WKNavigationAction.h>
#import <WebKit/WKNavigationDelegate.h>

#define castedSelf ((TabDocument*)self)

BOOL showAlert = YES;

%group iOS10
%hook TabDocument

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

//Extra 'Open in new Tab' option + 'Download to option'
- (NSMutableArray*)_actionsForElement:(_WKActivatedElementInfo*)arg1
  defaultActions:(NSArray*)arg2 previewViewController:(id)arg3
{
  if(!arg3 && (preferenceManager.enhancedDownloadsEnabled ||
    preferenceManager.openInNewTabOptionEnabled ||
    preferenceManager.openInOppositeModeOptionEnabled))
  {
    NSMutableArray* options = %orig;

    if(preferenceManager.openInOppositeModeOptionEnabled && arg1.type == 0)
    {
      //Create variable for title
      NSString* title;

      //Get title based on browsing mode
      if(castedSelf.browserController.privateBrowsingEnabled)
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
        [castedSelf.browserController togglePrivateBrowsing];

        [NSTimer scheduledTimerWithTimeInterval:0.1
          target:[NSBlockOperation blockOperationWithBlock:^
          {
            //After 0.1 seconds, open URL in new tab
            [castedSelf.browserController loadURLInNewTab:arg1.URL inBackground:NO];
          }]
          selector:@selector(main)
          userInfo:nil
          repeats:NO
          ];
      }];

      [options insertObject:openInOppositeModeAction atIndex:2];
    }

    if(preferenceManager.openInNewTabOptionEnabled && arg1.type == 0)
    {
      //Long pressed element is link -> Check for tabBar
      if(!castedSelf.browserController.tabController.usesTabBar)
      {
        //tabBar is not active -> Create in new tab option to alert
        _WKElementAction* openInNewTabAction = [%c(_WKElementAction)
          elementActionWithTitle:[localizationManager
          localizedMSStringForKey:@"Open Link in New Tab"] actionHandler:
        ^{
          //Open URL in new tab
          [castedSelf.browserController loadURLInNewTab:arg1.URL inBackground:NO];
        }];

        //Add option to alert
        [options insertObject:openInNewTabAction atIndex:1];
      }
    }

    if(preferenceManager.enhancedDownloadsEnabled)
    {
      //EnhancedDownloads are enabled -> create 'Download to ...' option
      _WKElementAction* downloadToAction = [%c(_WKElementAction)
        elementActionWithTitle:[localizationManager
        localizedSPStringForKey:@"DOWNLOAD_TO"] actionHandler:^
      {
        switch(arg1.type)
        {
          case 0: //Link long pressed
          {
            //Create download request from URL
            NSURLRequest* downloadRequest = [NSURLRequest requestWithURL:arg1.URL];

            //Create downloadInfo
            SPDownloadInfo* downloadInfo = [[SPDownloadInfo alloc]
              initWithRequest:downloadRequest];

            //Set filename
            downloadInfo.filename = @"site.html";
            downloadInfo.customPath = YES;

            //Call downloadManager
            [[SPDownloadManager sharedInstance]
              configureDownloadWithInfo:downloadInfo];
            break;
          }
          case 1: //Image long pressed
          {
            SPDownloadInfo* downloadInfo = [[SPDownloadInfo alloc]
              initWithImage:arg1.image];

            downloadInfo.filename = @"image.png";
            downloadInfo.customPath = YES;

            //Call SPDownloadManager with image
            [[SPDownloadManager sharedInstance] configureDownloadWithInfo:downloadInfo];
            break;
          }
          default:
          break;
        }
      }];

      switch(arg1.type)
      {
        case 0: //Link long pressed
        {
          //Add option to alert before share option
          [options insertObject:downloadToAction atIndex:[options count] - 1];
          break;
        }
        case 1: //Image long pressed
        {
          //Add option to alert
          [options addObject:downloadToAction];
          break;
        }
        default:
        break;
      }
    }

    return options;
  }

  return %orig;
}

%end
%end

%group iOS9
%hook TabDocument

//Extra 'Open in new Tab' option + 'Download to option'
- (NSMutableArray*)_actionsForElement:(_WKActivatedElementInfo*)arg1
  defaultActions:(NSArray*)arg2 previewViewController:(id)arg3
{
  if(!arg3 && (preferenceManager.enhancedDownloadsEnabled ||
    preferenceManager.openInNewTabOptionEnabled ||
    preferenceManager.openInOppositeModeOptionEnabled))
  {
    NSMutableArray* options = %orig;

    if(preferenceManager.openInOppositeModeOptionEnabled &&
      (arg1.type == 120259084288 || arg1.type == 0))
    {
      //Create variable for title
      NSString* title;

      //Get browserController
      BrowserController* browserController =
        MSHookIvar<BrowserController*>(castedSelf, "_browserController");

      //Get title based on browsing mode
      if(browserController.privateBrowsingEnabled)
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
        [browserController togglePrivateBrowsing];

        [NSTimer scheduledTimerWithTimeInterval:0.1
          target:[NSBlockOperation blockOperationWithBlock:^
          {
            //After 0.1 seconds, open URL in new tab
            [browserController loadURLInNewWindow:arg1.URL inBackground:NO];
          }]
          selector:@selector(main)
          userInfo:nil
          repeats:NO
          ];
      }];

      [options insertObject:openInOppositeModeAction atIndex:2];
    }

    if(preferenceManager.openInNewTabOptionEnabled &&
      (arg1.type == 120259084288 || arg1.type == 0))
    {
      //Long pressed element is link -> Check for tabBar

      //Get browserController
      BrowserController* browserController =
        MSHookIvar<BrowserController*>(castedSelf, "_browserController");

      if(!browserController.tabController.usesTabBar)
      {
        //tabBar is not active -> Create in new tab option to alert
        _WKElementAction* openInNewTabAction = [%c(_WKElementAction)
          elementActionWithTitle:[localizationManager
          localizedMSStringForKey:@"Open Link in New Tab"] actionHandler:
        ^{
          //Open URL in new tab
          [browserController loadURLInNewWindow:arg1.URL inBackground:NO];
        }];

        //Add option to alert
        [options insertObject:openInNewTabAction atIndex:1];
      }
    }

    if(preferenceManager.enhancedDownloadsEnabled)
    {
      //EnhancedDownloads are enabled -> create 'Download to ...' option
      _WKElementAction* downloadToAction = [%c(_WKElementAction)
        elementActionWithTitle:[localizationManager
        localizedSPStringForKey:@"DOWNLOAD_TO"] actionHandler:^
      {
        switch(arg1.type)
        {
          case 0: //Link long pressed (Just making sure not to break it on some devices?)
          case 120259084288: //I'm not really sure why these are the numbers on iOS9
          {
            //Create download request from URL
            NSURLRequest* downloadRequest = [NSURLRequest requestWithURL:arg1.URL];

            //Create downloadInfo
            SPDownloadInfo* downloadInfo = [[SPDownloadInfo alloc]
              initWithRequest:downloadRequest];

            //Set filename
            downloadInfo.filename = @"site.html";
            downloadInfo.customPath = YES;

            //Call downloadManager
            [[SPDownloadManager sharedInstance]
              configureDownloadWithInfo:downloadInfo];
            break;
          }
          case 1: //Image long pressed
          case 120259084289:
          {
            //Create downloadInfo
            SPDownloadInfo* downloadInfo = [[SPDownloadInfo alloc]
              initWithImage:arg1.image];

            downloadInfo.filename = @"image.png";
            downloadInfo.customPath = YES;

            //Call SPDownloadManager with image
            [[SPDownloadManager sharedInstance]
              configureDownloadWithInfo:downloadInfo];
            break;
          }
          default:
          break;
        }
      }];

      switch(arg1.type)
      {
        case 0: //Link long pressed
        case 120259084288:
        {
          //Add option to alert before share option
          [options insertObject:downloadToAction atIndex:[options count] - 1];
          break;
        }
        case 1: //Image long pressed
        case 120259084289:
        {
          //Add option to alert
          [options addObject:downloadToAction];
          break;
        }
        default:
        break;
      }
    }

    return options;
  }

  return %orig;
}

%end
%end

%group iOS9Up
%hook TabDocument

//desktop mode + ForceHTTPS
- (id)_loadURLInternal:(NSURL*)arg1 userDriven:(BOOL)arg2
{
  if((preferenceManager.forceHTTPSEnabled ||
    preferenceManager.desktopButtonEnabled) && arg1)
  {
    return %orig([castedSelf URLHandler:arg1], arg2);
  }
  return %orig;
}

- (id)loadURL:(NSURL*)arg1 fromBookmark:(id)arg2
{
  if((preferenceManager.forceHTTPSEnabled ||
    preferenceManager.desktopButtonEnabled) && arg1)
  {
    return %orig([castedSelf URLHandler:arg1], arg2);
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

    if(preferenceManager.desktopButtonEnabled && desktopButtonSelected)
    {
      //desktop button is selected -> change user agent to desktop agent
      [self setCustomUserAgent:desktopUserAgent];
    }
    else if(preferenceManager.desktopButtonEnabled && !desktopButtonSelected)
    {
      //desktop button is selected -> change user agent to mobile agent
      [self setCustomUserAgent:@""];
    }

    return %orig(newURL);
  }
  return %orig;
}

%end
%end

%group iOS8
%hook TabDocument

//Extra 'Open in new Tab' option + 'Download to option'
- (NSMutableArray*)actionsForElement:(_WKActivatedElementInfo*)arg1
  defaultActions:(NSArray*)arg2
{
  if(preferenceManager.enhancedDownloadsEnabled ||
    preferenceManager.openInNewTabOptionEnabled ||
    preferenceManager.openInOppositeModeOptionEnabled)
  {
    NSMutableArray* options = %orig;

    if(preferenceManager.openInOppositeModeOptionEnabled &&
      (arg1.type == 120259084288 || arg1.type == 0))
    {
      //Create variable for title
      NSString* title;

      //Get browserController
      BrowserController* browserController =
        MSHookIvar<BrowserController*>(castedSelf, "_browserController");

      //Get title based on browsing mode
      if(browserController.privateBrowsingEnabled)
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
        [browserController togglePrivateBrowsing];

        [NSTimer scheduledTimerWithTimeInterval:0.1
          target:[NSBlockOperation blockOperationWithBlock:^
          {
            //After 0.1 seconds, open URL in new tab
            [browserController loadURLInNewWindow:arg1.URL inBackground:NO];
          }]
          selector:@selector(main)
          userInfo:nil
          repeats:NO
          ];
      }];

      [options insertObject:openInOppositeModeAction atIndex:2];
    }

    if(preferenceManager.openInNewTabOptionEnabled &&
      (arg1.type == 120259084288 || arg1.type == 0))
    {
      //Long pressed element is link -> Check for tabBar

      //Get browserController
      BrowserController* browserController =
        MSHookIvar<BrowserController*>(castedSelf, "_browserController");

      if(!browserController.tabController.usesTabBar)
      {
        //tabBar is not active -> Create in new tab option to alert
        _WKElementAction* openInNewTabAction = [%c(_WKElementAction)
          elementActionWithTitle:[localizationManager
          localizedMSStringForKey:@"Open Link in New Tab"] actionHandler:
        ^{
          //Open URL in new tab
          [browserController loadURLInNewWindow:arg1.URL inBackground:NO];
        }];

        //Add option to alert
        [options insertObject:openInNewTabAction atIndex:1];
      }
    }

    if(preferenceManager.enhancedDownloadsEnabled)
    {
      //EnhancedDownloads are enabled -> create 'Download to ...' option
      _WKElementAction* downloadToAction = [%c(_WKElementAction)
        elementActionWithTitle:[localizationManager
        localizedSPStringForKey:@"DOWNLOAD_TO"] actionHandler:^
      {
        switch(arg1.type)
        {
          case 0: //Link long pressed (Just making sure not to break it on some devices?)
          case 120259084288: //I'm not really sure why these are the numbers on iOS9
          {
            //Create download request from URL
            NSURLRequest* downloadRequest = [NSURLRequest requestWithURL:arg1.URL];

            //Create downloadInfo
            SPDownloadInfo* downloadInfo = [[SPDownloadInfo alloc]
              initWithRequest:downloadRequest];

            //Set filename
            downloadInfo.filename = @"site.html";
            downloadInfo.customPath = YES;

            //Call downloadManager
            [[SPDownloadManager sharedInstance]
              configureDownloadWithInfo:downloadInfo];
            break;
          }
          case 1: //Image long pressed
          case 120259084289:
          {
            //Create downloadInfo
            SPDownloadInfo* downloadInfo = [[SPDownloadInfo alloc]
              initWithImage:arg1.image];

            downloadInfo.filename = @"image.png";
            downloadInfo.customPath = YES;

            //Call SPDownloadManager with image
            [[SPDownloadManager sharedInstance]
              configureDownloadWithInfo:downloadInfo];
            break;
          }
          default:
          break;
        }
      }];

      switch(arg1.type)
      {
        case 0: //Link long pressed
        case 120259084288:
        {
          //Add option to alert before share option
          [options insertObject:downloadToAction atIndex:[options count] - 1];
          break;
        }
        case 1: //Image long pressed
        case 120259084289:
        {
          //Add option to alert
          [options addObject:downloadToAction];
          break;
        }
        default:
        break;
      }
    }

    return options;
  }

  return %orig;
}

- (void)loadURL:(id)arg1 userDriven:(BOOL)arg2
{
  if((preferenceManager.forceHTTPSEnabled ||
    preferenceManager.desktopButtonEnabled) && arg1)
  {
    NSURL* newURL = [castedSelf URLHandler:arg1];
    %orig(newURL, arg2);
    return;
  }

  %orig;
}

- (void)loadURL:(NSURL*)arg1 fromBookmark:(id)arg2
{
  if((preferenceManager.forceHTTPSEnabled ||
    preferenceManager.desktopButtonEnabled) && arg1)
  {
    NSURL* newURL = [castedSelf URLHandler:arg1];
    %orig(newURL, arg2);
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

    if(preferenceManager.desktopButtonEnabled && desktopButtonSelected)
    {
      //desktop button is selected -> change user agent to desktop agent
      [self setCustomUserAgent:desktopUserAgent];
    }
    else if(preferenceManager.desktopButtonEnabled && !desktopButtonSelected)
    {
      //desktop button is selected -> change user agent to mobile agent
      [self setCustomUserAgent:@""];
    }

    return %orig(newURL);
  }
  return %orig;
}

%end
%end

%group all
%hook TabDocument

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
      //Get array of components that are seperated by a #
      NSArray* oldComponents = [[castedSelf URL].absoluteString
        componentsSeparatedByString:@"#"];

      //Strip fragment
      NSString* oldURLWithoutFragment = oldComponents.firstObject;

      //Get array of components that are seperated by a #
      NSArray* newComponents = [navigationAction.request.URL.absoluteString
        componentsSeparatedByString:@"#"];

      //Strip fragment
      NSString* newURLWithoutFragment = newComponents.firstObject;

      if(![newURLWithoutFragment isEqualToString:oldURLWithoutFragment])
      {
        //Link doesn't contain current URL -> Open in new tab

        //Cancel site load
        decisionHandler(WKNavigationResponsePolicyCancel);
        switch(iOSVersion)
        {
          case 8:
          case 9:
          //Load URL in new tab
          [MSHookIvar<BrowserController*>(castedSelf, "_browserController")
            loadURLInNewWindow:navigationAction.request.URL
            inBackground:NO animated:YES];
          break;

          case 10:
          //Load URL in new tab
          [castedSelf.browserController loadURLInNewTab:navigationAction.request.URL
            inBackground:NO animated:YES];
          break;
        }
        return;
      }
    }
  }

  %orig;
}

//Present download menu if clicked link is a downloadable file
- (void)webView:(WKWebView *)webView
  decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse
  decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
  if(preferenceManager.enhancedDownloadsEnabled)
  {
    //Get MIMEType
    NSString* MIMEType = navigationResponse.response.MIMEType;

    //Check if MIMEType indicates that link is download
    if(showAlert && (!navigationResponse.canShowMIMEType ||
      [MIMEType rangeOfString:@"video/"].location != NSNotFound ||
      [MIMEType rangeOfString:@"audio/"].location != NSNotFound ||
      [MIMEType isEqualToString:@"application/pdf"]))
    {
      //Cancel loading
      decisionHandler(WKNavigationResponsePolicyCancel);

      //Fix for some sites (eg dropbox), credits to https://stackoverflow.com/a/34740466
      NSHTTPURLResponse *response = (NSHTTPURLResponse *)navigationResponse.response;
      NSArray *cookies =[NSHTTPCookie cookiesWithResponseHeaderFields:[response allHeaderFields] forURL:response.URL];
      for(NSHTTPCookie *cookie in cookies)
      {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
      }

      SPDownloadInfo* downloadInfo = [[SPDownloadInfo alloc] initWithRequest:navigationResponse._request];
      downloadInfo.filesize = navigationResponse.response.expectedContentLength;
      downloadInfo.filename = navigationResponse.response.suggestedFilename;
      downloadInfo.sourceDocument = self;

      [[SPDownloadManager sharedInstance] presentDownloadAlertWithDownloadInfo:downloadInfo];
    }
    else
    {
      showAlert = YES;
      %orig;
    }
  }
  else
  {
    %orig;
  }
}

//NOTE: Not sure if hooking this method is needed
/*- (id)_initWithTitle:(id)arg1 URL:(NSURL*)arg2 UUID:(id)arg3
  privateBrowsingEnabled:(BOOL)arg4 bookmark:(id)arg5
  browserController:(id)arg6 createDocumentView:(id)arg7
{
  if((preferenceManager.forceHTTPSEnabled ||
    preferenceManager.desktopButtonEnabled) && arg2)
  {
    return %orig(arg1, [castedSelf URLHandler:arg2], arg3, arg4, arg5, arg6, arg7);
  }
  return %orig;
}*/

- (void)_loadStartedDuringSimulatedClickForURL:(NSURL*)arg1
{
  if((preferenceManager.forceHTTPSEnabled ||
    preferenceManager.desktopButtonEnabled) && arg1)
  {
    NSURL* newURL = [castedSelf URLHandler:arg1];
    if(![[newURL absoluteString] isEqualToString:[arg1 absoluteString]])
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
  if(preferenceManager.forceHTTPSEnabled || preferenceManager.desktopButtonEnabled)
  {
    NSURL* currentURL = [castedSelf URL];
    if(currentURL)
    {
      NSURL* tmpURL = [castedSelf URLHandler:currentURL];
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

//Convert http url into https url and change user agent if needed
%new
- (NSURL*)URLHandler:(NSURL*)URL
{
  //Get URL components
  NSURLComponents* URLComponents = [NSURLComponents componentsWithURL:URL
    resolvingAgainstBaseURL:NO];

  if(preferenceManager.forceHTTPSEnabled && [URL.scheme isEqualToString:@"http"] &&
    [castedSelf shouldRequestHTTPS:URL])
  {
    //ForceHTTPS enabled & current scheme is http & no exception for current URL
    //-> change scheme to https
    URLComponents.scheme = @"https";
  }

  if(preferenceManager.desktopButtonEnabled && desktopButtonSelected)
  {
    //desktop button is selected -> change user agent to desktop agent
    [castedSelf setCustomUserAgent:desktopUserAgent];
  }
  else if(preferenceManager.desktopButtonEnabled && !desktopButtonSelected)
  {
    //desktop button is selected -> change user agent to mobile agent
    [castedSelf setCustomUserAgent:@""];
  }

  return URLComponents.URL;
}

//Checks through exceptions whether https should be forced or not
%new
- (BOOL)shouldRequestHTTPS:(NSURL*)URL
{
  //Reload dictionary
  loadOtherPlist();

  //Get https exception array from dictionary
  NSMutableArray* ForceHTTPSExceptions = [otherPlist objectForKey:@"ForceHTTPSExceptions"];

  for(NSString* exception in ForceHTTPSExceptions)
  {
    if([[URL host] rangeOfString:exception].location != NSNotFound)
    {
      //Array contains host -> return false
      return false;
    }
  }
  //Array doesn't contain host -> return false
  return true;
}

%end
%end

%ctor
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
    %init(iOS10, TabDocument=TabDocumentClass);
  }
  else if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0)
  {
    %init(iOS9, TabDocument=TabDocumentClass);
  }

  %init(all, TabDocument=TabDocumentClass);
}
