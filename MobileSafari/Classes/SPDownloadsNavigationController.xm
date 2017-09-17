//  SPDownloadsNavigationController.xm
// (c) 2017 opa334

#import "SPDownloadsNavigationController.h"

@implementation SPDownloadsNavigationController

- (id)init
{
  self = [super init];

  //Set delegate of SPDownloadManager for communication
  [SPDownloadManager sharedInstance].navigationControllerDelegate = self;

  return self;
}

- (NSURL*)rootPath
{
  if(preferenceManager.customDefaultPathEnabled)
  {
    //customDefaultPath enabled -> return custom path if it is valid
    NSURL* path = [NSURL fileURLWithPath:[NSString stringWithFormat:@"/var%@", preferenceManager.customDefaultPath]];
    BOOL isDir;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[path path] isDirectory:&isDir];
    if(isDir && exists)
    {
      return path;
    }
  }
  //customDefaultPath disabled or invalid -> return default path
  return [NSURL fileURLWithPath:defaultDownloadPath];
}

- (BOOL)shouldLoadPreviousPathElements
{
  return YES;
}

- (id)newTableViewControllerWithPath:(NSURL*)path
{
  //return instance of SPDownloadsTableViewController
  return [[SPDownloadsTableViewController alloc] initWithPath:path];
}

@end
