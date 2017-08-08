//  fileBrowserNavigationController.xm
// (c) 2017 opa334

#import "fileBrowserNavigationController.h"

@implementation fileBrowserNavigationController

- (void)viewDidLoad
{
  if(self.shouldLoadPreviousPathElements)
  {
    NSURL* tmpURL = self.rootPath;
    NSMutableArray* URLListArray = [NSMutableArray new];

    for(int i = 0; i <= [[self.rootPath pathComponents] count] - 1; i++)
    {
      [URLListArray addObject:tmpURL];
      tmpURL = [tmpURL URLByDeletingLastPathComponent];
    }

    for(NSURL* URL in [URLListArray reverseObjectEnumerator])
    {
      [self pushViewController:[self newTableViewControllerWithPath:URL] animated:NO];
    }
  }

  else
  {
    [self pushViewController:[self newTableViewControllerWithPath:self.rootPath] animated:NO];
  }

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadAllTableViews) name:UIApplicationWillEnterForegroundNotification object:nil];

  [super viewDidLoad];
}

- (void)viewDidUnload
{
  [super viewDidUnload];

  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reloadAllTableViews
{
  for(fileBrowserTableViewController* tableViewController in self.viewControllers)
  {
    [tableViewController reloadDataAndDataSources];
  }
}

- (id)newTableViewControllerWithPath:(NSURL*)path
{
  return [[fileBrowserTableViewController alloc] initWithPath:path];
}

- (NSURL*)rootPath
{
  return [NSURL fileURLWithPath:@"/"];
}

- (BOOL)shouldLoadPreviousPathElements
{
  return NO;
}

@end
