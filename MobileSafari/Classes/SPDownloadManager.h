//  SPDownloadManager.h
// (c) 2017 opa334

#import "SPDownload.h"
#import "SPDownloadInfo.h"
#import "SPDirectoryPickerNavigationController.h"
#import "SPLocalizationManager.h"
#import "SPPreferenceManager.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import <WebKit/WKWebView.h>
#ifndef SIMJECT
#import <RocketBootstrap/rocketbootstrap.h>
#endif
#import "../Defines.h"
#import "../Shared.h"

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
- (void)resumeDownloadsFromDiskLoad;

- (void)loadDownloadsFromDisk;
- (void)saveDownloadsToDisk;

- (void)sendNotificationWithText:(NSString*)text;

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
- (void)pathSelectionResponseWithDownloadInfo:(SPDownloadInfo*)downloadInfo;
@end
