//  downloadsNavigationController.xm
// (c) 2017 opa334

#import "downloadsNavigationController.h"

@implementation downloadsNavigationController

- (NSURL*)rootPath
{
  if(preferenceManager.customDefaultPathEnabled)
  {
    NSURL* path = [NSURL fileURLWithPath:[NSString stringWithFormat:@"/User%@", preferenceManager.customDefaultPath]];
    BOOL isDir;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[path path] isDirectory:&isDir];
    if(isDir && exists)
    {
      return path;
    }
  }
  return [NSURL fileURLWithPath:@"/User/Downloads/"];
}

- (BOOL)shouldLoadPreviousPathElements
{
  return YES;
}

- (id)newTableViewControllerWithPath:(NSURL*)path
{
  return [[downloadsTableViewController alloc] initWithPath:path];
}

@end
