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

- (void)viewDidLoad
{
  [super viewDidLoad];

  UILongPressGestureRecognizer* barRecognizer = [[UILongPressGestureRecognizer alloc] init];
  barRecognizer.minimumPressDuration = 5;
  [barRecognizer addTarget:self action:@selector(handleNavigationBarLongPress:)];

  [self.navigationBar addGestureRecognizer:barRecognizer];
}

- (void)handleNavigationBarLongPress:(UILongPressGestureRecognizer*)sender
{
  if(sender.state == UIGestureRecognizerStateBegan)
  {
      UIAlertController* warningAlert = [UIAlertController
        alertControllerWithTitle:[localizationManager
        localizedSPStringForKey:@"WARNING"]
        message:[localizationManager localizedSPStringForKey:@"CLEAR_EVERYTHING_WARNING"]
        preferredStyle:UIAlertControllerStyleAlert];

      UIAlertAction* yesAction = [UIAlertAction actionWithTitle:[localizationManager
        localizedSPStringForKey:@"YES"]
        style:UIAlertActionStyleDestructive
        handler:^(UIAlertAction* action)
      {
        [[SPDownloadManager sharedInstance] cancelAllDownloads];
        [[SPDownloadManager sharedInstance] removeDownloadStorageFile];
        [[SPDownloadManager sharedInstance] clearTempFiles];
      }];

      UIAlertAction* noAction = [UIAlertAction actionWithTitle:[localizationManager
        localizedSPStringForKey:@"NO"]
        style:UIAlertActionStyleCancel
        handler:nil];

      [warningAlert addAction:yesAction];
      [warningAlert addAction:noAction];

      [self presentViewController:warningAlert animated:YES completion:nil];
  }


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
