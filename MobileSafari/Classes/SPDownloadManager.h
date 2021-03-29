// Copyright (c) 2017-2021 Lars Fröder

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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

@property (nonatomic) NSHashTable<NSObject<DownloadsObserverDelegate>*>* observerDelegates;

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

- (void)sendNotificationWithTitle:(NSString*)title message:(NSString*)message window:(UIWindow*)window;

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
- (void)presentDirectoryNotExistsAlertWithDownloadInfo:(SPDownloadInfo*)downloadInfo;
- (void)presentNotEnoughSpaceAlertWithDownloadInfo:(SPDownloadInfo*)downloadInfo;
- (void)presentWebContentErrorWithDownloadInfo:(SPDownloadInfo*)downloadInfo;
- (void)pathSelectionResponseWithDownloadInfo:(SPDownloadInfo*)downloadInfo;

- (void)handleFinishedTask:(__kindof NSURLSessionTask*)task location:(NSURL *)location;

- (NSString*)fileTypeOfMovpkgAtURL:(NSURL*)movpkgURL;
- (void)mergeMovpkgAtURL:(NSURL*)movpkgURL toFileAtURL:(NSURL*)fileURL;
- (void)mergeSegmentsAtURL:(NSURL*)segmentURL toFileAtURL:(NSURL*)fileURL;
@end
