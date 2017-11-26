//  SPDownloadManager.h
// (c) 2017 opa334

#import "../Protocols.h"

@class CPDistributedMessagingCenter;

@interface SPDownloadManager : NSObject <NSURLSessionDownloadDelegate, DownloadManagerDelegate>
@property (nonatomic) NSMutableArray* pendingDownloads;
@property (nonatomic) CPDistributedMessagingCenter* SPMessagingCenter;
@property (nonatomic) NSURLSession* downloadSession;
@property (nonatomic) NSInteger errorCount;
@property (nonatomic) NSInteger processedErrorCount;

@property (nonatomic, weak) id<RootControllerDownloadDelegate> rootControllerDelegate;
@property (nonatomic, weak) id<DownloadNavigationControllerDelegate> navigationControllerDelegate;

+ (instancetype)sharedInstance;

- (void)setUpSession;
- (void)checkDownloadStorageRevision;
- (void)removeDownloadStorageFile;
- (void)clearTempFiles;
- (void)cancelAllDownloads;
- (void)resumeDownloadsFromDiskLoad;

- (void)loadDownloadsFromDisk;
- (void)saveDownloadsToDisk;

- (void)sendNotificationWithText:(NSString*)text;

- (int64_t)freeDiscspace;
- (BOOL)enoughDiscspaceForDownloadInfo:(SPDownloadInfo*)downloadInfo;

- (void)closeDocumentIfObsoleteWithDownloadInfo:(SPDownloadInfo*)downloadInfo;

- (SPDownload*)downloadWithTaskIdentifier:(NSUInteger)identifier;
- (NSMutableArray*)downloadsAtURL:(NSURL*)URL;
- (BOOL)downloadExistsAtURL:(NSURL*)URL;

- (void)configureDownloadWithInfo:(SPDownloadInfo*)downloadInfo;
- (void)startDownloadWithInfo:(SPDownloadInfo*)downloadInfo;
- (void)saveImageWithInfo:(SPDownloadInfo*)downloadInfo;

- (void)presentViewController:(UIViewController*)viewController withDownloadInfo:(SPDownloadInfo*)downloadInfo;
- (void)presentDownloadAlertWithDownloadInfo:(SPDownloadInfo*)downloadInfo;
- (void)presentDirectoryPickerWithDownloadInfo:(SPDownloadInfo*)downloadInfo;
- (void)presentPinnedLocationsWithDownloadInfo:(SPDownloadInfo*)downloadInfo;
- (void)presentFileExistsAlertWithDownloadInfo:(SPDownloadInfo*)downloadInfo;
- (void)presentNotEnoughSpaceAlertWithDownloadInfo:(SPDownloadInfo*)downloadInfo;
- (void)pathSelectionResponseWithDownloadInfo:(SPDownloadInfo*)downloadInfo;
@end
