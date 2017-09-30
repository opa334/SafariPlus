// TabDocumentWK.xm
// (c) 2017 opa334

#import "../SafariPlus.h"

//NOTE: This class is only used by iOS 8

%group iOS8

%hook TabDocumentWK2

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
        MSHookIvar<BrowserController*>(self, "_browserController");

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
        MSHookIvar<BrowserController*>(self, "_browserController");

      if(browserController.tabController.usesTabBar)
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
      NSArray* oldComponents = [[self URL].absoluteString
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

        //Load URL in new tab
        [MSHookIvar<BrowserController*>(self, "_browserController")
          loadURLInNewWindow:navigationAction.request.URL
          inBackground:NO animated:YES];
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

%end

%end

%ctor
{
  if(kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_9_0)
  {
    %init(iOS8);
  }
}
