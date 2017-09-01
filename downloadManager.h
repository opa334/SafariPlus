//  downloadManager.h
// (c) 2017 opa334

#import "Download.h"
#import "directoryPickerNavigationController.h"
#import "SPLocalizationManager.h"
#import "SPPreferenceManager.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <RocketBootstrap/rocketbootstrap.h>

#define otherPlistPath @"/var/mobile/Library/Preferences/com.opa334.safariplusprefsOther.plist"
#define downloadsStorePath [NSHomeDirectory() stringByAppendingString:@"/Library/Safari/downloads"]

@class downloadManager;

@interface downloadManager : NSObject <DownloadManagerDelegate> {}
@property (nonatomic, weak) id<RootControllerDownloadDelegate> rootControllerDelegate;
@property (nonatomic, weak) id<DownloadTableDelegate> downloadTableDelegate;
@property (nonatomic, strong) CPDistributedMessagingCenter* SPMessagingCenter;
@property NSMutableArray* downloads;
+ (instancetype)sharedInstance;
- (void)loadDownloadsFromDisk;
- (void)saveDownloadsToDisk;
- (NSMutableArray*)getDownloadsForPath:(NSURL*)path;
- (void)removeDownloadWithIdentifier:(NSString*)identifier;
- (NSString*)generateIdentifier;
- (void)presentFileExistsAlert:(NSURLRequest*)request size:(int64_t)size fileName:(NSString*)fileName path:(NSURL*)path;
- (void)presentFileExistsAlert:(NSURLRequest*)request size:(int64_t)size fileName:(NSString*)fileName path:(NSURL*)path isImage:(BOOL)isImage image:(UIImage*)image;
- (void)handleDirectoryPickerImageResponse:(UIImage*)image fileName:(NSString*)fileName path:(NSURL*)path;
- (void)saveImage:(UIImage*)image fileName:(NSString*)fileName path:(NSURL*)path shouldReplace:(BOOL)shouldReplace;
- (void)prepareDownloadFromRequest:(NSURLRequest*)request withSize:(int64_t)size fileName:(NSString*)fileName;
- (void)prepareDownloadFromRequest:(NSURLRequest*)request withSize:(int64_t)size fileName:(NSString*)fileName customPath:(BOOL)customPath;
- (void)prepareImageDownload:(UIImage*)image fileName:(NSString*)fileName;
- (void)startDownloadFromRequest:(NSURLRequest*)request size:(int64_t)size fileName:(NSString*)fileName path:(NSURL*)path shouldReplace:(BOOL)shouldReplace;
- (void)handleDirectoryPickerResponse:(NSURLRequest*)request size:(int64_t)size fileName:(NSString*)fileName path:(NSURL*)path;
- (void)dispatchNotificationWithText:(NSString*)text;
@end
