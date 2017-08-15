//  preferenceDirectoryPickerNavigationController.xm
// (c) 2017 opa334

#import "preferenceDirectoryPickerNavigationController.h"

@implementation preferenceDirectoryPickerNavigationController

- (id)initWithDelegate:(id<PinnedLocationsDelegate>)delegate name:(NSString*) name
{
  self = [super init];
  self.pinnedLocationsDelegate = delegate;
  self.name = name;
  return self;
}

- (NSURL*)rootPath
{
  //return User directory
  return [NSURL fileURLWithPath:@"/User/"];
}

- (BOOL)shouldLoadPreviousPathElements
{
  return YES;
}

- (id)newTableViewControllerWithPath:(NSURL*)path
{
  //return instance of directoryPickerTableViewController
  return [[preferenceDirectoryPickerTableViewController alloc] initWithPath:path];
}

@end
