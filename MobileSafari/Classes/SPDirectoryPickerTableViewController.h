//  SPDirectoryPickerTableViewController.h
// (c) 2017 opa334

#import "SPFileBrowserTableViewController.h"
#import "SPDirectoryPickerNavigationController.h"
#import "SPLocalizationManager.h"
#import "SPPreferenceManager.h"
#import "../Shared.h"

@interface SPDirectoryPickerTableViewController : SPFileBrowserTableViewController {}
- (BOOL)canDownloadToPath:(NSURL*)pathURL;
- (void)chooseButtonPressed;
@end
