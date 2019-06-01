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

@class CPDistributedMessagingCenter, SPStatusBarNotificationWindow, SPDownload;

@interface SPDownloadManager : NSObject <NSURLSessionDownloadDelegate, NSURLSessionDataDelegate, DownloadManagerDelegate, SPDirectoryPickerDelegate>
@property (nonatomic) NSMutableArray<SPDownload*>* pendingDownloads;
@property (nonatomic) NSMutableArray<SPDownload*>* finishedDownloads;
@property (nonatomic) SPStatusBarNotificationWindow* notificationWindow;
@property (nonatomic) NSURLSession* downloadSession;
@property (nonatomic) NSInteger errorCount;
@property (nonatomic) NSInteger processedErrorCount;
@property (nonatomic) NSURL* defaultDownloadURL;
@property (nonatomic) SPDownloadInfo* requestFetchDownloadInfo;
@property (nonatomic) SPDownloadInfo* pickerDownloadInfo;
@property (copy) void (^applicationBackgroundSessionCompletionHandler)();

@property (nonatomic, weak) id<DownloadNavigationControllerDelegate> navigationControllerDelegate;

+ (instancetype)sharedInstance;

- (void)setUpDefaultDownloadURL;
- (BOOL)createDownloadDirectoryIfNeeded;
- (void)migrateFromSandbox;

- (void)verifyDownloadStorageRevision;
- (void)configureSession;
- (void)clearTempFiles;
- (void)clearTempFilesIgnorePendingDownloads:(BOOL)ignorePendingDownloads;
- (void)cancelAllDownloads;
- (void)clearDownloadHistory;
- (void)resumeDownloadsFromDiskLoad;
- (void)forceCancelDownload:(SPDownload*)download;

- (void)downloadFinished:(SPDownload*)download;
- (void)removeDownloadFromHistory:(SPDownload*)download;
- (NSString*)pathForResumeData:(NSData*)resumeData;
- (void)removeTemporaryFileForResumeData:(NSData*)resumeData;

- (void)loadDownloadsFromDisk;
- (void)saveDownloadsToDisk;

- (void)sendNotificationWithText:(NSString*)text;

- (int64_t)freeDiscspace;
- (BOOL)enoughDiscspaceForDownloadInfo:(SPDownloadInfo*)downloadInfo;

- (void)closeDocumentIfObsoleteWithDownloadInfo:(SPDownloadInfo*)downloadInfo;

- (SPDownload*)downloadWithTaskIdentifier:(NSUInteger)identifier;
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
@end
