@class SPDownload;

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
//- (void)downloadFinished:(SPDownload*)download withLocation:(NSURL*)location;
//- (void)downloadCancelled:(SPDownload*)download;
- (NSURLSession*)sharedDownloadSession;
- (void)saveDownloadsToDisk;
@end

@protocol CellDownloadDelegate
@required
- (void)setPaused:(BOOL)paused;
- (void)cancelDownload;
- (void)setCellDelegate:(id<DownloadCellDelegate>)cellDelegate;
@end
