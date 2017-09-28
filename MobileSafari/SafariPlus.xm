// SafariPlus.xm
// (c) 2017 opa334


#import "SafariPlus.h"

/****** Variables ******/

int iOSVersion;
BOOL desktopButtonSelected;

NSBundle* MSBundle = [NSBundle mainBundle];
NSBundle* SPBundle = [NSBundle bundleWithPath:SPBundlePath];

NSMutableDictionary* otherPlist;

SPPreferenceManager* preferenceManager = [SPPreferenceManager sharedInstance];
SPLocalizationManager* localizationManager = [SPLocalizationManager sharedInstance];

/****** Extensions ******/

//https://stackoverflow.com/a/22669888
@implementation UIImage (ColorInverse)

+ (UIImage *)inverseColor:(UIImage *)image
{
    CIImage *coreImage = [CIImage imageWithCGImage:image.CGImage];
    CIFilter *filter = [CIFilter filterWithName:@"CIColorInvert"];
    [filter setValue:coreImage forKey:kCIInputImageKey];
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    return [UIImage imageWithCIImage:result scale:image.scale orientation:image.imageOrientation];
}

@end

/****** Useful functions ******/

//Return current browsing status
BOOL privateBrowsingEnabled()
{
  BOOL privateBrowsingEnabled;

  switch(iOSVersion)
  {
    case 9:
    privateBrowsingEnabled = MSHookIvar<BrowserController*>
      ((Application*)[%c(Application) sharedApplication],
      "_controller").privateBrowsingEnabled;
    break;

    case 10:
    privateBrowsingEnabled = [((Application*)[%c(Application)
      sharedApplication]).shortcutController.browserController
      privateBrowsingEnabled];
    break;
  }

  return privateBrowsingEnabled;
}

SafariWebView* activeWebView()
{
  SafariWebView* activeWebView;
  switch(iOSVersion)
  {
    case 9:
    activeWebView = MSHookIvar<BrowserController*>
      ((Application*)[%c(Application) sharedApplication],
      "_controller").tabController.activeTabDocument.webView;
    break;

    case 10:
    activeWebView = ((Application*)[%c(Application) sharedApplication]).
      shortcutController.browserController.tabController.
      activeTabDocument.webView;
    break;
  }
  return activeWebView;
}

void loadOtherPlist()
{
  otherPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:otherPlistPath];
  if(!otherPlist)
  {
    otherPlist = [NSMutableDictionary new];
    saveOtherPlist();
  }
}

void saveOtherPlist()
{
  [otherPlist writeToFile:otherPlistPath atomically:YES];
}

/****** Version detection ******/

%ctor
{
  if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0)
  {
    iOSVersion = 11;
  }
  else if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0)
  {
    iOSVersion = 10;
  }
  else if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0)
  {
    iOSVersion = 9;
  }
}
