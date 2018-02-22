// SPDownloadManager.h
// (c) 2017 opa334

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

@class CPDistributedMessagingCenter, SPStatusBarNotificationWindow;

@interface SPDownloadManager : NSObject <NSURLSessionDownloadDelegate, DownloadManagerDelegate>
@property (nonatomic) NSMutableArray* pendingDownloads;
@property (nonatomic) CPDistributedMessagingCenter* messagingCenter;
@property (nonatomic) SPStatusBarNotificationWindow* notificationWindow;
@property (nonatomic) NSURLSession* downloadSession;
@property (nonatomic) NSInteger errorCount;
@property (nonatomic) NSInteger processedErrorCount;

@property (nonatomic, weak) id<DownloadNavigationControllerDelegate> navigationControllerDelegate;

+ (instancetype)sharedInstance;

- (void)configureSession;
- (void)checkDownloadStorageRevision;
- (void)removeDownloadStorageFile;
- (void)clearTempFiles;
- (void)cancelAllDownloads;
- (void)resumeDownloadsFromDiskLoad;
- (void)forceCancelDownload:(SPDownload*)download;

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
