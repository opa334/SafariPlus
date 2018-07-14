// SafariPlus.xm
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

#import "SafariPlus.h"

#import "Shared.h"
#import "Defines.h"
#import "Classes/SPFileManager.h"
#import "Classes/SPPreferenceManager.h"
#import "Classes/SPLocalizationManager.h"
#import "Classes/SPCommunicationManager.h"
#import "Classes/SPCacheManager.h"

#import <sys/utsname.h>

/****** Variables ******/

CGFloat iOSVersion;
BOOL iPhoneX;

NSBundle* MSBundle = [NSBundle mainBundle];
NSBundle* SPBundle = [NSBundle bundleWithPath:SPBundlePath];

SPFileManager* fileManager = [SPFileManager sharedInstance];
SPPreferenceManager* preferenceManager = [SPPreferenceManager sharedInstance];
SPLocalizationManager* localizationManager = [SPLocalizationManager sharedInstance];
SPDownloadManager* downloadManager;
SPCommunicationManager* communicationManager = [SPCommunicationManager sharedInstance];
SPCacheManager* cacheManager = [SPCacheManager sharedInstance];

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

@implementation NSURL (HTTPtoHTTPS)

//Convert http url into https url
- (NSURL*)httpsURL
{
  //Get URL components
  NSURLComponents* URLComponents = [NSURLComponents componentsWithURL:self
    resolvingAgainstBaseURL:NO];

  if([self.scheme isEqualToString:@"http"])
  {
    //Change scheme to https
    URLComponents.scheme = @"https";
  }

  return URLComponents.URL;
}

@end

@implementation NSString (Strip)
- (NSString*)stringStrippedByStrings:(NSArray<NSString*>*)strings
{
  NSString* strippedString = self;
  NSArray* tmpArray;

  for(NSString* string in strings)
  {
    tmpArray = [strippedString componentsSeparatedByString:string];
    strippedString = tmpArray.firstObject;
  }

  return strippedString;
}
@end

/****** Useful functions ******/

//Return current browsing status
BOOL privateBrowsingEnabled(BrowserController* controller)
{
  BOOL privateBrowsingEnabled;

  if(iOSVersion >= 10.3)
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
  if(iOSVersion >= 10.3)
  {
    [controller togglePrivateBrowsingEnabled];
  }
  else
  {
    [controller togglePrivateBrowsing];
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

  if(iOSVersion >= 10)
  {
    browserControllers = ((Application*)[UIApplication sharedApplication]).browserControllers;
  }
  else //8,9
  {
    browserControllers = @[MSHookIvar<BrowserController*>((Application*)[%c(Application) sharedApplication],"_controller")];
  }

  return browserControllers;
}

//Get browserController from tabDocument
BrowserController* browserControllerForTabDocument(TabDocument* document)
{
  BrowserController* browserController;

  if(iOSVersion >= 10)
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

  if(iOSVersion >= 10)
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

/****** Version and device detection ******/

%ctor
{
  if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_3)
  {
    iOSVersion = 11.3;
  }
  else if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0)
  {
    iOSVersion = 11;
  }
  else if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_3)
  {
    iOSVersion = 10.3;
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

  //Detection of iPhone X (Needs special treatment in some cases)
  #ifdef SIMJECT
  NSString* model = NSProcessInfo.processInfo.environment[@"SIMULATOR_MODEL_IDENTIFIER"];
  #else
  struct utsname systemInfo;
  uname(&systemInfo);
  NSString* model = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
  #endif
  iPhoneX = [model isEqualToString:@"iPhone10,3"] || [model isEqualToString:@"iPhone10,6"];
}
