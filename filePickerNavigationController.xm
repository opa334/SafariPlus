//  filePickerNavigationController.xm
// (c) 2017 opa334

#import "filePickerNavigationController.h"

@implementation filePickerNavigationController

- (id)newTableViewControllerWithPath:(NSURL*)path
{
  //return instance of filePickerTableViewController
  return [[filePickerTableViewController alloc] initWithPath:path];
}

@end
