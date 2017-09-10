//  SPDownloadsTableViewController.h
// (c) 2017 opa334

#import "SPFileBrowserTableViewController.h"
#import "SPFileTableViewCell.h"
#import "SPDownloadManager.h"
#import "SPDownloadTableViewCell.h"
#import "SPLocalizationManager.h"
#import "../Shared.h"
@import AVKit;
@import AVFoundation;

@interface UIApplication(iOS10)
- (void)openURL:(id)arg1 options:(id)arg2 completionHandler:(id)arg3;
@end

@interface SPDownloadsTableViewController : SPFileBrowserTableViewController <DownloadTableDelegate, UIDocumentInteractionControllerDelegate> {}
@property (nonatomic) NSMutableArray* downloadsAtCurrentPath;
@property (nonatomic, strong) UIDocumentInteractionController* documentController;
@property (nonatomic) NSURL* tmpSymlinkURL;
@property (nonatomic) BOOL didSelectOptionFromDocumentController;
- (id)newCellWithDownload:(SPDownload*)download;
- (void)startPlayerWithMedia:(NSURL*)mediaURL;
- (void)openScheme:(NSString *)scheme;
@end
