//  SPDownload.h
// (c) 2017 opa334

#import "SPPreferenceManager.h"
#import "SPDownloadInfo.h"
#import "../Shared.h"
#import "Protocols.h"

@interface SPDownload : NSObject <CellDownloadDelegate>
{
  _Bool verifiedSize;
}
@property (nonatomic) SPDownloadInfo* orgInfo;
@property (nonatomic) NSURLRequest* request;
@property (nonatomic) UIImage* image;
@property (nonatomic) int64_t filesize;
@property (nonatomic) NSString* filename;
@property (nonatomic) NSURL* targetPath;
@property (nonatomic) BOOL paused;
@property (nonatomic) NSTimeInterval lastSpeedRefreshTime;
@property (nonatomic) NSTimer* speedTimer;
@property (nonatomic) int64_t startBytes;
@property (nonatomic) int64_t totalBytesWritten;
@property (nonatomic) int64_t bytesPerSecond;

@property (nonatomic) NSData* resumeData;
@property (nonatomic) NSUInteger taskIdentifier;
@property (nonatomic) NSURLSessionDownloadTask* downloadTask;

@property (nonatomic, weak) id<DownloadManagerDelegate> downloadManagerDelegate;
@property (nonatomic, weak) id<DownloadCellDelegate> cellDelegate;

- (instancetype)initWithDownloadInfo:(SPDownloadInfo*)downloadInfo;

- (void)startDownload;
- (void)startDownloadFromResumeData;
- (void)setPaused:(BOOL)paused;
- (void)cancelDownload;

- (void)setTimerEnabled:(BOOL)enabled;
- (void)updateDownloadSpeed;
- (void)updateProgress:(int64_t)totalBytesWritten totalFilesize:(int64_t)filesize;

- (int64_t)remainingBytes;
@end
