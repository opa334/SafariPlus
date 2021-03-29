// Copyright (c) 2017-2021 Lars Fröder

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
	[self reloadBrowserAnimated:YES];
}

- (void)reloadBrowserAnimated:(BOOL)animated
{
	[self.viewControllers.lastObject reloadAnimated:animated];
}

- (void)reloadEverything
{
	[self reloadEverythingAnimated:YES];
}

- (void)reloadEverythingAnimated:(BOOL)animated
{
	for(SPFileBrowserTableViewController* viewController in self.viewControllers)
	{
		[viewController reloadAnimated:animated];
	}
}

- (Class)tableControllerClass
{
	return [SPFileBrowserTableViewController class];
}

@end
