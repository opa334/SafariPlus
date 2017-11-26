//  SPFilePickerNavigationController.h
// (c) 2017 opa334

#import "SPFileBrowserNavigationController.h"
#import "../Protocols.h"

@interface SPFilePickerNavigationController : SPFileBrowserNavigationController {}
@property (nonatomic, weak) id<filePickerDelegate> filePickerDelegate;
@end
