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

#import "SPDownloadListTableViewController.h"
#import "Extensions.h"

#import "SPDownloadListTableViewCell.h"
#import "SPDownloadListFinishedTableViewCell.h"
#import "SPDownload.h"
#import "SPDownloadInfo.h"
#import "SPDownloadNavigationController.h"
#import "../Util.h"
#import "../Defines.h"
#import "../Classes/SPLocalizationManager.h"
#import "../Classes/SPDownloadManager.h"
#import "../Classes/SPCacheManager.h"
#import "../Classes/SPFileManager.h"
#import "../Classes/SPCellButtonsView.h"
#import "../SafariPlus.h"

@implementation SPDownloadListTableViewController

- (instancetype)init
{
	self = [super init];

	[self loadDownloads];

	return self;
}

- (void)willMoveToParentViewController:(UIViewController *)parent
{
	[super willMoveToParentViewController:parent];
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0)
	{
		[(SPDownloadNavigationController*)self.navigationController applyPaletteToViewController:self];
	}
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	UIBarButtonItem* dismissItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
					target:self action:@selector(dismissButtonPressed)];

	UIBarButtonItem* addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonPressed:)];

	self.navigationItem.rightBarButtonItems = @[dismissItem, addItem];

	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[localizationManager
											localizedSPStringForKey:@"CLEAR"] style:UIBarButtonItemStylePlain
						 target:self action:@selector(clearButtonPressed)];

	self.title = [localizationManager localizedSPStringForKey:@"DOWNLOAD_OVERVIEW"];

	[self.tableView registerClass:[SPDownloadListTableViewCell class] forCellReuseIdentifier:@"SPDownloadListTableViewCell"];
	[self.tableView registerClass:[SPDownloadListFinishedTableViewCell class] forCellReuseIdentifier:@"SPDownloadListFinishedTableViewCell"];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	for(__kindof UITableViewCell* cell in self.tableView.visibleCells)
	{
		if([cell isMemberOfClass:[SPDownloadListFinishedTableViewCell class]])
		{
			[cell updateButtons];
		}
	}

	[self fixHeaderColors];
}

- (void)applyChangesAfterReload
{
	_displayedPendingDownloads = [_pendingDownloads copy];
	_displayedFinishedDownloads = [_finishedDownloads copy];

	[self updateSectionHeaders];
}

- (void)applyChangesToTable
{
	if(!_displayedPendingDownloads || !_displayedFinishedDownloads)
	{
		return;
	}

	NSMutableSet<SPDownload*>* oldPendingDownloadsSet = [NSMutableSet setWithArray:_displayedPendingDownloads];
	NSMutableSet<SPDownload*>* currentPendingDownloadsSet = [NSMutableSet setWithArray:_pendingDownloads];

	NSMutableSet<SPDownload*>* newPendingDownloadsSet = [currentPendingDownloadsSet mutableCopy];
	NSMutableSet<SPDownload*>* finishedPendingDownloadsSet = [oldPendingDownloadsSet mutableCopy];

	[newPendingDownloadsSet minusSet:oldPendingDownloadsSet];
	[finishedPendingDownloadsSet minusSet:currentPendingDownloadsSet];

	NSMutableSet<SPDownload*>* oldFinishedDownloadsSet = [NSMutableSet setWithArray:_displayedFinishedDownloads];
	NSMutableSet<SPDownload*>* currentFinishedDownloadsSet = [NSMutableSet setWithArray:_finishedDownloads];

	NSMutableSet<SPDownload*>* newFinishedDownloadsSet = [currentFinishedDownloadsSet mutableCopy];
	NSMutableSet<SPDownload*>* deletedFinishedDownloadsSet = [oldFinishedDownloadsSet mutableCopy];

	[newFinishedDownloadsSet minusSet:oldFinishedDownloadsSet];
	[deletedFinishedDownloadsSet minusSet:currentFinishedDownloadsSet];

	NSMutableArray<NSIndexPath*>* addIndexPaths = [NSMutableArray new];
	NSMutableArray<NSIndexPath*>* deleteIndexPaths = [NSMutableArray new];

	for(SPDownload* download in finishedPendingDownloadsSet)
	{
		[deleteIndexPaths addObject:[NSIndexPath indexPathForRow:[_displayedPendingDownloads indexOfObject:download] inSection:0]];
	}

	for(SPDownload* download in newPendingDownloadsSet)
	{
		[addIndexPaths addObject:[NSIndexPath indexPathForRow:[_pendingDownloads indexOfObject:download] inSection:0]];
	}

	for(SPDownload* download in deletedFinishedDownloadsSet)
	{
		[deleteIndexPaths addObject:[NSIndexPath indexPathForRow:[_displayedFinishedDownloads indexOfObject:download] inSection:1]];
	}

	for(SPDownload* download in newFinishedDownloadsSet)
	{
		[addIndexPaths addObject:[NSIndexPath indexPathForRow:[_finishedDownloads indexOfObject:download] inSection:1]];
	}

	dispatch_sync(dispatch_get_main_queue(), ^
	{
		if(addIndexPaths.count > 0 || deleteIndexPaths.count > 0)
		{
			[self.tableView beginUpdates];
			[self.tableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];
			[self.tableView insertRowsAtIndexPaths:addIndexPaths withRowAnimation:UITableViewRowAnimationFade];
			[self.tableView endUpdates];
		}

		[self applyChangesAfterReload];
	});
}

- (void)reload
{
	[self reloadAnimated:YES];
}

- (void)reloadAnimated:(BOOL)animated
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
	{
		@synchronized(self)
		{
			BOOL needsReload = [self loadDownloads];

			if(needsReload)
			{
				if(animated)
				{
					[self applyChangesToTable];
				}
				else
				{
					dispatch_sync(dispatch_get_main_queue(), ^
					{
						[self.tableView reloadData];
						[self applyChangesAfterReload];
					});
				}
			}
		}
	});
}

- (BOOL)loadDownloads
{
	BOOL firstLoad = (_pendingDownloads == nil && _finishedDownloads == nil);

	_pendingDownloads = [downloadManager.pendingDownloads copy];
	_finishedDownloads = [downloadManager.finishedDownloads copy];

	if(firstLoad)
	{
		_displayedPendingDownloads = [_pendingDownloads copy];
		_displayedFinishedDownloads = [_finishedDownloads copy];
	}

	return !([_pendingDownloads isEqualToArray:_displayedPendingDownloads] && [_finishedDownloads isEqualToArray:_displayedFinishedDownloads]);
}

- (void)dismissButtonPressed
{
	//Dismiss controller
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addButtonPressed:(UIBarButtonItem*)sender
{
	UIAlertController* manualDownloadAlert = [UIAlertController alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"MANUAL_DOWNLOAD"]
						  message:@"" preferredStyle:UIAlertControllerStyleAlert];

	[manualDownloadAlert addTextFieldWithConfigurationHandler:^(UITextField* textField)
	{
		textField.placeholder = [localizationManager
					 localizedSPStringForKey:@"URL_TO_DOWNLOADABLE_FILE"];

		if([UIColor respondsToSelector:@selector(labelColor)])
		{
			textField.textColor = [UIColor labelColor];
		}
		else
		{
			textField.textColor = [UIColor blackColor];
		}
		textField.clearButtonMode = UITextFieldViewModeWhileEditing;
		textField.borderStyle = UITextBorderStyleNone;
	}];

	UIAlertAction* startAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"START_DOWNLOAD"] style:UIAlertActionStyleDefault handler:^(UIAlertAction*)
	{
		NSString* URLString = manualDownloadAlert.textFields.firstObject.text;
		NSURL* URL = [NSURL URLWithString:URLString];

		if(URL && URL.scheme && URL.host)
		{
			SPDownloadInfo* downloadInfo = [[SPDownloadInfo alloc] initWithRequest:[NSURLRequest requestWithURL:URL]];
			downloadInfo.presentationController = self.navigationController;
			downloadInfo.sourceRect = [[sender.view superview] convertRect:sender.view.frame toView:self.navigationController.view];
			[downloadManager prepareDownloadFromRequestForDownloadInfo:downloadInfo];
		}
	}];

	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CANCEL"] style:UIAlertActionStyleCancel handler:nil];

	[manualDownloadAlert addAction:startAction];
	[manualDownloadAlert addAction:cancelAction];

	[self.navigationController presentViewController:manualDownloadAlert animated:YES completion:nil];
}

- (void)clearButtonPressed
{
	UIAlertController* clearAlert = [UIAlertController alertControllerWithTitle:nil
					 message:nil preferredStyle:UIAlertControllerStyleActionSheet];

	UIAlertAction* cancelDownloadsAction = [UIAlertAction actionWithTitle:[localizationManager
									       localizedSPStringForKey:@"CANCEL_ALL_DOWNLOADS"] style:UIAlertActionStyleDestructive
						handler:^(UIAlertAction* action)
	{
		[downloadManager cancelAllDownloads];
	}];

	[clearAlert addAction:cancelDownloadsAction];

	UIAlertAction* clearHistoryAction = [UIAlertAction actionWithTitle:[localizationManager
									    localizedSPStringForKey:@"CLEAR_DOWNLOAD_HISTORY"] style:UIAlertActionStyleDestructive
					     handler:^(UIAlertAction* action)
	{
		[downloadManager clearDownloadHistory];
	}];

	[clearAlert addAction:clearHistoryAction];

	UIAlertAction* clearTempFilesAction = [UIAlertAction actionWithTitle:[localizationManager
									      localizedSPStringForKey:@"CLEAR_TEMPORARY_DATA"] style:UIAlertActionStyleDestructive
					       handler:^(UIAlertAction* action)
	{
		[downloadManager clearTempFilesIgnorePendingDownloads:YES];
	}];

	[clearAlert addAction:clearTempFilesAction];

	UIAlertAction* clearEverythingAction = [UIAlertAction actionWithTitle:[localizationManager
									       localizedSPStringForKey:@"CLEAR_EVERYTHING"] style:UIAlertActionStyleDestructive
						handler:^(UIAlertAction* action)
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
			[downloadManager cancelAllDownloads];
			[downloadManager clearDownloadHistory];
			[cacheManager clearDownloadCache];
			[downloadManager clearTempFiles];
			[fileManager resetHardLinks];
		}];

		[warningAlert addAction:yesAction];

		UIAlertAction* noAction = [UIAlertAction actionWithTitle:[localizationManager
									  localizedSPStringForKey:@"NO"]
					   style:UIAlertActionStyleCancel
					   handler:nil];

		[warningAlert addAction:noAction];

		[self presentViewController:warningAlert animated:YES completion:nil];
	}];

	[clearAlert addAction:clearEverythingAction];

	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[localizationManager
								      localizedSPStringForKey:@"CANCEL"]
				       style:UIAlertActionStyleCancel
				       handler:nil];

	[clearAlert addAction:cancelAction];

	UIView* buttonView = [self.navigationItem.leftBarButtonItem valueForKey:@"view"];

	UIPopoverPresentationController* popPresenter = [clearAlert popoverPresentationController];

	popPresenter.sourceView = buttonView;
	popPresenter.sourceRect = buttonView.bounds;

	[self.navigationController presentViewController:clearAlert animated:YES completion:nil];
}

- (void)restartDownload:(SPDownload*)download forCell:(SPDownloadListFinishedTableViewCell*)cell
{
	SPDownloadInfo* downloadInfo = [[SPDownloadInfo alloc] initWithDownload:download];
	downloadInfo.presentationController = self.navigationController;
	downloadInfo.sourceRect = [cell.buttonsView convertRect:cell.buttonsView.topButton.frame toView:self.navigationController.view];
	[downloadManager prepareDownloadFromRequestForDownloadInfo:downloadInfo];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch(section)
	{
	case 0:
		//return amount of pending downloads
		return [_pendingDownloads count];

	case 1:
		//return amount of finished downloads
		return [_finishedDownloads count];
	}

	return 0;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewAutomaticDimension;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if([self tableView:tableView numberOfRowsInSection:section] > 0)
	{
		switch(section)
		{
		case 0:
			return [localizationManager localizedSPStringForKey:@"PENDING_DOWNLOADS"];

		case 1:
			return [localizationManager localizedSPStringForKey:@"DOWNLOAD_HISTORY"];
		}
	}

	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch(indexPath.section)
	{
	case 0:
	{
		SPDownloadListTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"SPDownloadListTableViewCell"];

		if(!cell)
		{
			cell = [[SPDownloadListTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SPDownloadListTableViewCell"];
		}

		[cell applyDownload:_pendingDownloads[indexPath.row]];

		return cell;
	}
	case 1:
	{
		SPDownloadListFinishedTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"SPDownloadListFinishedTableViewCell"];

		if(!cell)
		{
			cell = [[SPDownloadListFinishedTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SPDownloadListFinishedTableViewCell"];
		}

		[cell applyDownload:_finishedDownloads[indexPath.row]];
		cell.tableViewController = self;

		return cell;
	}
	}

	return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == 1)
	{
		return YES;
	}

	return NO;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(editingStyle == UITableViewCellEditingStyleDelete && indexPath.section == 1)
	{
		[downloadManager removeDownloadFromHistory:_finishedDownloads[indexPath.row]];
	}
}

@end
