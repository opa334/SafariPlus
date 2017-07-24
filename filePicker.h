//  filePicker.h
//  Headers for file picker

// (c) 2017 opa334

#import "fileBrowser.h"

@class filePickerNavigationController;

@protocol filePickerDelegate<NSObject>
- (void)didSelectFilesAtURL:(NSArray*)URLArray;
@end

@interface filePickerNavigationController : fileBrowserNavigationController {}
@property (nonatomic, weak) id<filePickerDelegate> filePickerDelegate;
@end

@interface filePickerTableViewController : fileBrowserTableViewController {}
- (void)tableWasLongPressed:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void)toggleEditing;
- (void)uploadSelectedItems;
- (void)updateTopRightButtonAvailability;
@end
