//  SPFilePickerTableViewController.h
// (c) 2017 opa334

#import "SPFileBrowserTableViewController.h"
#import "SPFilePickerNavigationController.h"

@interface SPFilePickerTableViewController : SPFileBrowserTableViewController {}
- (void)tableWasLongPressed:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void)toggleEditing;
- (void)uploadSelectedItems;
- (void)updateTopRightButtonAvailability;
@end
