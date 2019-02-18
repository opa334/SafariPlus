// SPFileBrowserNavigationController.mm
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

- (instancetype)init
{
	self = [super init];

	[self setUpTableViewControllers];

	//Add observer to reload all files if app enters foreground (after being minimized)
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadEverything)
	 name:UIApplicationWillEnterForegroundNotification object:nil];

	return self;
}

- (void)setUpTableViewControllers
{
	NSArray* tableViewControllers = [self tableViewControllersForDirectory:_startURL recursive:self.loadParentDirectories];

	[self setViewControllers:tableViewControllers animated:NO];
}

- (NSArray*)tableViewControllersForDirectory:(NSURL*)directoryURL recursive:(BOOL)recursive
{
	NSMutableArray* viewControllers = [NSMutableArray new];

	if(recursive)
	{
		NSURL* tmpURL;

		for(NSString* component in directoryURL.pathComponents)
		{
			if(!tmpURL)
			{
				tmpURL = [NSURL fileURLWithPath:component];
			}
			else
			{
				tmpURL = [tmpURL URLByAppendingPathComponent:component];
			}

			[viewControllers addObject:[((SPFileBrowserTableViewController*)[[self tableControllerClass] alloc]) initWithDirectoryURL:tmpURL]];
		}
	}
	else
	{
		[viewControllers addObject:[((SPFileBrowserTableViewController*)[[self tableControllerClass] alloc]) initWithDirectoryURL:directoryURL]];
	}

	return [viewControllers copy];
}

- (void)reloadBrowser
{
	[self.viewControllers.lastObject reload];
}

- (void)reloadEverything
{
	for(SPFileBrowserTableViewController* viewController in self.viewControllers)
	{
		[viewController reload];
	}
}

- (Class)tableControllerClass
{
	return [SPFileBrowserTableViewController class];
}

@end
