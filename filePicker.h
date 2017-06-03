//  filePicker.h
//  Headers for file picker

// (c) 2017 opa334

#import "LGShared.h"
#define imageBundlePath @"/Library/Application Support/SafariPlus.bundle"

@class filePickerNavigationController;

@protocol filePickerDelegate<NSObject>
-(void)didSelectFileAtURL:(NSURL*)url shouldCancel:(BOOL)cancel;
@end

@interface filePickerNavigationController : UINavigationController {}
@property (nonatomic, weak) id<filePickerDelegate> filePickerDelegate;
@end

@interface filePickerTableViewController : UITableViewController
{
  NSMutableArray* filesAtCurrentPath;
  NSFileManager* fileManager;
}
@property filePickerNavigationController* navController;
@property NSURL* currentPath;
@end
