//  SPFileBrowserNavigationController.xm
// (c) 2017 opa334

#import "SPFileBrowserNavigationController.h"

@implementation SPFileBrowserNavigationController

- (void)viewDidLoad
{
  if(self.shouldLoadPreviousPathElements)
  {
    //shouldLoadPreviousPathElements enabled -> push all previous urls
    //Get rootURL
    NSURL* tmpURL = self.rootPath;

    //Create array for all previous URLs
    NSMutableArray* URLListArray = [NSMutableArray new];

    //Get all previous URLs through always removing last past component and save them to array
    for(int i = 0; i <= [[self.rootPath pathComponents] count] - 1; i++)
    {
      [URLListArray addObject:tmpURL];
      tmpURL = [tmpURL URLByDeletingLastPathComponent];
    }

    //Push all URLs in reverse
    for(NSURL* URL in [URLListArray reverseObjectEnumerator])
    {
      [self pushViewController:[self newTableViewControllerWithPath:URL] animated:NO];
    }
  }

  else
  {
    //shouldLoadPreviousPathElements disabled -> only push specified URL
    [self pushViewController:[self newTableViewControllerWithPath:self.rootPath] animated:NO];
  }

  //Add observer to reload all files if app enters foreground (after being minimized)
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadAllTableViews)
    name:UIApplicationWillEnterForegroundNotification object:nil];

  [super viewDidLoad];
}

- (void)viewDidUnload
{
  [super viewDidUnload];

  //Remove observer
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reloadTopTableView
{
  [(SPFileBrowserTableViewController*)self.visibleViewController reloadDataAndDataSources];
}

- (void)reloadAllTableViews
{
  //Cycle through all tableViews and reload their data
  for(SPFileBrowserTableViewController* tableViewController in self.viewControllers)
  {
    [tableViewController reloadDataAndDataSources];
  }
}

- (id)newTableViewControllerWithPath:(NSURL*)path
{
  //Return instance of SPFileBrowserTableViewController
  return [[SPFileBrowserTableViewController alloc] initWithPath:path];
}

- (NSURL*)rootPath
{
  //Default rootPath is /
  return [NSURL fileURLWithPath:@"/"];
}

- (BOOL)shouldLoadPreviousPathElements
{
  //Default value for shouldLoadPreviousPathElements is NO
  return NO;
}

@end
