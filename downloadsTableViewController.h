//  downloadsTableViewController.h
// (c) 2017 opa334

#import "fileBrowserTableViewController.h"
#import "fileTableViewCell.h"
#import "downloadManager.h"
#import "downloadTableViewCell.h"
#import "SPLocalizationManager.h"
@import AVFoundation;
@import AVKit;

@interface downloadsTableViewController : fileBrowserTableViewController <DownloadTableDelegate, UIDocumentInteractionControllerDelegate> {}
@property (nonatomic) NSMutableArray* downloadsAtCurrentPath;
@property (nonatomic, strong) UIDocumentInteractionController* documentController;
@property (nonatomic) NSURL* tmpSymlinkURL;
@property (nonatomic) BOOL didSelectOptionFromDocumentController;
- (id)newCellWithDownload:(Download*)download;
- (void)startPlayerWithMedia:(NSURL*)mediaURL;
@end
