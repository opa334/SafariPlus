//  SPDirectoryPickerNavigationController.h
// (c) 2017 opa334

#import "SPFileBrowserNavigationController.h"

@class SPDownloadInfo;

@interface SPDirectoryPickerNavigationController : SPFileBrowserNavigationController {}
@property (nonatomic) SPDownloadInfo* downloadInfo;
- (id)initWithDownloadInfo:(SPDownloadInfo*)downloadInfo;
@end
