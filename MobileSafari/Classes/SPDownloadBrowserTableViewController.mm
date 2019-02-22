// SPDownloadBrowserTableViewController.mm
// (c) 2019 opa334

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

#import "SPDownloadBrowserTableViewController.h"

#import "../Defines.h"
#import "../Shared.h"
#import "SPDownloadManager.h"
#import "SPDownloadTableViewCell.h"
#import "SPDownloadNavigationController.h"
#import "SPFileBrowserTableViewController.h"
#import "SPFileTableViewCell.h"
#import "SPLocalizationManager.h"
#import "SPCommunicationManager.h"
#import "SPFileManager.h"
#import "SPFile.h"

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVPlayerViewController.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>

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
	//Populate download array
	NSMutableArray<SPDownload*>* newDownloads = [downloadManager downloadsAtURL:self.directoryURL];

	BOOL downloadsNeedUpdate = ![newDownloads isEqualToArray:self.downloadsAtCurrentURL];

	if(downloadsNeedUpdate)
	{
		self.downloadsAtCurrentURL = newDownloads;
	}

	BOOL filesNeedUpdate = [super loadContents];

	return downloadsNeedUpdate || filesNeedUpdate;
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

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch(indexPath.section)
	{
	case 0:
		return 66.0;

	default:
		return UITableViewAutomaticDimension;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
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

- (void)didSelectFile:(SPFile*)file atIndexPath:(NSIndexPath*)indexPath
{
	if(file.isRegularFile)
	{
		//Only cache one hard link at most
		[fileManager resetHardLinks];

		//Create alertSheet for tapped file
		UIAlertController *openAlert = [UIAlertController alertControllerWithTitle:file.name
						message:nil preferredStyle:UIAlertControllerStyleActionSheet];

		if([file conformsTo:kUTTypeAudiovisualContent])
		{
			//File is audio or video -> Add option to play file
			[openAlert addAction:[self playActionForFile:file]];
		}

		/*if([file conformsTo:kUTTypeAudio])
		   {
		   //File is audio -> Add option to import to library
		   [openAlert addAction:[self importToMusicLibraryActionForFile:file]];
		   }*/

		[openAlert addAction:[self openInActionForFile:file]];

		if([file conformsTo:kUTTypeAudiovisualContent] || [file conformsTo:kUTTypeImage])
		{
			NSURL* hardLinkedURL = [fileManager accessibleHardLinkForFileAtURL:file.fileURL forced:NO];

			if([file conformsTo:kUTTypeAudiovisualContent])
			{
				if(UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(hardLinkedURL.path))
				{
					[openAlert addAction:[self importToMediaLibraryActionForVideoWithURL:hardLinkedURL]];
				}
				else
				{
					[fileManager removeItemAtURL:hardLinkedURL error:nil];
				}
			}
			else
			{
				[openAlert addAction:[self importToMediaLibraryActionForImageWithURL:hardLinkedURL]];
			}
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
			[fileManager resetHardLinks];
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
	if(!file.isRegularFile)
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

- (UIAlertAction*)playActionForFile:(SPFile*)file
{
	return [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"PLAY"]
		style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
	{
		NSURL* hardLinkedURL = [fileManager accessibleHardLinkForFileAtURL:file.fileURL forced:NO];
		[self startPlayerWithMedia:hardLinkedURL];
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
		UIImage* image = [UIImage imageWithContentsOfFile:URL.path];
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
		UISaveVideoAtPathToSavedPhotosAlbum(URL.path, self, @selector(mediaImport:didFinishSavingWithError:contextInfo:), nil);
		[self unselectRow];
	}];
}

- (void)mediaImport:(NSString*)path didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo
{
	[fileManager resetHardLinks];
}

/*- (UIAlertAction*)importToMusicLibraryActionForFile:(SPFile*)file
   {
   return [UIAlertAction actionWithTitle:[localizationManager
    localizedSPStringForKey:@"IMPORT_TO_MUSIC_LIBRARY"]
    style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
   {

   }];
   }*/

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
			textField.textColor = [UIColor blackColor];
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
								       URLByAppendingPathComponent:selectFilenameController.textFields[0].text]
			 error:nil];

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

		textField.textColor = [UIColor blackColor];
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
