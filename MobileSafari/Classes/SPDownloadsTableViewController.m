// SPDownloadsTableViewController.m
// (c) 2017 opa334

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

#import "SPDownloadsTableViewController.h"

#import "../Shared.h"
#import "SPDownloadManager.h"
#import "SPDownloadTableViewCell.h"
#import "SPFileBrowserTableViewController.h"
#import "SPFileTableViewCell.h"
#import "SPLocalizationManager.h"
#import "SPFileManager.h"

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVPlayerViewController.h>
#import <MobileCoreServices/MobileCoreServices.h>

@implementation SPDownloadsTableViewController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  switch(section)
  {
    case 0:
    //return amount of downloads at path
    return [self.downloadsAtCurrentPath count];
    break;

    case 1:
    //return amount of files at path
    return [_filesAtCurrentPath count];
    break;

    default:
    return 0;
    break;
  }
}

- (void)populateDataSources
{
  [super populateDataSources];

  //Repopulate download array
  self.downloadsAtCurrentPath = [downloadManager downloadsAtPath:self.currentPath];
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

      default:
      return nil;
      break;
    }
  }
  else
  {
    return nil;
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  switch(indexPath.section)
  {
    case 0:
    {
      //Return downloadCells
      SPDownload* currentDownload = self.downloadsAtCurrentPath[indexPath.row];
      SPDownloadTableViewCell* cell = [self newCellWithDownload:currentDownload];
      return cell;
      break;
    }

    case 1:
    {
      //Return fileCells
      return (SPFileTableViewCell*)[super tableView:tableView cellForRowAtIndexPath:indexPath];
      break;
    }

    default:
    return nil;
    break;
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  if(indexPath.section == 0)
  {
    //Return 66.0, because downloadCells need more space
    return 66.0;
  }
  else
  {
    //Return default height
    return tableView.rowHeight;
  }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  if(indexPath.section == 1)
  {
    //File cells are editable
    return [super tableView:tableView canEditRowAtIndexPath:indexPath];
  }
  else
  {
    //Download cells are not edititable
    return NO;
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if(indexPath.section != 0)
  {
    //Make download cells unselectable
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
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

- (void)selectedFileAtPath:(NSString*)filePath type:(NSInteger)type atIndexPath:(NSIndexPath*)indexPath
{
  //Type 1: file; type 2: symlink; type 3: directory
  if(type == 1)
  {
    //Only cache one hard link at most
    [fileManager resetHardLinks];

    __block NSString* hardLinkedPath;

    //Check if Filza is installed
    BOOL filzaInstalled = [fileManager fileExistsAtPath:@"/Applications/Filza.app"];

    //Get filename for title
    NSString* filename = [[filePath lastPathComponent] stringByRemovingPercentEncoding];

    //Create alertSheet for tapped file
    UIAlertController *openAlert = [UIAlertController alertControllerWithTitle:filename
      message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    //Get fileUTI
    CFStringRef fileExtension = (__bridge CFStringRef)[filePath pathExtension];
    CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(
      kUTTagClassFilenameExtension, fileExtension, NULL);

    if(UTTypeConformsTo(fileUTI, kUTTypeMovie) || UTTypeConformsTo(fileUTI, kUTTypeAudio))
    {
      //File is audio or video -> Add option to play file
      UIAlertAction* playAction = [UIAlertAction
        actionWithTitle:[localizationManager localizedSPStringForKey:@"PLAY"]
        style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
      {
        hardLinkedPath = [fileManager createHardLinkForFileAtPath:filePath onlyIfNeeded:YES];
        [self startPlayerWithMedia:[NSURL fileURLWithPath:hardLinkedPath]];
      }];

      [openAlert addAction:playAction];
    }

    UIAlertAction* openInAction = [UIAlertAction actionWithTitle:[localizationManager
      localizedSPStringForKey:@"OPEN_IN"]
      style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
    {
      hardLinkedPath = [fileManager createHardLinkForFileAtPath:filePath onlyIfNeeded:NO];

      //Create documentController from selected file and present it
      self.documentController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:hardLinkedPath]];

      [self.documentController presentOpenInMenuFromRect:CGRectZero inView:self.view animated:YES];
    }];

    [openAlert addAction:openInAction];

    if(filzaInstalled)
    {
      //Filza is installed -> add 'Show in Filza' option
      UIAlertAction* showInFilzaAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"SHOW_IN_FILZA"]
        style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
      {
        //https://stackoverflow.com/a/32145122
        NSString* filzaPath = [NSString stringWithFormat:@"%@%@", @"filza://view", filePath];
        [self openScheme:filzaPath];
      }];

      [openAlert addAction:showInFilzaAction];
    }

    //Add rename option
    UIAlertAction* renameAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"RENAME_FILE"]
      style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
    {
      UIAlertController* selectFilenameController = [UIAlertController
        alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"RENAME_FILE"]
        message:nil
        preferredStyle:UIAlertControllerStyleAlert];

      [selectFilenameController addTextFieldWithConfigurationHandler:^(UITextField *textField)
      {
        textField.text = filename;
        textField.placeholder = [localizationManager localizedSPStringForKey:@"FILENAME"];
        textField.textColor = [UIColor blackColor];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleNone;
      }];

      //Add cancel option
      UIAlertAction *cancelAction = [UIAlertAction
        actionWithTitle:[localizationManager localizedSPStringForKey:@"CANCEL"]
        style:UIAlertActionStyleDefault handler:nil];

      [selectFilenameController addAction:cancelAction];

      //Add rename option
      UIAlertAction* confirmRenameAction = [UIAlertAction
        actionWithTitle:[localizationManager localizedSPStringForKey:@"RENAME"]
        style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
      {
        //Rename file
        [fileManager moveItemAtPath:filePath toPath:[[filePath
          stringByDeletingLastPathComponent]
          stringByAppendingPathComponent:selectFilenameController.textFields[0].text]
          error:nil];

        //Reload files
        [self reloadDataAndDataSources];
      }];

      [selectFilenameController addAction:confirmRenameAction];

      //Make rename option bold on iOS 9 and above
      if(iOSVersion > 8)
      {
        selectFilenameController.preferredAction = confirmRenameAction;
      }

      [self presentViewController:selectFilenameController animated:YES completion:nil];
    }];

    [openAlert addAction:renameAction];

    //Add delete option
    UIAlertAction* deleteAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"DELETE_FILE"]
      style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action)
    {
      //Create alert to confirm deletion of file
      UIAlertController* confirmationController = [UIAlertController
        alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"WARNING"]
        message:[NSString stringWithFormat:[localizationManager localizedSPStringForKey:@"DELETE_FILE_MESSAGE"], filename]
        preferredStyle:UIAlertControllerStyleAlert];

      //Add cancel option
      UIAlertAction *cancelAction = [UIAlertAction
        actionWithTitle:[localizationManager localizedSPStringForKey:@"CANCEL"]
        style:UIAlertActionStyleDefault handler:nil];

      [confirmationController addAction:cancelAction];

      //Add delete option
      UIAlertAction *deleteAction = [UIAlertAction
        actionWithTitle:[localizationManager localizedSPStringForKey:@"DELETE"]
        style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action)
      {
        //Delete file
        [fileManager removeItemAtPath:filePath error:nil];

        //Reload files
        [self reloadDataAndDataSources];
      }];

      [confirmationController addAction:deleteAction];

      //Make cancel option bold on iOS 9 and above
      if(iOSVersion >= 9)
      {
        confirmationController.preferredAction = cancelAction;
      }

      //Present confirmation alert
      [self presentViewController:confirmationController animated:YES completion:nil];
    }];

    [openAlert addAction:deleteAction];

    //Add cancel option
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CANCEL"]
          style:UIAlertActionStyleCancel handler:nil];

    [openAlert addAction:cancelAction];

    //iPad fix (Set position of open alert to row in table)
    CGRect cellRect = [self.tableView rectForRowAtIndexPath:indexPath];
    openAlert.popoverPresentationController.sourceView = self.tableView;
    openAlert.popoverPresentationController.sourceRect = CGRectMake(cellRect.size.width / 2.0, cellRect.origin.y + cellRect.size.height / 2, 1.0, 1.0);

    //Present open alert
    [self presentViewController:openAlert animated:YES completion:nil];
  }
  [super selectedFileAtPath:filePath type:type atIndexPath:indexPath];
}

- (void)startPlayerWithMedia:(NSURL*)mediaURL
{
  //Enable Background Audio
  [[AVAudioSession sharedInstance] setActive:YES error:nil];
  [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];

  //Create AVPlayer from media file
  AVPlayer* player = [AVPlayer playerWithURL:mediaURL];

  //Create AVPlayerController
  AVPlayerViewController *playerViewController = [AVPlayerViewController new];

  //Link AVPlayer and AVPlayerController
  playerViewController.player = player;

  //Present AVPlayerController
  [self presentViewController:playerViewController animated:YES completion:^
  {
    //Start playing when player is presented
    [player play];
  }];
}

- (id)newCellWithDownload:(SPDownload*)download
{
  //Return instance of SPDownloadTableViewCell
  return [[SPDownloadTableViewCell alloc] initWithDownload:download];
}

@end
