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

#import "SPDownloadBrowserTableViewController.h"

#import "../Defines.h"
#import "../Util.h"
#import "SPDownloadManager.h"
#import "SPDownloadTableViewCell.h"
#import "SPDownloadNavigationController.h"
#import "SPFileBrowserTableViewController.h"
#import "SPFileTableViewCell.h"
#import "SPLocalizationManager.h"
#import "SPCommunicationManager.h"
#import "SPFileManager.h"
#import "../../Shared/SPFile.h"

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVPlayerViewController.h>
#import <MobileCoreServices/MobileCoreServices.h>

@implementation SPDownloadBrowserTableViewController

- (void)setUpRightBarButtonItems
{
	[super setUpRightBarButtonItems];
	NSNumber* isWritable;

	[fileManager URLResourceValue:&isWritable forKey:NSURLIsWritableKey forURL:self.directoryURL error:nil];

	if([isWritable boolValue])
	{
		UIBarButtonItem* dismissItem = self.navigationItem.rightBarButtonItem;
		UIBarButtonItem* addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonPressed)];

		self.navigationItem.rightBarButtonItems = @[dismissItem, addItem];
	}
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	_filzaInstalled = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"filza://"]];

	[self.tableView registerClass:[SPDownloadTableViewCell class] forCellReuseIdentifier:@"SPDownloadTableViewCell"];
}

- (void)willMoveToParentViewController:(UIViewController *)parent
{
	[super willMoveToParentViewController:parent];
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0)
	{
		[(SPDownloadNavigationController*)self.navigationController applyPaletteToViewController:self];
	}
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
		//return amount of downloads at url
		return [self.downloadsAtCurrentURL count];
		break;

	case 1:
		//return amount of files at url
		return [self.filesAtCurrentURL count];
		break;

	default:
		return 0;
		break;
	}
}

- (BOOL)loadContents
{
	BOOL firstLoad = (self.downloadsAtCurrentURL == nil);

	//Populate download array
	NSMutableArray<SPDownload*>* newDownloads = [downloadManager downloadsAtURL:self.directoryURL];

	self.downloadsAtCurrentURL = [newDownloads copy];

	if(firstLoad)
	{
		self.displayedDownloads = [self.downloadsAtCurrentURL copy];
	}

	BOOL downloadsNeedUpdate = ![self.downloadsAtCurrentURL isEqualToArray:self.displayedDownloads];

	BOOL filesNeedUpdate = [super loadContents];

	return downloadsNeedUpdate || filesNeedUpdate;
}

- (NSMutableArray<NSIndexPath*>*)indexPathsToAdd
{
	NSMutableArray<NSIndexPath*>* addIndexPaths = [super indexPathsToAdd];

	if(!self.displayedDownloads)
	{
		return addIndexPaths;
	}

	NSMutableSet<SPDownload*>* oldDownloadsSet = [NSMutableSet setWithArray:self.displayedDownloads];
	NSMutableSet<SPDownload*>* newDownloadsSet = [NSMutableSet setWithArray:self.downloadsAtCurrentURL];

	[newDownloadsSet minusSet:oldDownloadsSet];

	for(SPDownload* download in newDownloadsSet)
	{
		[addIndexPaths addObject:[NSIndexPath indexPathForRow:[self.downloadsAtCurrentURL indexOfObject:download] inSection:0]];
	}

	return addIndexPaths;
}

- (NSMutableArray<NSIndexPath*>*)indexPathsToDelete
{
	NSMutableArray<NSIndexPath*>* deleteIndexPaths = [super indexPathsToDelete];

	if(!self.displayedDownloads)
	{
		return deleteIndexPaths;
	}

	NSMutableSet<SPDownload*>* currentDownloadsSet = [NSMutableSet setWithArray:self.downloadsAtCurrentURL];
	NSMutableSet<SPDownload*>* finishedDownloadsSet = [NSMutableSet setWithArray:self.displayedDownloads];

	[finishedDownloadsSet minusSet:currentDownloadsSet];

	for(SPDownload* download in finishedDownloadsSet)
	{
		[deleteIndexPaths addObject:[NSIndexPath indexPathForRow:[self.displayedDownloads indexOfObject:download] inSection:0]];
	}

	return deleteIndexPaths;
}

- (void)applyChangesAfterReload
{
	self.displayedDownloads = [self.downloadsAtCurrentURL copy];

	[super applyChangesAfterReload];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if([self tableView:tableView numberOfRowsInSection:0] > 0)
	{
		switch(section)
		{
		case 0:
			return [localizationManager localizedSPStringForKey:@"PENDING_DOWNLOADS"];
			break;

		case 1:
			return [localizationManager localizedSPStringForKey:@"FILES"];
			break;
		}
	}

	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == 0)
	{
		SPDownload* currentDownload = self.downloadsAtCurrentURL[indexPath.row];

		SPDownloadTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"SPDownloadTableViewCell"];

		if(!cell)
		{
			cell = [[SPDownloadTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SPDownloadTableViewCell"];
		}

		[cell applyDownload:currentDownload];

		//Return cell for download
		return cell;
	}

	return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == 0)
	{
		//Download cells should not be edititable
		return NO;
	}

	return [super tableView:tableView canEditRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section != 0)
	{
		//Make download cells unselectable
		[super tableView:tableView didSelectRowAtIndexPath:indexPath];
	}
}

- (void)unselectRow
{
	NSIndexPath* selectedIndexPath = [self.tableView indexPathForSelectedRow];
	if(selectedIndexPath)
	{
		[self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
	}
}

//https://useyourloaf.com/blog/openurl-deprecated-in-ios10/
- (void)openScheme:(NSString *)scheme
{
	UIApplication* application = [UIApplication sharedApplication];
	NSURL* URL = [NSURL URLWithString:scheme];

	if([application respondsToSelector:@selector(openURL:options:completionHandler:)])
	{
		[application openURL:URL options:@{} completionHandler:nil];
	}
	else
	{
		[application openURL:URL];
	}
}

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller;
{
	return _previewFiles.count;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index
{
	NSURL* fileURL = [_previewFiles objectAtIndex:index].fileURL;
	return [fileManager accessibleHardLinkForFileAtURL:fileURL forced:NO];
}

- (void)previewControllerDidDismiss:(QLPreviewController *)controller
{
	_previewFiles = nil;
	self.previewController = nil;

	[self unselectRow];
	[fileManager resetHardLinks];
}

- (void)didSelectFile:(SPFile*)file atIndexPath:(NSIndexPath*)indexPath
{
	if([file displaysAsRegularFile])
	{
		//Only cache one hard link at most
		[fileManager resetHardLinks];

		//Create alertSheet for tapped file
		UIAlertController *openAlert = [UIAlertController alertControllerWithTitle:file.name
			message:nil preferredStyle:UIAlertControllerStyleActionSheet];

		if([file conformsTo:kUTTypeAudiovisualContent] || [file isHLSStream])
		{
			//File is audio or video -> Add option to play file
			[openAlert addAction:[self playActionForFile:file]];
		}

		if(file.isPreviewable)
		{
			[openAlert addAction:[self previewActionForFile:file]];
		}

		if(!file.isRegularFile)
		{
			[openAlert addAction:[self showContentActionForFile:file withIndexPath:indexPath]];
		}

		NSURL* hardLinkedURL;

		if([file conformsTo:kUTTypeAudiovisualContent] || [file isHLSStream])
		{
			hardLinkedURL = [fileManager accessibleHardLinkForFileAtURL:file.fileURL forced:NO];
		}

		if([file isHLSStream])
		{
			NSString* extension = [downloadManager fileTypeOfMovpkgAtURL:hardLinkedURL];
			
			if(![extension isEqualToString:@""])
			{
				[openAlert addAction:[self mergeActionForFile:file withTargetExtension:extension]];
			}
		}

		[openAlert addAction:[self openInActionForFile:file]];

		if([file conformsTo:kUTTypeAudiovisualContent] || [file conformsTo:kUTTypeImage])
		{
			if([file conformsTo:kUTTypeAudiovisualContent])
			{
				if(UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(hardLinkedURL.path)) //This can take more than a second on larger files
				{
					[openAlert addAction:[self importToMediaLibraryActionForVideoWithURL:file.fileURL]];
				}
			}
			else
			{
				[openAlert addAction:[self importToMediaLibraryActionForImageWithURL:file.fileURL]];
			}
		}

		if(hardLinkedURL)
		{
			[fileManager resetHardLinks];
		}

		if(_filzaInstalled)
		{
			//Filza is installed -> add 'Show in Filza' option
			[openAlert addAction:[self showInFilzaActionForFile:file]];
		}

		if(file.isWritable)
		{
			//Add rename option
			[openAlert addAction:[self renameActionForFile:file]];

			//Add delete option
			[openAlert addAction:[self deleteActionForFile:file]];
		}

		//Add cancel option
		UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CANCEL"]
			style:UIAlertActionStyleCancel handler:^(UIAlertAction * action)
		{
			[self unselectRow];
		}];

		[openAlert addAction:cancelAction];

		//iPad fix (Set position of open alert to row in table)
		CGRect cellRect = [self.tableView rectForRowAtIndexPath:indexPath];
		openAlert.popoverPresentationController.sourceView = self.tableView;
		openAlert.popoverPresentationController.sourceRect = CGRectMake(cellRect.size.width / 2.0, cellRect.origin.y + cellRect.size.height / 2, 1.0, 1.0);

		//Present open alert
		[self presentViewController:openAlert animated:YES completion:nil];
	}

	[super didSelectFile:file atIndexPath:indexPath];
}

//Downloads are section 0, files are section 1
- (NSInteger)fileSection
{
	return 1;
}

- (void)didLongPressFile:(SPFile*)file atIndexPath:(NSIndexPath*)indexPath
{
	if(![file displaysAsRegularFile])
	{
		if(file.isWritable || _filzaInstalled)
		{
			//Create alertSheet for tapped file
			UIAlertController* longPressAlert = [UIAlertController alertControllerWithTitle:file.name
							     message:nil preferredStyle:UIAlertControllerStyleActionSheet];

			if(_filzaInstalled)
			{
				//Filza is installed -> add 'Show in Filza' option
				[longPressAlert addAction:[self showInFilzaActionForFile:file]];
			}

			if(file.isWritable)
			{
				//Add rename option
				[longPressAlert addAction:[self renameActionForFile:file]];

				//Add delete option
				[longPressAlert addAction:[self deleteActionForFile:file]];
			}

			//Add cancel option
			UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CANCEL"]
						       style:UIAlertActionStyleCancel handler:nil];

			[longPressAlert addAction:cancelAction];

			//iPad fix (Set position of open alert to row in table)
			CGRect cellRect = [self.tableView rectForRowAtIndexPath:indexPath];
			longPressAlert.popoverPresentationController.sourceView = self.tableView;
			longPressAlert.popoverPresentationController.sourceRect = CGRectMake(cellRect.size.width / 2.0, cellRect.origin.y + cellRect.size.height / 2, 1.0, 1.0);

			//Present open alert
			[self presentViewController:longPressAlert animated:YES completion:nil];
		}
	}
}

- (UIAlertAction*)previewActionForFile:(SPFile*)file
{
	return [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"PREVIEW"]
		style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
	{
		_previewFiles = [self.filesAtCurrentURL filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL (id evaluatedObject, NSDictionary<NSString *,id>* bindings)
		{
			SPFile* file = evaluatedObject;
			return file.isPreviewable;
		}]];

		self.previewController = [[QLPreviewController alloc] init];
		self.previewController.dataSource = self;
		self.previewController.delegate = self;
		self.previewController.currentPreviewItemIndex = [_previewFiles indexOfObject:file];

		[self.navigationController presentViewController:self.previewController animated:YES completion:nil];
	}];
}

- (UIAlertAction*)playActionForFile:(SPFile*)file
{
	return [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"PLAY"]
		style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
	{
		NSURL* hardLinkedURL = [fileManager accessibleHardLinkForFileAtURL:file.fileURL forced:NO];
		[self startPlayerWithMedia:hardLinkedURL];
	}];
}

- (UIAlertAction*)showContentActionForFile:(SPFile*)file withIndexPath:(NSIndexPath*)indexPath
{
	return [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"SHOW_CONTENT"]
		style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
	{
		[super didSelectFile:file atIndexPath:indexPath];
	}];
}

- (UIAlertAction*)mergeActionForFile:(SPFile*)file withTargetExtension:(NSString*)targetExtension
{
	return [UIAlertAction actionWithTitle:[NSString stringWithFormat:[localizationManager localizedSPStringForKey:@"MERGE_INTO_FILE"], targetExtension]
		style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
	{
		NSURL* hardLinkedURL = [fileManager accessibleHardLinkForFileAtURL:file.fileURL forced:NO];
		NSURL* targetURL = [[[file fileURL] URLByDeletingPathExtension] URLByAppendingPathExtension:targetExtension];

		void (^performMerge)(void) = ^
		{
			UIAlertController* mergingActivityController = [UIAlertController alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"MERGING"] message:@"" preferredStyle:UIAlertControllerStyleAlert];
			UIActivityIndicatorView* activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(10,5,50,50)];
			activityIndicator.hidesWhenStopped = YES;
			activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
			[activityIndicator startAnimating];
			[mergingActivityController.view addSubview:activityIndicator];

			[self.navigationController presentViewController:mergingActivityController animated:YES completion:nil];

			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
			{
				[downloadManager mergeMovpkgAtURL:hardLinkedURL toFileAtURL:targetURL];

				dispatch_async(dispatch_get_main_queue(), ^
				{
					[fileManager resetHardLinks];
					[mergingActivityController dismissViewControllerAnimated:YES completion:nil];
					[self unselectRow];
					[self reload];
				});
			});
		};

		if(![fileManager fileExistsAtURL:targetURL error:nil])
		{
			if([targetExtension isEqualToString:@"ts"])
			{
				UIAlertController* mergingActivityController = [UIAlertController alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"NOTICE"] message:[localizationManager localizedSPStringForKey:@"TS_NOTICE_MESSAGE"] preferredStyle:UIAlertControllerStyleAlert];

				UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CANCEL"] style:UIAlertActionStyleCancel handler:^(UIAlertAction* action)
				{
					[self unselectRow];
				}];

				UIAlertAction* mergeAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"MERGE"] style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
				{
					performMerge();
				}];

				[mergingActivityController addAction:cancelAction];
				[mergingActivityController addAction:mergeAction];

				[self.navigationController presentViewController:mergingActivityController animated:YES completion:nil];
			}
			else
			{
				performMerge();
			}
		}
		else
		{
			UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"ERROR"] message:[NSString stringWithFormat:[localizationManager localizedSPStringForKey:@"MERGE_FILE_EXISTS_ERROR"], targetURL.lastPathComponent] preferredStyle:UIAlertControllerStyleAlert];

			UIAlertAction* closeAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CLOSE"] style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
			{
				[self unselectRow];
			}];

			[errorAlert addAction:closeAction];

			[self.navigationController presentViewController:errorAlert animated:YES completion:nil];
		}
	}];
}

- (UIAlertAction*)openInActionForFile:(SPFile*)file
{
	return [UIAlertAction actionWithTitle:[localizationManager
			localizedSPStringForKey:@"OPEN_IN"]
		style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
	{
		NSURL* hardLinkedURL = [fileManager accessibleHardLinkForFileAtURL:file.fileURL forced:YES];

		//Create documentController from selected file and present it
		self.documentController = [UIDocumentInteractionController interactionControllerWithURL:hardLinkedURL];
		self.documentController.delegate = self;

		[self.documentController presentOpenInMenuFromRect:CGRectZero inView:self.view animated:YES];
	}];
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
	[self unselectRow];
	//[fileManager resetHardLinks];
}

//We use the lowest level api here because PHPhotoLibrary requires a description key that I cannot provide, I'm suprised that this actually works (it probably does because Safari has an entitlement)
- (UIAlertAction*)importToMediaLibraryActionForImageWithURL:(NSURL*)URL
{
	return [UIAlertAction actionWithTitle:[localizationManager
			localizedSPStringForKey:@"SAVE_TO_MEDIA_LIBRARY"]
		style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
	{
		NSURL* hardLinkedURL = [fileManager accessibleHardLinkForFileAtURL:URL forced:NO];
		UIImage* image = [UIImage imageWithContentsOfFile:hardLinkedURL.path];
		UIImageWriteToSavedPhotosAlbum(image, self, @selector(mediaImport:didFinishSavingWithError:contextInfo:), nil);
		[self unselectRow];
	}];
}

- (UIAlertAction*)importToMediaLibraryActionForVideoWithURL:(NSURL*)URL
{
	return [UIAlertAction actionWithTitle:[localizationManager
			localizedSPStringForKey:@"SAVE_TO_MEDIA_LIBRARY"]
		style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
	{
		NSURL* hardLinkedURL = [fileManager accessibleHardLinkForFileAtURL:URL forced:NO];
		UISaveVideoAtPathToSavedPhotosAlbum(hardLinkedURL.path, self, @selector(mediaImport:didFinishSavingWithError:contextInfo:), nil);
		[self unselectRow];
	}];
}

- (void)mediaImport:(NSString*)path didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo
{
	[fileManager resetHardLinks];
}

- (UIAlertAction*)showInFilzaActionForFile:(SPFile*)file
{
	return [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"SHOW_IN_FILZA"]
		style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
	{
		//https://stackoverflow.com/a/32145122
		NSString* filzaPath = [NSString stringWithFormat:@"%@%@", @"filza://view", [file.fileURL.path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]];
		[self openScheme:filzaPath];
	}];
}

- (UIAlertAction*)renameActionForFile:(SPFile*)file
{
	NSString* title;

	if(file.isRegularFile)
	{
		title = [localizationManager localizedSPStringForKey:@"RENAME_FILE"];
	}
	else
	{
		title = [localizationManager localizedSPStringForKey:@"RENAME_DIRECTORY"];
	}

	return [UIAlertAction actionWithTitle:title
		style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
	{
		UIAlertController* selectFilenameController = [UIAlertController
							       alertControllerWithTitle:title
							       message:nil
							       preferredStyle:UIAlertControllerStyleAlert];

		[selectFilenameController addTextFieldWithConfigurationHandler:^(UITextField *textField)
		{
			textField.text = file.name;
			if(file.isRegularFile)
			{
				textField.placeholder = [localizationManager localizedSPStringForKey:@"FILENAME"];
			}
			else
			{
				textField.placeholder = [localizationManager localizedSPStringForKey:@"DIRECTORY_NAME"];
			}
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

		//Add cancel option
		UIAlertAction *cancelAction = [UIAlertAction
					       actionWithTitle:[localizationManager localizedSPStringForKey:@"CANCEL"]
					       style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
		{
			[self unselectRow];
		}];

		[selectFilenameController addAction:cancelAction];

		//Add rename option
		UIAlertAction* confirmRenameAction = [UIAlertAction
						      actionWithTitle:[localizationManager localizedSPStringForKey:@"RENAME"]
						      style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
		{
			//Rename file
			[fileManager moveItemAtURL:file.fileURL toURL:[[file.fileURL URLByDeletingLastPathComponent]
								       URLByAppendingPathComponent:selectFilenameController.textFields[0].text] error:nil];

			//Reload files
			[self reload];
		}];

		[selectFilenameController addAction:confirmRenameAction];

		//Make rename option bold if available
		if([selectFilenameController respondsToSelector:@selector(preferredAction)])
		{
			selectFilenameController.preferredAction = confirmRenameAction;
		}

		[self presentViewController:selectFilenameController animated:YES completion:nil];
	}];
}

- (UIAlertAction*)deleteActionForFile:(SPFile*)file
{
	NSString* title, *message;

	if(file.isRegularFile)
	{
		title = [localizationManager localizedSPStringForKey:@"DELETE_FILE"];
		message = [localizationManager localizedSPStringForKey:@"DELETE_FILE_MESSAGE"];
	}
	else
	{
		title = [localizationManager localizedSPStringForKey:@"DELETE_DIRECTORY"];
		message = [localizationManager localizedSPStringForKey:@"DELETE_DIRECTORY_MESSAGE"];
	}

	return [UIAlertAction actionWithTitle:title
		style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action)
	{
		//Create alert to confirm deletion of file
		UIAlertController* confirmationController = [UIAlertController
			alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"WARNING"]
			message:[NSString stringWithFormat:message, file.name]
			preferredStyle:UIAlertControllerStyleAlert];

		//Add cancel option
		UIAlertAction *cancelAction = [UIAlertAction
			actionWithTitle:[localizationManager localizedSPStringForKey:@"CANCEL"]
			style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
		{
			[self unselectRow];
		}];

		[confirmationController addAction:cancelAction];

		//Add delete option
		UIAlertAction *deleteAction = [UIAlertAction
			actionWithTitle:[localizationManager localizedSPStringForKey:@"DELETE"]
			style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action)
		{
			//Delete file
			[fileManager removeItemAtURL:file.fileURL error:nil];

			//Reload files
			[self reload];
		}];

		[confirmationController addAction:deleteAction];

		//Make cancel option bold if available
		if([confirmationController respondsToSelector:@selector(preferredAction)])
		{
			confirmationController.preferredAction = cancelAction;
		}

		//Present confirmation alert
		[self presentViewController:confirmationController animated:YES completion:nil];
	}];
}

- (void)startPlayerWithMedia:(NSURL*)mediaURL
{
	//Enable Background Audio
	[[AVAudioSession sharedInstance] setActive:YES error:nil];
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];

	//Create AVPlayer from media file
	AVPlayer* player = [AVPlayer playerWithURL:mediaURL];

	//Create AVPlayerController
	AVPlayerViewController* playerViewController = [AVPlayerViewController new];

	//Link AVPlayer and AVPlayerController
	playerViewController.player = player;

	//Present AVPlayerController
	[self presentViewController:playerViewController animated:YES completion:^
	{
		//Start playing when player is presented
		[player play];
	}];
}

- (void)addButtonPressed
{
	UIAlertController* createDirectoryAlert = [UIAlertController alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"CREATE_DIRECTORY"]
		message:nil preferredStyle:UIAlertControllerStyleAlert];

	[createDirectoryAlert addTextFieldWithConfigurationHandler:^(UITextField* textField)
	{
		textField.placeholder = [localizationManager
			localizedSPStringForKey:@"DIRECTORY_NAME"];

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

	UIAlertAction* createAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CREATE"] style:UIAlertActionStyleDefault
		handler:^(UIAlertAction* action)
	{
		NSURL* selectedURL = [self.directoryURL URLByAppendingPathComponent:createDirectoryAlert.textFields.firstObject.text];

		NSError* error;
		[fileManager createDirectoryAtURL:selectedURL withIntermediateDirectories:NO attributes:nil error:&error];

		if(!error)
		{
			[self reload];
		}
		else
		{
			UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"ERROR"]
							 message:[error localizedDescription]
							 preferredStyle:UIAlertControllerStyleAlert];

			UIAlertAction* closeAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CLOSE"] style:UIAlertActionStyleCancel handler:nil];

			[errorAlert addAction:closeAction];

			[self presentViewController:errorAlert animated:YES completion:nil];
		}
	}];
	[createDirectoryAlert addAction:createAction];

	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CANCEL"] style:UIAlertActionStyleCancel handler:nil];
	[createDirectoryAlert addAction:cancelAction];

	[self presentViewController:createDirectoryAlert animated:YES completion:nil];
}

@end
