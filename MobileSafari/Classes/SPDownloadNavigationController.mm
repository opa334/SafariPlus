// SPDownloadNavigationController.mm
// (c) 2017 - 2019 opa334

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

#import "SPDownloadNavigationController.h"

#import "../SafariPlus.h"
#import "../Defines.h"
#import "../Util.h"
#import "SPDownloadManager.h"
#import "SPDownloadBrowserTableViewController.h"
#import "SPDownloadListTableViewController.h"
#import "SPFileBrowserNavigationController.h"
#import "SPLocalizationManager.h"
#import "SPPreferenceManager.h"
#import "SPCacheManager.h"
#import "SPFileManager.h"

@implementation SPDownloadNavigationController

- (id)init
{
	self.startURL = downloadManager.defaultDownloadURL;
	self.loadParentDirectories = YES;

	self = [super init];

	if(preferenceManager.defaultDownloadSectionAutoSwitchEnabled)
	{
		if([downloadManager.pendingDownloads count] > 0)
		{
			_previousSelectedIndex = preferenceManager.defaultDownloadSection;
		}
		else
		{
			_previousSelectedIndex = ~preferenceManager.defaultDownloadSection & 1;
		}
	}
	else
	{
		_previousSelectedIndex = preferenceManager.defaultDownloadSection;
	}

	[self setUpPalette];

	//Set delegate of SPDownloadManager for communication
	downloadManager.navigationControllerDelegate = self;

	return self;
}

- (void)setUpTableViewControllers
{
	_browserTableViewControllers = [self tableViewControllersForDirectory:self.startURL recursive:self.loadParentDirectories];
	_listTableViewControllers = @[[[SPDownloadListTableViewController alloc] init]];
}

- (void)setUpSegmentedControl
{
	_segmentedControl = [[UISegmentedControl alloc] initWithItems:@[[localizationManager localizedSPStringForKey:@"FILE_BROWSER"], [localizationManager localizedSPStringForKey:@"DOWNLOADS"]]];
	[_segmentedControl addTarget:self action:@selector(segmentedControlValueDidChange:) forControlEvents:UIControlEventValueChanged];
	_segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
	_segmentedControl.selectedSegmentIndex = _previousSelectedIndex;

	[self segmentedControlValueDidChange:_segmentedControl];
}

- (void)setUpPalette
{
	[self setUpSegmentedControl];

	_palette = [self paletteForEdge:2 size:CGSizeMake(CGRectGetWidth(self.view.bounds), 41)];

	[_palette addSubview:_segmentedControl];

	NSDictionary *views = NSDictionaryOfVariableBindings(_segmentedControl);

	[_palette addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-8-[_segmentedControl]-8-|" options:0 metrics:nil views:views]];
	[_palette addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_segmentedControl]-12-|" options:0 metrics:nil views:views]];

	[self attachPalette:_palette isPinned:YES];
}

- (void)openDirectoryInBrowser:(NSURL*)directoryURL
{
	_browserTableViewControllers = [self tableViewControllersForDirectory:directoryURL recursive:YES];
	_segmentedControl.selectedSegmentIndex = 0;
	[self segmentedControlValueDidChange:_segmentedControl];
}

- (void)showFileInBrowser:(NSURL*)fileURL
{
	[self openDirectoryInBrowser:fileURL.URLByDeletingLastPathComponent];

	[[self browserTableViewControllers].lastObject showFileNamed:[fileURL lastPathComponent]];
}

- (void)segmentedControlValueDidChange:(UISegmentedControl *)segmentedControl
{
	if(segmentedControl.selectedSegmentIndex == 0)
	{
		if(_previousSelectedIndex == 1)
		{
			_listTableViewControllers = self.viewControllers;
		}

		[self setViewControllers:_browserTableViewControllers animated:NO];
	}
	else
	{
		if(_previousSelectedIndex == 0)
		{
			_browserTableViewControllers = self.viewControllers;
		}

		[self setViewControllers:_listTableViewControllers animated:NO];
	}

	_previousSelectedIndex = segmentedControl.selectedSegmentIndex;
}

- (NSArray<SPDownloadBrowserTableViewController*>*)browserTableViewControllers
{
	if(_segmentedControl.selectedSegmentIndex == 0)
	{
		return self.viewControllers;
	}
	else
	{
		return _browserTableViewControllers;
	}
}

- (NSArray<SPDownloadListTableViewController*>*)listTableViewControllers
{
	if(_segmentedControl.selectedSegmentIndex == 1)
	{
		return self.viewControllers;
	}
	else
	{
		return _listTableViewControllers;
	}
}

- (void)reloadBrowser
{
	[self reloadBrowserForced:NO];
}

- (void)reloadBrowserForced:(BOOL)forced
{
	[[self browserTableViewControllers].lastObject reloadForced:forced];
}

- (void)reloadEverything
{
	[self reloadEverythingForced:NO];
}

- (void)reloadEverythingForced:(BOOL)forced
{
	for(SPFileBrowserTableViewController* viewController in [self browserTableViewControllers])
	{
		[viewController reloadForced:forced];
	}

	[self reloadDownloadListForced:forced];
}

- (void)reloadDownloadList
{
	[self reloadDownloadListForced:NO];
}

- (void)reloadDownloadListForced:(BOOL)forced
{
	[[self listTableViewControllers].firstObject reloadForced:forced];
}

- (Class)tableControllerClass
{
	return [SPDownloadBrowserTableViewController class];
}

@end
