//  filePickerTableViewController.h
// (c) 2017 opa334

#import "fileBrowserTableViewController.h"
#import "filePickerNavigationController.h"

@interface filePickerTableViewController : fileBrowserTableViewController {}
- (void)tableWasLongPressed:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void)toggleEditing;
- (void)uploadSelectedItems;
- (void)updateTopRightButtonAvailability;
@end
