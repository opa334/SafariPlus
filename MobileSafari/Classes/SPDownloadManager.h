// SPDownloadManager.h
// (c) 2017 - 2019 opa334

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

#import "../Protocols.h"

#import <AVFoundation/AVFoundation.h>

@class CPDistributedMessagingCenter, SPStatusBarNotificationWindow, SPDownload, AVAssetDownloadURLSession;

@interface SPDownloadManager : NSObject <NSURLSessionDownloadDelegate, NSURLSessionDataDelegate, DownloadManagerDelegate, SPDirectoryPickerDelegate, AVAssetDownloadDelegate>
@property (nonatomic) BOOL HLSSupported;
@property (nonatomic) BOOL isReconnectingDownloads;
@property (nonatomic) NSMutableArray<SPDownload*>* pendingDownloads;
@property (nonatomic) NSMutableArray<SPDownload*>* finishedDownloads;
@property (nonatomic) SPStatusBarNotificationWindow* notificationWindow;
@property (nonatomic) NSURLSession* fetchSession;
@property (nonatomic) NSURLSession* downloadSession;
@property (nonatomic) AVAssetDownloadURLSession* avDownloadSession;
@property (nonatomic) NSInteger errorCount;
@property (nonatomic) NSInteger processedErrorCount;
@property (nonatomic) NSURL* defaultDownloadURL;
@property (nonatomic) SPDownloadInfo* requestFetchDownloadInfo;
@property (nonatomic) SPDownloadInfo* pickerDownloadInfo;
@property (copy) void (^applicationBackgroundSessionCompletionHandler)();

@property (nonatomic, weak) id<DownloadNavigationControllerDelegate> navigationControllerDelegate;
@property (nonatomic) NSHashTable<id<DownloadsObserverDelegate> >* observerDelegates;

+ (instancetype)sharedInstance;

- (void)setUpDefaultDownloadURL;
- (BOOL)createDownloadDirectoryIfNeeded;
- (void)migrateFromSandbox;

- (NSURLSession*)sharedDownloadSession;
- (AVAssetDownloadURLSession*)sharedAVDownloadSession;

- (void)verifyDownloadStorageRevision;
- (void)configureSession;
- (void)reconnectDownloads;
- (void)reconnectHLSDownloads;
- (void)didFinishReconnectingDownloads;
- (void)didFinishReconnectingHLSDownloads;
- (void)clearTempFiles;
- (void)clearTempFilesIgnorePendingDownloads:(BOOL)ignorePendingDownloads;
- (void)cancelAllDownloads;
- (void)clearDownloadHistory;
- (void)forceCancelDownload:(SPDownload*)download;

- (void)downloadFinished:(SPDownload*)download;
- (void)downloadFailed:(SPDownload*)download withError:(NSError*)error;
- (void)moveDownloadFromPendingToHistory:(SPDownload*)download;
- (void)removeDownloadFromHistory:(SPDownload*)download;
- (NSString*)pathForResumeData:(NSData*)resumeData;
- (void)removeTemporaryFileForResumeData:(NSData*)resumeData;

- (void)loadDownloadsFromDisk;
- (void)saveDownloadsToDisk;

- (void)sendNotificationWithTitle:(NSString*)title message:(NSString*)message;

- (int64_t)freeDiscspace;
- (BOOL)enoughDiscspaceForDownloadInfo:(SPDownloadInfo*)downloadInfo;
- (float)progressOfAllRunningDownloads;
- (NSUInteger)runningDownloadsCount;

- (void)addObserverDelegate:(id<DownloadsObserverDelegate>)observerDelegate;
- (void)removeObserverDelegate:(id<DownloadsObserverDelegate>)observerDelegate;
- (void)totalProgressDidChange;
- (void)runningDownloadsCountDidChange;

- (void)closeDocumentIfObsoleteWithDownloadInfo:(SPDownloadInfo*)downloadInfo;

- (SPDownload*)downloadWithTask:(__kindof NSURLSessionTask*)task;
- (SPDownload*)downloadWithTaskIdentifier:(NSUInteger)identifier isHLS:(BOOL)isHLS;
- (NSMutableArray*)downloadsAtURL:(NSURL*)url;
- (BOOL)downloadExistsAtURL:(NSURL*)url;

- (void)configureDownloadWithInfo:(SPDownloadInfo*)downloadInfo;
- (void)startDownloadWithInfo:(SPDownloadInfo*)downloadInfo;
- (void)saveImageWithInfo:(SPDownloadInfo*)downloadInfo;
- (void)prepareVideoDownloadForDownloadInfo:(SPDownloadInfo*)downloadInfo;
- (void)prepareDownloadFromRequestForDownloadInfo:(SPDownloadInfo*)downloadInfo;

- (void)presentViewController:(UIViewController*)viewController withDownloadInfo:(SPDownloadInfo*)downloadInfo;
- (void)presentDownloadAlertWithDownloadInfo:(SPDownloadInfo*)downloadInfo;
- (void)presentDirectoryPickerWithDownloadInfo:(SPDownloadInfo*)downloadInfo;
- (void)presentPinnedLocationsWithDownloadInfo:(SPDownloadInfo*)downloadInfo;
- (void)presentFileExistsAlertWithDownloadInfo:(SPDownloadInfo*)downloadInfo;
- (void)presentNotEnoughSpaceAlertWithDownloadInfo:(SPDownloadInfo*)downloadInfo;
- (void)presentVideoURLNotFoundErrorWithDownloadInfo:(SPDownloadInfo*)downloadInfo;
- (void)pathSelectionResponseWithDownloadInfo:(SPDownloadInfo*)downloadInfo;

- (void)handleFinishedTask:(__kindof NSURLSessionTask*)task location:(NSURL *)location;
//- (void)mergeSegmentsAtURL:(NSURL*)segmentURL toFileAtURL:(NSURL*)fileURL;
@end
