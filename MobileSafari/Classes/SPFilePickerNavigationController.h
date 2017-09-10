//  SPFilePickerNavigationController.h
// (c) 2017 opa334

#import "SPFileBrowserNavigationController.h"
#import "SPFilePickerTableViewController.h"

@protocol filePickerDelegate<NSObject>
- (void)didSelectFilesAtURL:(NSArray*)URLArray;
@end

@interface SPFilePickerNavigationController : SPFileBrowserNavigationController {}
@property (nonatomic, weak) id<filePickerDelegate> filePickerDelegate;
@end
