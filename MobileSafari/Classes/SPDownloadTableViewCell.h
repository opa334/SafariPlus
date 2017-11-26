//  SPDownloadTableViewCell.h
// (c) 2017 opa334

#import "../Protocols.h"

@class SPFilePickerNavigationController;

@interface SPDownloadTableViewCell : UITableViewCell <DownloadCellDelegate> {}
@property (nonatomic, weak) id<CellDownloadDelegate> downloadDelegate;
@property NSString* filename;
@property UIProgressView* progressView;
@property UILabel* filenameLabel;
@property UIImageView* fileIcon;
@property UILabel* percentProgress;
@property UILabel* sizeProgress;
@property UILabel* sizeSpeedSeperator;
@property UILabel* downloadSpeed;
@property UIButton* pauseResumeButton;
@property UIButton* stopButton;
- (id)initWithDownload:(SPDownload*)download;
- (void)setPaused:(BOOL)paused;
- (void)pauseResumeButtonPressed;
- (void)stopButtonPressed;
@end
