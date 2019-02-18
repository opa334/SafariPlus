// SPDownloadListTableViewController.mm
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

#import "SPDownloadListTableViewController.h"

#import "SPDownloadListTableViewCell.h"
#import "SPDownloadListFinishedTableViewCell.h"
#import "SPDownload.h"
#import "../Shared.h"
#import "../Classes/SPLocalizationManager.h"
#import "../Classes/SPDownloadManager.h"
#import "../Classes/SPCacheManager.h"
#import "../Classes/SPFileManager.h"
#import "../SafariPlus.h"

@implementation SPDownloadListTableViewController

- (instancetype)init
{
	self = [super init];

	[self loadDownloads];

	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[localizationManager
											 localizedSPStringForKey:@"DISMISS"] style:UIBarButtonItemStylePlain
						  target:self action:@selector(dismissButtonPressed)];

	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[localizationManager
											localizedSPStringForKey:@"CLEAR"] style:UIBarButtonItemStylePlain
						 target:self action:@selector(clearButtonPressed)];

	self.title = [localizationManager localizedSPStringForKey:@"DOWNLOAD_OVERVIEW"];

	self.tableView.allowsMultipleSelectionDuringEditing = NO;

	[self.tableView registerClass:[SPDownloadListTableViewCell class] forCellReuseIdentifier:@"SPDownloadListTableViewCell"];
	[self.tableView registerClass:[SPDownloadListFinishedTableViewCell class] forCellReuseIdentifier:@"SPDownloadListFinishedTableViewCell"];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[self fixFooterColors];
}

- (void)reload
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
	{
		//Repopulate dataSources
		BOOL needsReload = [self loadDownloads];

		if(needsReload)
		{
			//Reload tableView with new dataSources
			NSRange range = NSMakeRange(0, [self numberOfSectionsInTableView:self.tableView]);
			NSIndexSet* sections = [NSIndexSet indexSetWithIndexesInRange:range];

			dispatch_async(dispatch_get_main_queue(), ^
			{
				[self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationFade];
			});
		}
	});
}

- (BOOL)loadDownloads
{
	NSArray* newPendingDownloads = [downloadManager.pendingDownloads copy];
	NSArray* newFinishedDownloads = [downloadManager.finishedDownloads copy];

	BOOL downloadsNeedUpdate = !([_pendingDownloads isEqualToArray:newPendingDownloads] && [_finishedDownloads isEqualToArray:newFinishedDownloads]);

	if(downloadsNeedUpdate)
	{
		_pendingDownloads = newPendingDownloads;
		_finishedDownloads = newFinishedDownloads;
	}

	return downloadsNeedUpdate;
}

- (void)dismissButtonPressed
{
	//Dismiss controller
	[self dismissViewControllerAnimated:YES completion:nil];
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

- (void)restartDownload:(SPDownload*)download
{
	[self dismissViewControllerAnimated:YES completion:^
	{
		BrowserController* browserController = browserControllers().firstObject;

		if([browserController respondsToSelector:@selector(loadURLInNewTab:inBackground:)])
		{
			[browserController loadURLInNewTab:download.request.URL inBackground:NO];
		}
		else
		{
			[browserController loadURLInNewWindow:download.request.URL inBackground:NO];
		}
	}];
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
	switch(indexPath.section)
	{
	case 0:
		return 88.0;

	case 1:
		return 60.5;

	default:
		return UITableViewAutomaticDimension;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
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
