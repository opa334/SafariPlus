//  filePickerNavigationController.xm
// (c) 2017 opa334

#import "filePickerNavigationController.h"

@implementation filePickerNavigationController

- (id)newTableViewControllerWithPath:(NSURL*)path
{
  return [[filePickerTableViewController alloc] initWithPath:path];
}

@end
