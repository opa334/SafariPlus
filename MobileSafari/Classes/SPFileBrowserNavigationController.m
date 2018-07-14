// SPFileBrowserNavigationController.m
// (c) 2018 opa334

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import "SPFileBrowserNavigationController.h"

#import "SPFileBrowserTableViewController.h"

@implementation SPFileBrowserNavigationController

- (void)viewDidLoad
{
  if(_loadPreviousPathElements)
  {
    //loadPreviousPathElements enabled -> push all previous paths

    //Create array for all previous paths
    NSMutableArray* previousPaths = [NSMutableArray new];

    NSInteger pathComponentCount = [[self.startPath pathComponents] count];

    NSString* workPath = self.startPath;

    //Get all previous paths through always removing last past component and save them to array
    for(int i = 0; i < pathComponentCount; i++)
    {
      [previousPaths addObject:workPath];
      workPath = [workPath stringByDeletingLastPathComponent];
    }

    //Push all paths in reverse
    for(NSString* path in [previousPaths reverseObjectEnumerator])
    {
      [self pushViewController:[self newTableViewControllerWithPath:path] animated:NO];
    }
  }
  else
  {
    //loadPreviousPathElements disabled -> only start path
    [self pushViewController:[self newTableViewControllerWithPath:self.startPath] animated:NO];
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

- (id)newTableViewControllerWithPath:(NSString*)path
{
  //Return instance of SPFileBrowserTableViewController
  return [[SPFileBrowserTableViewController alloc] initWithPath:path];
}

@end
