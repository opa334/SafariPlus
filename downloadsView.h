//  downloadsView.h
//  Headers for downloads view

// (c) 2017 opa334

#import "fileBrowser.h"
#import "downloadManager.h"
#import <MobileCoreServices/MobileCoreServices.h>
@import AVFoundation;
@import AVKit;

@class filePickerNavigationController;

@interface downloadsNavigationController : fileBrowserNavigationController {}
@end

@interface downloadsTableViewController : fileBrowserTableViewController <DownloadTableDelegate, UIDocumentInteractionControllerDelegate> {}
@property (nonatomic) NSMutableArray* downloadsAtCurrentPath;
@property (nonatomic, strong) UIDocumentInteractionController* documentController;
@property (nonatomic) NSURL* tmpSymlinkURL;
@property (nonatomic) BOOL didSelectOptionFromDocumentController;
- (id)newCellWithDownload:(Download*)download;
- (void)startPlayerWithMedia:(NSURL*)mediaURL;
@end

@interface downloadTableViewCell : fileTableViewCell <DownloadCellDelegate> {}
@property (nonatomic, weak) id<CellDownloadDelegate> downloadDelegate;
@property NSString* fileName;
@property UIProgressView* progressView;
@property UILabel* percentProgress;
@property UILabel* sizeProgress;
@property UIButton* pauseResumeButton;
@property UIButton* stopButton;
- (id)initWithDownload:(Download*)download;
- (void)pauseResumeButtonPressed;
- (void)stopButtonPressed;
@end
