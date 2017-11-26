// SafariPlus.xm
// (c) 2017 opa334

#import "SafariPlus.h"

#import "Shared.h"
#import "Defines.h"
#import "Classes/SPPreferenceManager.h"
#import "Classes/SPLocalizationManager.h"

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

  if(iOSVersion >= 11)
  {
    privateBrowsingEnabled = [mainBrowserController() isPrivateBrowsingEnabled];
  }
  else
  {
    privateBrowsingEnabled = mainBrowserController().privateBrowsingEnabled;
  }

  return privateBrowsingEnabled;
}

void togglePrivateBrowsing()
{
  if(iOSVersion >= 11)
  {
    [mainBrowserController() togglePrivateBrowsingEnabled];
  }
  else
  {
    [mainBrowserController() togglePrivateBrowsing];
  }
}

SafariWebView* activeWebView()
{
  return mainBrowserController().tabController.activeTabDocument.webView;
}

BrowserController* mainBrowserController()
{
  BrowserController* controller;
  switch(iOSVersion)
  {
    case 8:
    case 9:
    controller = MSHookIvar<BrowserController*>
      ((Application*)[%c(Application) sharedApplication],
      "_controller");
    break;

    case 10:
    case 11:
    controller = ((Application*)[%c(Application) sharedApplication]).
      shortcutController.browserController;
    break;
  }
  return controller;
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
  else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0)
  {
    iOSVersion = 8;
  }
}
