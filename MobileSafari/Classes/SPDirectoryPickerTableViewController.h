//  SPDirectoryPickerTableViewController.h
// (c) 2017 opa334

#import "SPFileBrowserTableViewController.h"

@class SPFileBrowserTableViewController;

@interface SPDirectoryPickerTableViewController : SPFileBrowserTableViewController
- (BOOL)canDownloadToPath:(NSURL*)pathURL;
- (void)chooseButtonPressed;
@end
