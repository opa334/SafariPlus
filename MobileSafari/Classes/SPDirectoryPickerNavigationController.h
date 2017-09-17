//  SPDirectoryPickerNavigationController.h
// (c) 2017 opa334

#import "SPDirectoryPickerTableViewController.h"
#import "SPFileBrowserNavigationController.h"
#import "SPDownloadManager.h"

@interface SPDirectoryPickerNavigationController : SPFileBrowserNavigationController {}
@property (nonatomic) SPDownloadInfo* downloadInfo;
- (id)initWithDownloadInfo:(SPDownloadInfo*)downloadInfo;
@end
