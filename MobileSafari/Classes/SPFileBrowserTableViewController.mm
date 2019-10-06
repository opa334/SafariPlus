// SPFileBrowserTableViewController.mm
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

#import "SPFileBrowserTableViewController.h"
#import "Extensions.h"

#import "../Util.h"
#import "SPFileBrowserNavigationController.h"
#import "SPFileTableViewCell.h"
#import "SPLocalizationManager.h"
#import "SPFileManager.h"
#import "SPFile.h"

@implementation SPFileBrowserTableViewController

- (instancetype)initWithDirectoryURL:(NSURL*)directoryURL
{
	self = [super init];

	if(directoryURL)
	{
		self.title = directoryURL.lastPathComponent;

		_directoryURL = [fileManager resolveSymlinkForURL:directoryURL];
	}

	[self setUpRightBarButtonItems];

	[self.tableView registerClass:[SPFileTableViewCell class] forCellReuseIdentifier:@"SPFileTableViewCell"];

	return self;
}

- (void)setUpRightBarButtonItems
{
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[localizationManager
											 localizedSPStringForKey:@"DISMISS"] style:UIBarButtonItemStylePlain
						  target:self action:@selector(dismiss)];
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	//Add refreshControl (pull up to refresh)
	self.refreshControl = [[UIRefreshControl alloc] init];
	[self.refreshControl addTarget:self action:@selector(refreshControlValueChanged) forControlEvents:UIControlEventValueChanged];

	//Initialise long press recognizer for tableView
	self.longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressTable:)];

	//Duration of long press: 1 second
	self.longPressRecognizer.minimumPressDuration = 1.0;

	//Add long press recognizer to tableView
	[self.tableView addGestureRecognizer:self.longPressRecognizer];

	[self loadContents];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[self fixFooterColors];
}

- (BOOL)loadContents
{
	NSMutableArray<SPFile*>* newFiles = [NSMutableArray new];

	//Fetch files from current URL into array
	NSArray* fileURLs = [fileManager contentsOfDirectoryAtURL:_directoryURL
			     includingPropertiesForKeys:nil options:0 error:nil];

	for(NSURL* fileURL in fileURLs)
	{
		SPFile* file = [[SPFile alloc] initWithFileURL:fileURL];
		[newFiles addObject:file];
	}

	[newFiles sortUsingComparator:^NSComparisonResult (SPFile* a, SPFile* b)
	{
		return [a.cellTitle.string caseInsensitiveCompare:b.cellTitle.string];
	}];

	BOOL filesNeedUpdate = ![_filesAtCurrentURL isEqualToArray:newFiles];

	if(filesNeedUpdate)
	{
		_filesAtCurrentURL = [newFiles copy];
	}

	return filesNeedUpdate;
}

- (void)refreshControlValueChanged
{
	if(!self.tableView.isDragging)
	{
		[self reload];
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if([self.refreshControl isRefreshing])
	{
		[self reload];
	}
}

- (void)reload
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
	{
		//Repopulate dataSources
		BOOL needsReload = [self loadContents];

		if(needsReload)
		{
			//Reload tableView with new dataSources
			NSRange range = NSMakeRange(0, [self numberOfSectionsInTableView:self.tableView]);
			NSIndexSet* sections = [NSIndexSet indexSetWithIndexesInRange:range];

			dispatch_async(dispatch_get_main_queue(), ^
			{
				[self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationFade];

				if([self.refreshControl isRefreshing])
				{
					//Stop refresh animation if needed
					[self.refreshControl endRefreshing];
				}
			});
		}
		else
		{
			dispatch_async(dispatch_get_main_queue(), ^
			{
				if([self.refreshControl isRefreshing])
				{
					//Stop refresh animation if needed
					[self.refreshControl endRefreshing];
				}
			});
		}
	});
}

- (void)dismiss
{
	dispatch_async(dispatch_get_main_queue(), ^
	{
		//Dismiss controller
		[self dismissViewControllerAnimated:YES completion:nil];
	});
}

- (NSInteger)fileSection
{
	return 0;
}

- (void)didLongPressTable:(UILongPressGestureRecognizer*)gestureRecognizer
{
	if(gestureRecognizer.state == UIGestureRecognizerStateBegan)
	{
		//Get CGPoint of touch location
		CGPoint p = [gestureRecognizer locationInView:self.tableView];

		//Get index path of CGPoint
		NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];

		if(indexPath.section == [self fileSection])
		{
			[self didLongPressFile:self.filesAtCurrentURL[indexPath.row] atIndexPath:indexPath];
		}
	}
}

- (void)didSelectFile:(SPFile*)file atIndexPath:(NSIndexPath*)indexPath
{
	if(!file.isRegularFile)
	{
		Class tableClass = [(SPFileBrowserNavigationController*)self.navigationController tableControllerClass];

		SPFileBrowserTableViewController* tableViewController = [((SPFileBrowserTableViewController*)[tableClass alloc]) initWithDirectoryURL:file.fileURL];

		[self.navigationController pushViewController:tableViewController animated:YES];
	}
}

- (void)didLongPressFile:(SPFile*)file atIndexPath:(NSIndexPath*)indexPath
{
	return;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	//One section (files)
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	//Return amount of files at current path
	return [_filesAtCurrentURL count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	//Get file for row
	SPFile* file = _filesAtCurrentURL[indexPath.row];

	SPFileTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"SPFileTableViewCell"];

	if(!cell)
	{
		cell = [[SPFileTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SPFileTableViewCell"];
	}

	[cell applyFile:file];

	//Return cell for file
	return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(tableView.editing)
	{
		//tableView is in editing mode -> Make directories unselectable
		SPFile* selectedFile = _filesAtCurrentURL[indexPath.row];

		if(!selectedFile.isRegularFile)
		{
			return nil;
		}
	}

	return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(!tableView.editing)
	{
		//tableView is not in editing mode -> Select file / directory
		SPFile* selectedFile = _filesAtCurrentURL[indexPath.row];

		[self didSelectFile:selectedFile atIndexPath:indexPath];
	}
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	SPFile* file = _filesAtCurrentURL[indexPath.row];

	//Only files should be editable
	return file.isRegularFile;
}

@end
