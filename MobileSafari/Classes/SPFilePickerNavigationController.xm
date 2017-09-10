//  SPFilePickerNavigationController.xm
// (c) 2017 opa334

#import "SPFilePickerNavigationController.h"

@implementation SPFilePickerNavigationController

- (id)newTableViewControllerWithPath:(NSURL*)path
{
  //return instance of filePickerTableViewController
  return [[SPFilePickerTableViewController alloc] initWithPath:path];
}

@end
