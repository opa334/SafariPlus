// SafariPlus.xm
// (c) 2017 opa334


#import "SafariPlus.h"

/****** Variables ******/

int iOSVersion;
BOOL desktopButtonSelected;

NSBundle* MSBundle = [NSBundle mainBundle];
NSBundle* SPBundle = [NSBundle bundleWithPath:SPBundlePath];

SPPreferenceManager* preferenceManager = [SPPreferenceManager sharedInstance];
SPLocalizationManager* localizationManager = [SPLocalizationManager sharedInstance];

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
