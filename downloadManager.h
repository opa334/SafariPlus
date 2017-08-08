//  downloadManager.h
// (c) 2017 opa334

#import "Download.h"
#import "directoryPickerNavigationController.h"
#import "SPLocalizationManager.h"
#import "SPPreferenceManager.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <RocketBootstrap/rocketbootstrap.h>

@class downloadManager;

@interface downloadManager : NSObject <DownloadManagerDelegate> {}
@property (nonatomic, weak) id<RootControllerDownloadDelegate> rootControllerDelegate;
@property (nonatomic, weak) id<DownloadTableDelegate> downloadTableDelegate;
@property (nonatomic, strong) CPDistributedMessagingCenter* SPMessagingCenter;
@property NSMutableArray* downloads;
+ (instancetype)sharedInstance;
- (NSMutableArray*)getDownloadsForPath:(NSURL*)path;
- (void)removeDownloadWithIdentifier:(NSString*)identifier;
- (NSString*)generateIdentifier;
- (void)presentFileExistsAlert:(NSURLRequest*)request size:(int64_t)size fileName:(NSString*)fileName path:(NSURL*)path;
- (void)presentFileExistsAlert:(NSURLRequest*)request size:(int64_t)size fileName:(NSString*)fileName path:(NSURL*)path isImage:(BOOL)isImage;
- (void)handleDirectoryPickerImageResponse:(UIImage*)image fileName:(NSString*)fileName path:(NSURL*)path;
- (void)saveImage:(UIImage*)image fileName:(NSString*)fileName path:(NSURL*)path shouldReplace:(BOOL)shouldReplace;
- (void)prepareDownloadFromRequest:(NSURLRequest*)request withSize:(int64_t)size fileName:(NSString*)fileName;
- (void)prepareDownloadFromRequest:(NSURLRequest*)request withSize:(int64_t)size fileName:(NSString*)fileName customPath:(BOOL)customPath;
- (void)prepareImageDownload:(UIImage*)image fileName:(NSString*)fileName;
- (void)startDownloadFromRequest:(NSURLRequest*)request size:(int64_t)size fileName:(NSString*)fileName path:(NSURL*)path shouldReplace:(BOOL)shouldReplace;
- (void)handleDirectoryPickerResponse:(NSURLRequest*)request size:(int64_t)size fileName:(NSString*)fileName path:(NSURL*)path;
@end
