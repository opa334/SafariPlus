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

NSBundle* MSBundle = [NSBundle mainBundle];
NSBundle* SPBundle = [NSBundle bundleWithPath:SPBundlePath];

SPCommunicationManager* communicationManager = [SPCommunicationManager sharedInstance];
SPFileManager* fileManager = [SPFileManager sharedInstance];
SPPreferenceManager* preferenceManager = [SPPreferenceManager sharedInstance];
SPLocalizationManager* localizationManager = [SPLocalizationManager sharedInstance];
SPDownloadManager* downloadManager;
SPCacheManager* cacheManager = [SPCacheManager sharedInstance];

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

void intDlog(NSString* fString, ...)
{
  va_list va;
  va_start(va, fString);
  NSString* msg = [[NSString alloc] initWithFormat:fString arguments:va];
  va_end(va);

  [debugLogFileHandle writeData:[[msg stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
  NSLog(@"%@", msg);
}

void intDlogDownload(SPDownload* download, NSString* message)
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
  dlog(@"didFinish: %i", download.didFinish);
  dlog(@"wasCancelled: %i", download.wasCancelled);
  dlog(@"downloadManagerDelegate: %@", download.downloadManagerDelegate);
  dlog(@"browserCellDelegate: %@", download.browserCellDelegate);
  dlog(@"listCellDelegate: %@", download.listCellDelegate);
  dlog(@"----------");
}

void intDlogDownloadInfo(SPDownloadInfo* downloadInfo, NSString* message)
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

void intDlogDownloadManager()
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
  dlog(@"processedVideoDownloadInfo: %@", downloadManager.processedVideoDownloadInfo);
  [downloadManager.downloadSession getAllTasksWithCompletionHandler:^(NSArray<__kindof NSURLSessionTask *> *tasks)
  {
    dlog(@"tasks: %@", tasks);
  }];
  dlog(@"----------");
}

#endif

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

@implementation NSString (UUID)
- (BOOL)isUUID
{
  return (bool)[[NSUUID alloc] initWithUUIDString:self];
}
@end

@implementation UIView (Autolayout)
+ (id)autolayoutView
{
    UIView *view = [self new];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    return view;
}
@end

@implementation UITableViewController (FooterFix)
- (void)fixFooterColors
{
  for(int i = 0; i < [self numberOfSectionsInTableView:self.tableView]; i++)
  {
    UITableViewHeaderFooterView* footerView = [self.tableView headerViewForSection:i];
    footerView.backgroundView.backgroundColor = [UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:1];
  }
}
@end

/****** Useful functions ******/

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
    privateBrowsingEnabled = controller.privateBrowsingEnabled;
  }

  return privateBrowsingEnabled;
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
  else //8,9
  {
    browserControllers = @[MSHookIvar<BrowserController*>(sharedApplication,"_controller")];
  }

  return browserControllers;
}

//Get browserController from tabDocument
BrowserController* browserControllerForTabDocument(TabDocument* document)
{
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

//Only add object to dict if it's not nil
void addToDict(NSMutableDictionary* dict, NSObject* object, NSString* key)
{
  if(object)
  {
    [dict setObject:object forKey:key];
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

  [rootViewControllerForBrowserController(browserControllers().firstObject) presentViewController:alert animated:YES completion:nil];
}

/****** One constructor that inits all hooks ******/

extern void initApplication();
extern void initAVFullScreenPlaybackControlsViewController();
extern void initAVPlaybackControlsView();
extern void initBrowserController();
extern void initColors();
extern void initTabDocument();
extern void initWKFileUploadPanel();

%ctor
{
  #ifdef DEBUG_LOGGING
  initDebug();
  #endif

  initApplication();
  initAVFullScreenPlaybackControlsViewController();
  initAVPlaybackControlsView();
  initBrowserController();
  initColors();
  initTabDocument();
  initWKFileUploadPanel();
}
