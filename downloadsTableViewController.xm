//  downloadsTableViewController.xm
// (c) 2017 opa334

#import "downloadsTableViewController.h"

@implementation downloadsTableViewController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  switch(section)
  {
    case 0:
    return [self.downloadsAtCurrentPath count];
    break;

    case 1:
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
  self.downloadsAtCurrentPath = [NSMutableArray new];
  self.downloadsAtCurrentPath = [[downloadManager sharedInstance] getDownloadsForPath:self.currentPath];
}

- (void)viewDidAppear:(BOOL)animated
{
  [downloadManager sharedInstance].downloadTableDelegate = self;
  [super viewDidAppear:animated];
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
      Download* currentDownload = self.downloadsAtCurrentPath[indexPath.row];
      downloadTableViewCell* cell = [self newCellWithDownload:currentDownload];
      cell.imageView.image = [UIImage imageNamed:@"File.png" inBundle:SPBundle compatibleWithTraitCollection:nil];
      cell.textLabel.text = currentDownload.fileName;
      currentDownload.cellDelegate = cell;
      return cell;
      break;
    }

    case 1:
    {
      return (fileTableViewCell*)[super tableView:tableView cellForRowAtIndexPath:indexPath];
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
    return 66.0;
  }
  else
  {
    return tableView.rowHeight;
  }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  if(indexPath.section == 1)
  {
    return [super tableView:tableView canEditRowAtIndexPath:indexPath];
  }
  else
  {
    return NO;
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if(indexPath.section != 0)
  {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
  }
}

- (void)selectedEntryAtURL:(NSURL*)entryURL type:(NSInteger)type atIndexPath:(NSIndexPath*)indexPath
{
  //Type 1: file; type 2: symlink; type 3: directory
  if(type == 1)
  {
    BOOL filzaInstalled = [fileManager fileExistsAtPath:@"/Applications/Filza.app"];
    NSString* fileName = [[entryURL lastPathComponent] stringByRemovingPercentEncoding];

    UIAlertController *openAlert = [UIAlertController alertControllerWithTitle:fileName
          message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    CFStringRef fileExtension = (__bridge CFStringRef)[entryURL pathExtension];
    CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);

    if(UTTypeConformsTo(fileUTI, kUTTypeMovie) || UTTypeConformsTo(fileUTI, kUTTypeAudio))
    {
      UIAlertAction *playAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"PLAY"]
            style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
            {
              [self startPlayerWithMedia:entryURL];
            }];

      [openAlert addAction:playAction];
    }

    UIAlertAction *openInAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"OPEN_IN"]
          style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
          {
            //Creating temporary link cause we ain't inside sandbox (silly, right?)
            self.tmpSymlinkURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", NSTemporaryDirectory(), entryURL.lastPathComponent]];
            [[NSFileManager defaultManager] linkItemAtURL:entryURL.URLByResolvingSymlinksInPath toURL:self.tmpSymlinkURL error:nil];

            self.didSelectOptionFromDocumentController = NO;

            self.documentController = [UIDocumentInteractionController interactionControllerWithURL:self.tmpSymlinkURL];
            self.documentController.delegate = self;
            [self.documentController presentOpenInMenuFromRect:CGRectZero inView:self.view animated:YES];
          }];

    [openAlert addAction:openInAction];

    if(filzaInstalled)
    {
      UIAlertAction *showInFilzaAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"SHOW_IN_FILZA"]
            style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
            {
              //https://stackoverflow.com/a/32145122
              NSString *FilzaPath = [NSString stringWithFormat:@"%@%@", @"filza://view",[entryURL absoluteString]];
              [[UIApplication sharedApplication] openURL:[NSURL URLWithString:FilzaPath]];
            }];

      [openAlert addAction:showInFilzaAction];
    }

    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"DELETE_FILE"]
          style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action)
          {
            UIAlertController* confirmationController = [UIAlertController alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"WARNING"]
              message:[[localizationManager localizedSPStringForKey:@"DELETE_FILE_MESSAGE"] stringByReplacingOccurrencesOfString:@"<fn>" withString:fileName] preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CANCEL"]
              style:UIAlertActionStyleDefault handler:nil];

            [confirmationController addAction:cancelAction];

            UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"DELETE"]
              style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action)
            {
              dispatch_async(dispatch_get_main_queue(), ^
              {
                [fileManager removeItemAtPath:[entryURL path] error:nil];
                [self reloadDataAndDataSources];
              });
            }];

            [confirmationController addAction:deleteAction];

            confirmationController.preferredAction = cancelAction;

            [self presentViewController:confirmationController animated:YES completion:nil];
          }];

    [openAlert addAction:deleteAction];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CANCEL"]
          style:UIAlertActionStyleCancel handler:nil];

    [openAlert addAction:cancelAction];

    //iPad fix
    CGRect cellRect = [self.tableView rectForRowAtIndexPath:indexPath];
    openAlert.popoverPresentationController.sourceView = self.tableView;
    openAlert.popoverPresentationController.sourceRect = CGRectMake(cellRect.size.width / 2.0, cellRect.origin.y + cellRect.size.height / 2, 1.0, 1.0);

    [self presentViewController:openAlert animated:YES completion:nil];
  }
  [super selectedEntryAtURL:entryURL type:type atIndexPath:indexPath];
}

//https://stackoverflow.com/a/35619091

- (void)documentInteractionController:(UIDocumentInteractionController *)controller willBeginSendingToApplication:(NSString *)application
{
  self.didSelectOptionFromDocumentController = YES;
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application
{
  //Clean up
  [[NSFileManager defaultManager] removeItemAtURL:self.tmpSymlinkURL error:nil];
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
  if(self.didSelectOptionFromDocumentController == NO) //Cancelled
  {
    //Clean up
    [[NSFileManager defaultManager] removeItemAtURL:self.tmpSymlinkURL error:nil];
  }
}

- (void)startPlayerWithMedia:(NSURL*)mediaURL
{
  [[AVAudioSession sharedInstance] setActive:YES error:nil];

  //Enable Background Audio
  [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];

  AVPlayer* player = [AVPlayer playerWithURL:mediaURL];

  AVPlayerViewController *playerViewController = [AVPlayerViewController new];

  playerViewController.player = player;
  //playerViewController.allowsPictureInPicturePlayback = YES;

  [self presentViewController:playerViewController animated:YES completion:^
  {
    [player play];
  }];
}

- (id)newCellWithDownload:(Download*)download
{
  return [[downloadTableViewCell alloc] initWithDownload:download];
}

@end
