//  filePickerNavigationController.h
// (c) 2017 opa334

#import "fileBrowserNavigationController.h"
#import "filePickerTableViewController.h"

@protocol filePickerDelegate<NSObject>
- (void)didSelectFilesAtURL:(NSArray*)URLArray;
@end

@interface filePickerNavigationController : fileBrowserNavigationController {}
@property (nonatomic, weak) id<filePickerDelegate> filePickerDelegate;
@end
