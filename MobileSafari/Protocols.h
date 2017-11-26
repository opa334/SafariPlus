@class SPDownload, SPDownloadInfo;

@protocol filePickerDelegate<NSObject>
- (void)didSelectFilesAtURL:(NSArray*)URLArray;
@end

@protocol DownloadNavigationControllerDelegate
@required
- (void)reloadTopTableView;
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
- (NSURLSession*)sharedDownloadSession;
- (void)saveDownloadsToDisk;
- (BOOL)enoughDiscspaceForDownloadInfo:(SPDownloadInfo*)downloadInfo;
- (void)presentNotEnoughSpaceAlertWithDownloadInfo:(SPDownloadInfo*)downloadInfo;
@end

@protocol CellDownloadDelegate
@required
- (void)setPaused:(BOOL)paused;
- (void)cancelDownload;
- (void)setCellDelegate:(id<DownloadCellDelegate>)cellDelegate;
@end
