//  downloadManager.h
//  Headers for download manager

// (c) 2017 opa334

#import "directoryPicker.h"
#import "SafariPlusUtil.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <RocketBootstrap/rocketbootstrap.h>

@class Download, downloadManager;

@protocol DownloadCellDelegate
@required
- (void)updateProgress:(int64_t)currentBytes totalBytes:(int64_t)totalBytes bytesPerSecond:(int64_t)bytesPerSecond animated:(BOOL)animated;
@end

@protocol DownloadTableDelegate
@required
- (void)reloadDataAndDataSources;
@end

@protocol CellDownloadDelegate
@required
- (void)cancelDownload;
- (void)pauseDownload;
- (void)resumeDownload;
- (void)setCellDelegate:(id<DownloadCellDelegate>)cellDelegate;
@end

@protocol RootControllerDownloadDelegate
@required
- (void)dispatchNotificationWithText:(NSString*)text;
- (void)dismissNotificationWithCompletion:(void (^)(void))completion;
- (void)presentViewController:(id)viewController;
@end

@protocol DownloadManagerDelegate
@required
- (void)downloadFinished:(Download*)download withLocation:(NSURL*)location;
- (void)downloadCancelled:(Download*)download;
@end

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
- (void)prepareDownloadFromRequest:(NSURLRequest*)request withSize:(int64_t)size fileName:(NSString*)fileName;
- (void)prepareDownloadFromRequest:(NSURLRequest*)request withSize:(int64_t)size fileName:(NSString*)fileName customPath:(BOOL)customPath;
- (void)startDownloadFromRequest:(NSURLRequest*)request size:(int64_t)size fileName:(NSString*)fileName path:(NSURL*)path shouldReplace:(BOOL)shouldReplace;
- (void)handleDirectoryPickerResponse:(NSURLRequest*)request size:(int64_t)size fileName:(NSString*)fileName path:(NSURL*)path;
@end

@interface Download : NSObject <NSURLSessionDownloadDelegate, NSURLSessionDelegate, CellDownloadDelegate> {}
@property (nonatomic, strong) NSURLSession* session;
@property (nonatomic, strong) NSURLSessionDownloadTask* downloadTask;
@property (nonatomic, weak) id<DownloadManagerDelegate> downloadManagerDelegate;
@property (nonatomic, weak) id<DownloadCellDelegate> cellDelegate;
@property (nonatomic) BOOL paused;
@property (nonatomic) NSInteger updateCount;
@property (nonatomic) NSTimeInterval startTime;
@property (nonatomic) int64_t startBytes;
@property (nonatomic) int64_t totalBytesWritten;
@property (nonatomic) NSString* fileName;
@property (nonatomic) int64_t fileSize;
@property (nonatomic) NSURL* filePath;
@property (nonatomic) BOOL replaceFile;
@property (nonatomic) NSString* identifier;
- (void)cancelDownload;
- (void)pauseDownload;
- (void)resumeDownload;
- (void)startDownloadFromRequest:(NSURLRequest*)request;
@end
