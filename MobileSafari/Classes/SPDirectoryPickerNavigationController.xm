//  SPDirectoryPickerNavigationController.xm
// (c) 2017 opa334

#import "SPDirectoryPickerNavigationController.h"

#import "../Defines.h"
#import "../Shared.h"
#import "SPDirectoryPickerTableViewController.h"
#import "SPDownloadManager.h"
#import "SPPreferenceManager.h"

@implementation SPDirectoryPickerNavigationController

- (id)initWithDownloadInfo:(SPDownloadInfo*)downloadInfo
{
  self = [super init];

  self.downloadInfo = downloadInfo;

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
  //return instance of directoryPickerTableViewController
  return [[SPDirectoryPickerTableViewController alloc] initWithPath:path];
}

@end
