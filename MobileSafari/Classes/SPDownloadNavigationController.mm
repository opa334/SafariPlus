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

	if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_13_0)
	{
		[self setUpPalette];
	}
	else
	{
		[self setUpSegmentedControl];
	}

	//Register as observer
	[downloadManager addObserverDelegate:self];

	return self;
}

- (void)dealloc
{
	[downloadManager removeObserverDelegate:self];
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

//iOS 13 and up
- (void)applyPaletteToViewController:(UIViewController*)viewController
{
	if(!_palette)
	{
		UIView* contentView = [[UIView alloc] initWithSize:CGSizeMake(self.view.bounds.size.width, _segmentedControl.bounds.size.height + 12.0)];
		contentView.translatesAutoresizingMaskIntoConstraints = NO;
		[contentView addSubview:_segmentedControl];

		[NSLayoutConstraint activateConstraints:@[
			[_segmentedControl.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:8],
			[contentView.trailingAnchor constraintEqualToAnchor:_segmentedControl.trailingAnchor constant:8],
			[_segmentedControl.topAnchor constraintEqualToAnchor:contentView.topAnchor],
			[contentView.bottomAnchor constraintEqualToAnchor:_segmentedControl.bottomAnchor constant:12],
		]];

		_palette = [[NSClassFromString(@"_UINavigationBarPalette") alloc] initWithContentView:contentView];

		[NSLayoutConstraint activateConstraints:@[
			[_palette.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor],
			[_palette.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor],
			[_palette.topAnchor constraintEqualToAnchor:contentView.topAnchor],
			[_palette.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor],
		]];
	}

	viewController.navigationItem._bottomPalette = (_UINavigationBarPalette*)_palette;
}

//iOS 12 and down
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
	[self reloadBrowserAnimated:YES];
}

- (void)reloadBrowserAnimated:(BOOL)animated
{
	[[self browserTableViewControllers].lastObject reloadAnimated:animated];
}

- (void)reloadEverything
{
	[self reloadEverythingAnimated:YES];
}

- (void)reloadEverythingAnimated:(BOOL)animated
{
	for(SPFileBrowserTableViewController* viewController in [self browserTableViewControllers])
	{
		[viewController reloadAnimated:animated];
	}

	[self reloadDownloadListAnimated:animated];
}

- (void)reloadDownloadList
{
	[self reloadDownloadListAnimated:YES];
}

- (void)reloadDownloadListAnimated:(BOOL)animated
{
	[[self listTableViewControllers].firstObject reloadAnimated:animated];
}

- (void)totalDownloadsCountDidChangeForDownloadManager:(SPDownloadManager*)downloadManager
{
	[self reloadEverything];
}

- (void)downloadHistoryDidChangeForDownloadManager:(SPDownloadManager*)downloadManager
{
	[self reloadDownloadList];
}

- (Class)tableControllerClass
{
	return [SPDownloadBrowserTableViewController class];
}

@end
