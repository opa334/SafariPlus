//  SPDownload.h
// (c) 2017 opa334

#import "SPPreferenceManager.h"
#import "../Shared.h"

@class SPDownload;

@protocol DownloadTableDelegate
@required
- (void)reloadDataAndDataSources;
@end

@protocol DownloadCellDelegate
@required
- (void)updateDownloadSpeed:(int64_t)bytesPerSecond;
- (void)updateProgress:(int64_t)currentBytes totalBytes:(int64_t)totalBytes animated:(BOOL)animated;
@end

@protocol RootControllerDownloadDelegate
@required
- (void)dispatchNotificationWithText:(NSString*)text;
- (void)dismissNotificationWithCompletion:(void (^)(void))completion;
- (void)presentViewController:(id)viewController;
- (void)presentAlertControllerSheet:(UIAlertController*)alertController;
@end

@protocol DownloadManagerDelegate
@required
- (void)downloadFinished:(SPDownload*)download withLocation:(NSURL*)location;
- (void)downloadCancelled:(SPDownload*)download;
- (void)saveDownloadsToDisk;
@end

@protocol CellDownloadDelegate
@required
- (void)cancelDownload;
- (void)pauseDownload;
- (void)resumeDownload;
- (void)setCellDelegate:(id<DownloadCellDelegate>)cellDelegate;
@end

@interface SPDownload : NSObject <NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate, NSURLSessionDelegate, CellDownloadDelegate> {}
@property (nonatomic, strong) NSURLRequest* request;
@property (nonatomic, strong) NSURLSession* session;
@property (nonatomic, strong) NSURLSessionDownloadTask* downloadTask;
@property (nonatomic, weak) id<DownloadManagerDelegate> downloadManagerDelegate;
@property (nonatomic, weak) id<DownloadCellDelegate> cellDelegate;
@property (nonatomic) BOOL paused;
@property (nonatomic) BOOL resumedFromResumeData;
@property (nonatomic) BOOL shouldReplace;
@property (nonatomic) NSTimeInterval startTime;
@property (nonatomic) NSTimer* speedTimer;
@property (nonatomic) int64_t startBytes;
@property (nonatomic) int64_t totalBytesWritten;
@property (nonatomic) int64_t bytesPerSecond;
@property (nonatomic) NSString* fileName;
@property (nonatomic) int64_t fileSize;
@property (nonatomic) NSURL* filePath;
@property (nonatomic) NSString* identifier;
- (id)initWithRequest:(NSURLRequest*)request;
- (void)startDownload;
- (void)resumeFromDiskLoad;
- (void)cancelDownload;
- (void)pauseDownload;
- (void)resumeDownload;
- (void)setTimerEnabled:(BOOL)enabled;
- (void)updateDownloadSpeed;
@end
