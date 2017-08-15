//  directoryPickerTableViewController.h
// (c) 2017 opa334

#import "preferenceFileBrowserTableViewController.h"
#import "preferenceDirectoryPickerNavigationController.h"
#import "SPPreferenceLocalizationManager.h"

@interface preferenceDirectoryPickerTableViewController : preferenceFileBrowserTableViewController {}
- (BOOL)canDownloadToPath:(NSURL*)pathURL;
- (void)chooseButtonPressed;
@end
