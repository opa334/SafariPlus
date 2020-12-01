// Copyright (c) 2017-2020 Lars Fröder

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

#import "SPFilePickerTableViewController.h"

#import "../Util.h"
#import "SPFilePickerNavigationController.h"
#import "SPLocalizationManager.h"
#import "SPFileManager.h"
#import "../../Shared/SPFile.h"

@implementation SPFilePickerTableViewController

- (void)viewDidLoad
{
	[super viewDidLoad];

	//Activate checkmarks on the left while editing
	self.tableView.allowsMultipleSelectionDuringEditing = YES;
}

- (void)dismiss
{
	//Dismiss file picker
	[((SPFilePickerNavigationController*)self.navigationController).filePickerDelegate filePicker:(SPFilePickerNavigationController*)self.navigationController didSelectFiles:nil];
}

- (void)didSelectFile:(SPFile*)file atIndexPath:(NSIndexPath*)indexPath
{
	if(file.isRegularFile)
	{
		//tapped entry is file -> call delegate to upload file
		NSLog(@"((SPFilePickerNavigationController*)self.navigationController).filePickerDelegate = %@", ((SPFilePickerNavigationController*)self.navigationController).filePickerDelegate);
		[((SPFilePickerNavigationController*)self.navigationController).filePickerDelegate filePicker:(SPFilePickerNavigationController*)self.navigationController didSelectFiles:@[file.fileURL]];
	}

	[super didSelectFile:file atIndexPath:indexPath];
}

- (void)didLongPressFile:(SPFile*)file atIndexPath:(NSIndexPath*)indexPath
{
	if(!self.tableView.editing && file.isRegularFile)
	{
		//Toggle editing mode
		[self toggleEditing];

		//Select file
		[self.tableView selectRowAtIndexPath:indexPath animated:YES
		 scrollPosition:UITableViewScrollPositionNone];

		//Update top right button status
		[self updateTopRightButtonAvailability];
	}
}

- (void)toggleEditing
{
	//Toggle editing
	[self.tableView setEditing:!self.tableView.editing animated:YES];

	if(self.tableView.editing)
	{
		//Entered editing mode -> change top buttons
		UIBarButtonItem* cancelItem = [[UIBarButtonItem alloc]
					       initWithTitle:[localizationManager
							      localizedSPStringForKey:@"CANCEL"]
					       style:UIBarButtonItemStylePlain
					       target:self action:@selector(toggleEditing)];

		UIBarButtonItem* uploadItem = [[UIBarButtonItem alloc]
					       initWithTitle:[localizationManager
							      localizedSPStringForKey:@"UPLOAD"]
					       style:UIBarButtonItemStylePlain
					       target:self action:@selector(uploadSelectedItems)];

		self.navigationItem.leftBarButtonItem = cancelItem;
		self.navigationItem.rightBarButtonItem = uploadItem;

		self.navigationItem.rightBarButtonItem.enabled = NO;
	}
	else
	{
		//Exited editing mode -> revert top buttons
		self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;
		[self setUpRightBarButtonItems];
		self.navigationItem.rightBarButtonItem.enabled = YES;
	}
}

- (void)uploadSelectedItems
{
	//Get selected items
	NSArray* selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
	NSMutableArray* selectedURLs = [NSMutableArray new];

	//Store fileURLs into array
	for(NSIndexPath* indexPath in selectedIndexPaths)
	{
		NSURL* fileURL = self.filesAtCurrentURL[indexPath.row].fileURL;
		[selectedURLs addObject:fileURL];
	}

	//Call delegate to upload files
	[((SPFilePickerNavigationController*)self.navigationController).filePickerDelegate filePicker:(SPFilePickerNavigationController*)self.navigationController didSelectFiles:selectedURLs];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[super tableView:tableView didSelectRowAtIndexPath:indexPath];

	[self updateTopRightButtonAvailability];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self updateTopRightButtonAvailability];
}

- (void)updateTopRightButtonAvailability
{
	if(self.tableView.editing)
	{
		NSArray *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
		if([selectedIndexPaths count] <= 0)
		{
			//Count of selected files is 0 -> disable button
			self.navigationItem.rightBarButtonItem.enabled = NO;
		}
		else
		{
			//Count of selected files is 1 or more -> enable button
			self.navigationItem.rightBarButtonItem.enabled = YES;
		}
	}
	else
	{
		//TableView is not in editing mode -> enable button
		self.navigationItem.rightBarButtonItem.enabled = YES;
	}
}

@end
