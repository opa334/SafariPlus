//  SPDownloadsTableViewController.xm
// (c) 2017 opa334

#import "SPDownloadsTableViewController.h"

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
    return [filesAtCurrentPath count];
    break;

    default:
    return 0;
    break;
  }
}

- (void)populateDataSources
{
  [super populateDataSources];

  //Create new array for downloads and populate it
  self.downloadsAtCurrentPath = [NSMutableArray new];
  self.downloadsAtCurrentPath = [[SPDownloadManager sharedInstance] downloadsAtURL:self.currentPath];
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
    //File cells editable
    return [super tableView:tableView canEditRowAtIndexPath:indexPath];
  }
  else
  {
    //Download cells not edititable
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

- (void)selectedFileAtURL:(NSURL*)fileURL type:(NSInteger)type atIndexPath:(NSIndexPath*)indexPath
{
  //Type 1: file; type 2: symlink; type 3: directory
  if(type == 1)
  {
    //Check if Filza is installed
    BOOL filzaInstalled = [fileManager fileExistsAtPath:@"/Applications/Filza.app"];

    //Get fileName for title
    NSString* fileName = [[fileURL lastPathComponent] stringByRemovingPercentEncoding];

    //Create alertSheet for tapped file
    UIAlertController *openAlert = [UIAlertController alertControllerWithTitle:fileName
      message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    //Get fileUTI
    CFStringRef fileExtension = (__bridge CFStringRef)[fileURL pathExtension];
    CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(
      kUTTagClassFilenameExtension, fileExtension, NULL);

    if(UTTypeConformsTo(fileUTI, kUTTypeMovie) || UTTypeConformsTo(fileUTI, kUTTypeAudio))
    {
      //File is audio or video -> Add option to play file
      UIAlertAction *playAction = [UIAlertAction
        actionWithTitle:[localizationManager localizedSPStringForKey:@"PLAY"]
        style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
      {
        [self startPlayerWithMedia:fileURL];
      }];

      [openAlert addAction:playAction];
    }

    UIAlertAction *openInAction = [UIAlertAction actionWithTitle:[localizationManager
      localizedSPStringForKey:@"OPEN_IN"]
      style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
    {
      //Creating temporary link cause we ain't inside sandbox (silly, right?)
      self.tmpSymlinkURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@",
        NSTemporaryDirectory(), fileURL.lastPathComponent]];

      [[NSFileManager defaultManager] linkItemAtURL:fileURL.URLByResolvingSymlinksInPath
        toURL:self.tmpSymlinkURL error:nil];

      //No option selected yet
      self.didSelectOptionFromDocumentController = NO;

      //Create documentController from selected file and present it
      self.documentController = [UIDocumentInteractionController
        interactionControllerWithURL:self.tmpSymlinkURL];

      self.documentController.delegate = self;
      [self.documentController presentOpenInMenuFromRect:CGRectZero inView:self.view animated:YES];
    }];

    [openAlert addAction:openInAction];

    if(filzaInstalled)
    {
      //Filza is installed -> add 'Show in Filza' option
      UIAlertAction *showInFilzaAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"SHOW_IN_FILZA"]
        style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
      {
        //https://stackoverflow.com/a/32145122
        NSString *FilzaPath = [NSString stringWithFormat:@"%@%@", @"filza://view",[fileURL absoluteString]];
        [self openScheme:FilzaPath];
      }];

      [openAlert addAction:showInFilzaAction];
    }

    //Add delete option
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"DELETE_FILE"]
          style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action)
          {
            //Create alert to confirm deletion of file
            UIAlertController* confirmationController = [UIAlertController
              alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"WARNING"]
              message:[[localizationManager localizedSPStringForKey:@"DELETE_FILE_MESSAGE"]
              stringByReplacingOccurrencesOfString:@"<fn>" withString:fileName]
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
              dispatch_async(dispatch_get_main_queue(), ^
              {
                //Delete file
                [fileManager removeItemAtPath:[fileURL path] error:nil];

                //Reload files
                [self reloadDataAndDataSources];
              });
            }];

            [confirmationController addAction:deleteAction];

            //Make cancel option bold
            confirmationController.preferredAction = cancelAction;

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
  [super selectedFileAtURL:fileURL type:type atIndexPath:indexPath];
}

//https://stackoverflow.com/a/35619091

- (void)documentInteractionController:(UIDocumentInteractionController *)controller willBeginSendingToApplication:(NSString *)application
{
  //Selected app in open in alert
  self.didSelectOptionFromDocumentController = YES;
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application
{
  //Link finished importing -> delete link
  [[NSFileManager defaultManager] removeItemAtURL:self.tmpSymlinkURL error:nil];
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
  if(self.didSelectOptionFromDocumentController == NO)
  {
    //Cancelled open in menu -> delete link
    [[NSFileManager defaultManager] removeItemAtURL:self.tmpSymlinkURL error:nil];
  }
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
