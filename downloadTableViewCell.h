//  downloadTableViewCell.h
// (c) 2017 opa334

#import "fileTableViewCell.h"
#import "downloadManager.h"
#import <MobileCoreServices/MobileCoreServices.h>

@class filePickerNavigationController;

@interface downloadTableViewCell : fileTableViewCell <DownloadCellDelegate> {}
@property (nonatomic, weak) id<CellDownloadDelegate> downloadDelegate;
@property NSString* fileName;
@property UIProgressView* progressView;
@property UILabel* percentProgress;
@property UILabel* sizeProgress;
@property UILabel* sizeSpeedSeperator;
@property UILabel* downloadSpeed;
@property UIButton* pauseResumeButton;
@property UIButton* stopButton;
- (id)initWithDownload:(Download*)download;
- (void)pauseResumeButtonPressed;
- (void)stopButtonPressed;
@end
