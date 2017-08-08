//  directoryPickerTableViewController.h
// (c) 2017 opa334

#import "fileBrowserTableViewController.h"
#import "directoryPickerNavigationController.h"
#import "SPLocalizationManager.h"
#import "SPPreferenceManager.h"

@interface directoryPickerTableViewController : fileBrowserTableViewController {}
- (BOOL)canDownloadToPath:(NSURL*)pathURL;
- (void)chooseButtonPressed;
@end
