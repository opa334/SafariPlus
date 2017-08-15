//  downloadsNavigationController.xm
// (c) 2017 opa334

#import "downloadsNavigationController.h"

@implementation downloadsNavigationController

- (NSURL*)rootPath
{
  if(preferenceManager.customDefaultPathEnabled)
  {
    //customDefaultPath enabled -> return custom path if it is valid
    NSURL* path = [NSURL fileURLWithPath:[NSString stringWithFormat:@"/User%@", preferenceManager.customDefaultPath]];
    BOOL isDir;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[path path] isDirectory:&isDir];
    if(isDir && exists)
    {
      return path;
    }
  }
  //customDefaultPath disabled or invalid -> return default path
  return [NSURL fileURLWithPath:@"/User/Downloads/"];
}

- (BOOL)shouldLoadPreviousPathElements
{
  return YES;
}

- (id)newTableViewControllerWithPath:(NSURL*)path
{
  //return instance of downloadsTableViewController
  return [[downloadsTableViewController alloc] initWithPath:path];
}

@end
