// SPDownloadManager.xm
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

#import "SPDownloadManager.h"

#import "../Defines.h"
#import "../SafariPlus.h"
#import "../Shared.h"
#import "SPDirectoryPickerNavigationController.h"
#import "SPDownload.h"
#import "SPDownloadInfo.h"
#import "SPLocalizationManager.h"
#import "SPPreferenceManager.h"
#import "SPStatusBarNotification.h"
#import "SPStatusBarNotificationWindow.h"

#import <AppSupport/CPDistributedMessagingCenter.h>
#import <WebKit/WKWebView.h>

#if !defined(SIMJECT) && !defined(ELECTRA)
#import <RocketBootstrap/rocketbootstrap.h>
#endif

@implementation SPDownloadManager

+ (instancetype)sharedInstance
{
    static SPDownloadManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,
    ^{
      //Initialise instance
      sharedInstance = [[SPDownloadManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
  self = [super init];

  if(![[NSFileManager defaultManager] fileExistsAtPath:defaultDownloadPath])
  {
    //Downloads directory doesn't exist -> create it
    [[NSFileManager defaultManager] createDirectoryAtPath:defaultDownloadPath
      withIntermediateDirectories:NO attributes:nil error:nil];
  }

  self.pendingDownloads = [NSMutableArray new];

  //Create message center to communicate with SpringBoard through RocketBootstrap
  self.messagingCenter = [%c(CPDistributedMessagingCenter)
    centerNamed:@"com.opa334.SafariPlus.MessagingCenter"];

  #if !defined(SIMJECT) && !defined(ELECTRA)
  rocketbootstrap_distributedmessagingcenter_apply(_messagingCenter);
  #endif

  //Init notification window for status bar notifications
  self.notificationWindow = [[SPStatusBarNotificationWindow alloc] init];

  #ifndef ELECTRA

  //Remove download storage if needed
  [self checkDownloadStorageRevision];

  #endif

  //Get downloads from file
  [self loadDownloadsFromDisk];

  //Configure session
  [self configureSession];

  return self;
}

- (NSURLSession*)sharedDownloadSession
{
  return self.downloadSession;
}

- (void)configureSession
{
  //Create background configuration for shared session
  NSURLSessionConfiguration* config = [NSURLSessionConfiguration
    backgroundSessionConfigurationWithIdentifier:@"com.opa334.SafariPlus.sharedSession"];

  //Configure cellular access
  config.allowsCellularAccess = !preferenceManager.onlyDownloadOnWifiEnabled;

  //Create shared session with configuration
  self.downloadSession = [NSURLSession sessionWithConfiguration:config
    delegate:self delegateQueue:nil];

  self.errorCount = 0; //Counts how many errors exists
  self.processedErrorCount = 0; //Counts how many errors are processed

  [self.downloadSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks)
  {
    for(NSURLSessionDownloadTask* task in downloadTasks)
    {
      //Reconnect sessions that are still running (for example after a respring)
      if(task.state != 3)
      {
        SPDownload* download = [self downloadWithTaskIdentifier:task.taskIdentifier];
        download.downloadTask = task;
        [download setTimerEnabled:YES];
        //NSLog(@"SafariPlus - Reconnected task:%@", task);
      }
      else
      {
        //Count how often didCompleteWithError will get called
        self.errorCount++;
        //NSLog(@"SafariPlus - Task will error:%@", task);
      }
    }
  }];
}

- (void)checkDownloadStorageRevision
{
  loadOtherPlist();

  //Get storage revision from plist
  int storageRevision = [[otherPlist objectForKey:@"downloadFormatRevision"] intValue];

  //Check if download storage is up to date
  if(storageRevision != DownloadStorageRevision)
  {
    //NSLog(@"SafariPlus - Download Storage not up to date");
    //Remove download storage
    [self removeDownloadStorageFile];

    //Also clear temp files
    [self clearTempFiles];

    //Update storageRevision to current
    storageRevision = DownloadStorageRevision;

    //Save it to plist
    [otherPlist setObject:[NSNumber numberWithInt:storageRevision]
      forKey:@"downloadFormatRevision"];

    saveOtherPlist();
  }
}

- (void)removeDownloadStorageFile
{
  if([[NSFileManager defaultManager] fileExistsAtPath:downloadStoragePath])
  {
    [[NSFileManager defaultManager] removeItemAtPath:downloadStoragePath error:nil];
  }
}

- (void)clearTempFiles
{
  //NOTE: Sometimes temp files are saved in /tmp and sometimes in caches

  //NSLog(@"SafariPlus - clearTempFiles");

  //Get files in tmp directory
  NSArray* tmpFiles = [[NSFileManager defaultManager]
    contentsOfDirectoryAtURL:[NSURL fileURLWithPath:NSTemporaryDirectory()]
    includingPropertiesForKeys:nil
    options:0
    error:nil];

  //Get files in caches directory
  NSArray* cacheFiles = [[NSFileManager defaultManager]
    contentsOfDirectoryAtURL:[NSURL fileURLWithPath:[NSHomeDirectory()
    stringByAppendingString:@"/Library/Caches/com.apple.nsurlsessiond/Downloads/com.apple.mobilesafari"]]
    includingPropertiesForKeys:nil
    options:0
    error:nil];

  //Join arrays
  NSArray* files = [tmpFiles arrayByAddingObjectsFromArray:cacheFiles];

  for(NSURL* file in files)
  {
    if([file.lastPathComponent containsString:@"CFNetworkDownload"])
    {
      //File is cached download -> remove it
      [[NSFileManager defaultManager] removeItemAtPath:[file path] error:nil];
    }
  }
}

- (void)cancelAllDownloads
{
  //Cancel all downloads
  for(SPDownload* download in self.pendingDownloads)
  {
    [download cancelDownload];
  }

  //Reinitialise array
  self.pendingDownloads = [NSMutableArray new];

  //Reload table views
  [self.navigationControllerDelegate reloadTopTableView];
}

- (void)resumeDownloadsFromDiskLoad
{
  //This function aims to resume the downloads in the same order they were
  //when Safari was closed
  //NOTE: The order gets a little messy when a download was left paused
  //This cannot be fixed reliably to my knowledge, because of how NSURLSessions work
  for(SPDownload* download in self.pendingDownloads)
  {
    if(download.resumeData)
    {
      //NSLog(@"SafariPlus - started download %@ from resume data", download);
      //Download has resume data -> resume it
      [download startDownloadFromResumeData];
    }
    else
    {
      //NSLog(@"SafariPlus - started download %@ from beginning", download);
      //Download has no resume data -> start it from the beginning
      [download startDownload];
    }
  }
}

- (void)loadDownloadsFromDisk
{
  //NSLog(@"SafariPlus - loadDownloadsFromDisk");
  if([[NSFileManager defaultManager] fileExistsAtPath:downloadStoragePath])
  {
    //Get data from download storage file
    NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:downloadStoragePath]];

    //Unarchive the data to pendingDownloads
    self.pendingDownloads = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    for(SPDownload* download in self.pendingDownloads)
    {
      //Set downloadManagerDelegate for all downloads
      download.downloadManagerDelegate = self;
    }

    //NSLog(@"SafariPlus - Download Storage Exists");
  }
}

- (void)saveDownloadsToDisk
{
  //Create data from pendingDownloads
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.pendingDownloads];

  //Write data to file
  [data writeToFile:downloadStoragePath atomically:YES];
}

- (void)sendNotificationWithText:(NSString*)text
{
  if([[UIApplication sharedApplication] applicationState] == 0 &&
    !preferenceManager.disableBarNotificationsEnabled)
  {
    //Application is active -> Use status bar notification if not disabled
    //Dissmiss current status notification (if one exists)
    [self.notificationWindow dismissWithCompletion:^
    {
      //Dispatch status notification with given text
      [self.notificationWindow dispatchNotification:[SPStatusBarNotification downloadStyleWithText:text]];
    }];
  }
  else if([[UIApplication sharedApplication] applicationState] != 0 &&
    !preferenceManager.disablePushNotificationsEnabled)
  {
    //Application is inactive -> Use push notification if not disabled
    //Create userInfo to send to SpringBoard
    NSDictionary* userInfo =
    @{@"title"    :  @"Safari",
      @"message"  :  text,
      @"bundleID" :  @"com.apple.mobilesafari"
    };

    //Send userInfo to SpringBoard using RocketBootstrap
    //There it dispatches a notification using libbulletin
    [self.messagingCenter sendMessageName:@"pushNotification" userInfo:userInfo];
  }
}

- (int64_t)freeDiscspace
{
  int64_t freeSpace; //Free space of device
  int64_t occupiedDownloadSpace = 0; //Space that's 'reserved' for downloads
  int64_t totalFreeSpace; //Total usable space

  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSDictionary* dictionary = [[NSFileManager defaultManager]
    attributesOfFileSystemForPath:[paths lastObject] error:nil];

  if(dictionary)
  {
    freeSpace = ((NSNumber*)[dictionary objectForKey:NSFileSystemFreeSize]).longLongValue;
  }

  for(SPDownload* download in self.pendingDownloads)
  {
    occupiedDownloadSpace += [download remainingBytes];
  }

  totalFreeSpace = freeSpace - occupiedDownloadSpace;

  return totalFreeSpace;
}

- (BOOL)enoughDiscspaceForDownloadInfo:(SPDownloadInfo*)downloadInfo
{
  return downloadInfo.filesize <= [self freeDiscspace];
}

//When a download url was opened in a new tab, the tab will stay
//blank after an option was selected, this function closes that tab
- (void)closeDocumentIfObsoleteWithDownloadInfo:(SPDownloadInfo*)downloadInfo;
{
  if(downloadInfo)
  {
    if(![downloadInfo.sourceDocument URL] && !downloadInfo.sourceDocument.blankDocument)
    {
      [downloadInfo.sourceDocument _closeTabDocumentAnimated:YES];
    }
  }
}

- (SPDownload*)downloadWithTaskIdentifier:(NSUInteger)identifier
{
  for(SPDownload* download in self.pendingDownloads)
  {
    if(download.taskIdentifier == identifier)
    {
      //Download taskIdentifier matches -> return download
      return download;
    }
  }
  return nil;
}

- (NSArray*)downloadsAtURL:(NSURL*)URL
{
  //Create mutable array
  NSMutableArray* downloadsAtURL = [NSMutableArray new];

  for(SPDownload* download in self.pendingDownloads)
  {
    if([download.targetPath.URLByResolvingSymlinksInPath.path isEqualToString:URL.URLByResolvingSymlinksInPath.path])
    {
      //Download is at specified path -> add it to array
      [downloadsAtURL addObject:download];
    }
  }

  //Return array
  return downloadsAtURL;
}

- (BOOL)downloadExistsAtURL:(NSURL*)URL
{
  for(SPDownload* download in self.pendingDownloads)
  {
    //Get path of download
    NSURL* pathURL = [download.targetPath URLByAppendingPathComponent:download.filename];

    if([pathURL.URLByResolvingSymlinksInPath.path
      isEqualToString:URL.URLByResolvingSymlinksInPath.path])
    {
      //Download with path exists
      return YES;
    }
  }
  //Download with path doesn't exist
  return NO;
}

- (void)configureDownloadWithInfo:(SPDownloadInfo*)downloadInfo
{
  if(downloadInfo.customPath)
  {
    //Check if downloadInfo needs a custom path
    if(preferenceManager.pinnedLocationsEnabled)
    {
      //Pinned Locations enabled -> present them
      [self presentPinnedLocationsWithDownloadInfo:downloadInfo];
    }
    else
    {
      //Pinned Locations not enabled -> present directory picker
      [self presentDirectoryPickerWithDownloadInfo:downloadInfo];
    }
  }
  else
  {
    //downloadInfo does not need custom path
    if(preferenceManager.customDefaultPathEnabled)
    {
      //Custom default path enabled -> set it as target path
      downloadInfo.targetPath = [NSURL fileURLWithPath:[@"/var"
        stringByAppendingString:preferenceManager.customDefaultPath]];
    }
    else
    {
      //Custom default path not enabled -> set path to default
      downloadInfo.targetPath = [NSURL fileURLWithPath:defaultDownloadPath];
    }

    if([downloadInfo fileExists] || [self downloadExistsAtURL:[downloadInfo pathURL]])
    {
      //File or download exists -> present alert
      [self presentFileExistsAlertWithDownloadInfo:downloadInfo];
    }
    else if(![self enoughDiscspaceForDownloadInfo:downloadInfo])
    {
      //Not enough space for download
      [self presentNotEnoughSpaceAlertWithDownloadInfo:downloadInfo];
    }
    else
    {
      //All good -> start download
      [self startDownloadWithInfo:downloadInfo];
    }
  }
}

- (void)startDownloadWithInfo:(SPDownloadInfo*)downloadInfo
{
  if(downloadInfo.image)
  {
    //Download is image -> Save it directly
    [self saveImageWithInfo:downloadInfo];
  }
  else if(downloadInfo.request)
  {
    //Create instance of SPDownload
    SPDownload* download = [[SPDownload alloc] initWithDownloadInfo:downloadInfo];

    //Set delegate for communication
    download.downloadManagerDelegate = self;

    //Start download
    [download startDownload];

    //Add download to array
    [self.pendingDownloads addObject:download];

    //Save array to disk
    [self saveDownloadsToDisk];

    //Send notification
    [self sendNotificationWithText:[NSString stringWithFormat:@"%@: %@",
      [localizationManager localizedSPStringForKey:@"DOWNLOAD_STARTED"], downloadInfo.filename]];
  }
}

- (void)saveImageWithInfo:(SPDownloadInfo*)downloadInfo
{
  //Remove existing file (if one exists)
  [downloadInfo removeExistingFile];

  //Write image to file
  [UIImagePNGRepresentation(downloadInfo.image) writeToFile:[downloadInfo pathString] atomically:YES];

  //Send notification
  [self sendNotificationWithText:[NSString
    stringWithFormat:@"%@: %@", [localizationManager
    localizedSPStringForKey:@"SAVED_IMAGE"], downloadInfo.filename]];
}

- (void)presentViewController:(UIViewController*)viewController withDownloadInfo:(SPDownloadInfo*)downloadInfo
{
  if(downloadInfo.presentationController)
  {
    if([viewController isKindOfClass:[UIAlertController class]])
    {
      UIAlertController* alertController = (UIAlertController*)viewController;

      if(alertController.preferredStyle == UIAlertControllerStyleActionSheet)
      {
        //Set sourceView (iPad)
        alertController.popoverPresentationController.sourceView =
          downloadInfo.presentationController.view;

        if(CGRectIsEmpty(downloadInfo.sourceRect))
        {
          //Fallback iPad positions to middle of screen (because no sourceRect was specified)
          alertController.popoverPresentationController.sourceRect =
            CGRectMake(downloadInfo.presentationController.view.bounds.size.width / 2,
            downloadInfo.presentationController.view.bounds.size.height / 2, 1.0, 1.0);
        }
        else
        {
          //Set iPad positions to specified sourceRect
          alertController.popoverPresentationController.sourceRect = downloadInfo.sourceRect;
        }
      }
    }

    dispatch_async(dispatch_get_main_queue(),
    ^{
      [downloadInfo.presentationController presentViewController:viewController animated:YES completion:nil];
    });
  }
}

- (void)presentDownloadAlertWithDownloadInfo:(SPDownloadInfo*)downloadInfo
{
  if(preferenceManager.instantDownloadsEnabled)
  {
    if(preferenceManager.instantDownloadsOption == 1)
    {
      //Start download
      [self configureDownloadWithInfo:downloadInfo];
    }
    else
    {
      //Start download with custom path
      downloadInfo.customPath = YES;
      [self configureDownloadWithInfo:downloadInfo];
    }

    [self closeDocumentIfObsoleteWithDownloadInfo:downloadInfo];
  }
  else
  {
    NSString* title;

    if(downloadInfo.filesize < 0)
    {
      //Size unknown (Happens on Google Drive for example)
      title = [NSString stringWithFormat:@"%@ (%@)", downloadInfo.filename,
        [localizationManager localizedSPStringForKey:@"SIZE_UNKNOWN"]];
    }
    else if(downloadInfo.filesize)
    {
      //Filesize exists -> add it to title
      title = [NSString stringWithFormat:@"%@ (%@)", downloadInfo.filename,
        [NSByteCountFormatter stringFromByteCount:downloadInfo.filesize
        countStyle:NSByteCountFormatterCountStyleFile]];
    }
    else
    {
      //Filesize doesn't exist, just use filename as title
      title = downloadInfo.filename;
    }

    UIAlertController* downloadAlert = [UIAlertController
      alertControllerWithTitle:title message:nil
      preferredStyle:UIAlertControllerStyleActionSheet];

    //Download option
    UIAlertAction *downloadAction = [UIAlertAction
      actionWithTitle:[localizationManager
      localizedSPStringForKey:@"DOWNLOAD"]
      style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
    {
      //Start download
      [self configureDownloadWithInfo:downloadInfo];
      [self closeDocumentIfObsoleteWithDownloadInfo:downloadInfo];
    }];

    [downloadAlert addAction:downloadAction];

    //Download to... option
    UIAlertAction *downloadToAction = [UIAlertAction
      actionWithTitle:[localizationManager
      localizedSPStringForKey:@"DOWNLOAD_TO"]
      style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
    {
      //Start download with custom path
      downloadInfo.customPath = YES;
      [self configureDownloadWithInfo:downloadInfo];
      [self closeDocumentIfObsoleteWithDownloadInfo:downloadInfo];
    }];

    [downloadAlert addAction:downloadToAction];

    //Copy link options (only on videos)
    if(downloadInfo.isVideo)
    {
      UIAlertAction *copyLinkAction = [UIAlertAction
        actionWithTitle:[localizationManager
        localizedSPStringForKey:@"COPY_LINK"]
        style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
      {
        [UIPasteboard generalPasteboard].string = downloadInfo.request.URL.absoluteString;
      }];

      [downloadAlert addAction:copyLinkAction];
    }
    //Open option (not on videos)
    else
    {
      UIAlertAction *openAction = [UIAlertAction actionWithTitle:[localizationManager
        localizedSPStringForKey:@"OPEN"]
        style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
      {
        //Load request again and avoid another alert
        showAlert = NO;
        [downloadInfo.sourceDocument.webView loadRequest:downloadInfo.request];
      }];

      [downloadAlert addAction:openAction];
    }

    //Cancel option
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[localizationManager
      localizedSPStringForKey:@"CANCEL"]
      style:UIAlertActionStyleCancel handler:^(UIAlertAction * action)
    {
      [self closeDocumentIfObsoleteWithDownloadInfo:downloadInfo];
    }];
    [downloadAlert addAction:cancelAction];

    [self presentViewController:downloadAlert withDownloadInfo:downloadInfo];
  }
}

- (void)presentDirectoryPickerWithDownloadInfo:(SPDownloadInfo*)downloadInfo
{
  SPDirectoryPickerNavigationController* directoryPicker =
    [[SPDirectoryPickerNavigationController alloc] initWithDownloadInfo:downloadInfo];

  [self presentViewController:directoryPicker withDownloadInfo:downloadInfo];
}

- (void)presentPinnedLocationsWithDownloadInfo:(SPDownloadInfo*)downloadInfo
{
  //Load plist
  loadOtherPlist();

  //Get pinned location names & paths
  NSArray* PinnedLocationNames = [NSArray new];
  NSArray* PinnedLocationPaths = [NSArray new];
  PinnedLocationNames = [otherPlist objectForKey:@"PinnedLocationNames"];
  PinnedLocationPaths = [otherPlist objectForKey:@"PinnedLocationPaths"];

  UIAlertController* pinnedLocationAlert = [UIAlertController
    alertControllerWithTitle:[localizationManager
    localizedSPStringForKey:@"PINNED_LOCATIONS"] message:nil
    preferredStyle:UIAlertControllerStyleActionSheet];

  for(NSString* name in PinnedLocationNames)
  {
    //Add option for each location
    [pinnedLocationAlert addAction:[UIAlertAction actionWithTitle:name
      style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
    {
      //Get index of tapped action
      NSInteger index = [pinnedLocationAlert.actions indexOfObject:action];

      //Get path from index
      __block NSURL* path = [NSURL fileURLWithPath:[PinnedLocationPaths objectAtIndex:index]];

      //Alert for filename
      UIAlertController* filenameAlert = [UIAlertController
        alertControllerWithTitle:[localizationManager
        localizedSPStringForKey:@"CHOOSE_FILENAME"] message:nil
        preferredStyle:UIAlertControllerStyleAlert];

      //Add textfield
      [filenameAlert addTextFieldWithConfigurationHandler:^(UITextField *textField)
      {
        textField.placeholder = [localizationManager
          localizedSPStringForKey:@"FILENAME"];
        textField.textColor = [UIColor blackColor];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleNone;
        textField.text = downloadInfo.filename;
      }];

      //Choose option
      UIAlertAction* chooseAction = [UIAlertAction actionWithTitle:
        [localizationManager localizedSPStringForKey:@"CHOOSE"]
        style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
      {
        downloadInfo.filename = filenameAlert.textFields[0].text;

        //Resolve possible symlinks
        path = path.URLByResolvingSymlinksInPath;

        //Do some magic to fix up the path
        path = [NSURL fileURLWithPath:[[path path]
          stringByReplacingOccurrencesOfString:@"/var"
          withString:@"/private/var"]];

        //Set selected path
        downloadInfo.targetPath = path;

        [self pathSelectionResponseWithDownloadInfo:downloadInfo];
      }];

      [filenameAlert addAction:chooseAction];

      //Cancel option
      UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:
        [localizationManager localizedSPStringForKey:@"CANCEL"]
        style:UIAlertActionStyleCancel handler:nil];

      [filenameAlert addAction:cancelAction];

      //Present filename alert
      [self presentViewController:filenameAlert withDownloadInfo:downloadInfo];
    }]];
  }

  //Browse option
  UIAlertAction* browseAction = [UIAlertAction actionWithTitle:
    [localizationManager localizedSPStringForKey:@"BROWSE"]
    style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
  {
    //Present directory picker
    [self presentDirectoryPickerWithDownloadInfo:downloadInfo];
  }];

  [pinnedLocationAlert addAction:browseAction];

  //Cancel option
  UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:
    [localizationManager localizedSPStringForKey:@"CANCEL"]
    style:UIAlertActionStyleCancel handler:nil];

  [pinnedLocationAlert addAction:cancelAction];

  //Present pinned location sheet
  [self presentViewController:pinnedLocationAlert withDownloadInfo:downloadInfo];
}

- (void)presentFileExistsAlertWithDownloadInfo:(SPDownloadInfo*)downloadInfo
{
  //Create error alert
  UIAlertController *errorAlert = [UIAlertController
    alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"ERROR"]
    message:[localizationManager localizedSPStringForKey:@"FILE_EXISTS_MESSAGE"]
    preferredStyle:UIAlertControllerStyleAlert];

  //Replace action
  UIAlertAction *replaceAction = [UIAlertAction
    actionWithTitle:[localizationManager localizedSPStringForKey:@"REPLACE_FILE"]
    style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
  {
    [self startDownloadWithInfo:downloadInfo];
  }];

  //Change path action
  UIAlertAction *changePathAction = [UIAlertAction
    actionWithTitle:[localizationManager localizedSPStringForKey:@"CHANGE_PATH"]
    style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
  {
    downloadInfo.customPath = YES;
    [self configureDownloadWithInfo:downloadInfo];
  }];

  //Do nothing
  UIAlertAction *cancelAction = [UIAlertAction
    actionWithTitle:[localizationManager localizedSPStringForKey:@"CANCEL"]
    style:UIAlertActionStyleCancel handler:nil];

  //Add actions to alert
  [errorAlert addAction:replaceAction];
  [errorAlert addAction:changePathAction];
  [errorAlert addAction:cancelAction];

  //Present alert
  [self presentViewController:errorAlert withDownloadInfo:downloadInfo];
}

- (void)presentNotEnoughSpaceAlertWithDownloadInfo:(SPDownloadInfo*)downloadInfo
{
  //Create error alert
  UIAlertController *errorAlert = [UIAlertController
    alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"ERROR"]
    message:[localizationManager localizedSPStringForKey:@"NOT_ENOUGH_SPACE_MESSAGE"]
    preferredStyle:UIAlertControllerStyleAlert];

  //Do nothing
  UIAlertAction *cancelAction = [UIAlertAction
    actionWithTitle:[localizationManager localizedSPStringForKey:@"CLOSE"]
    style:UIAlertActionStyleCancel handler:nil];

  [errorAlert addAction:cancelAction];

  //Present alert
  [self presentViewController:errorAlert withDownloadInfo:downloadInfo];
}

- (void)pathSelectionResponseWithDownloadInfo:(SPDownloadInfo*)downloadInfo
{
  if([downloadInfo fileExists] || [self downloadExistsAtURL:[downloadInfo pathURL]])
  {
    //File or download already exists -> present file exists alert
    [self presentFileExistsAlertWithDownloadInfo:downloadInfo];
  }
  else if(![self enoughDiscspaceForDownloadInfo:downloadInfo])
  {
    //Not enough space for download
    [self presentNotEnoughSpaceAlertWithDownloadInfo:downloadInfo];
  }
  else
  {
    //Nothing exists -> start download
    [self startDownloadWithInfo:downloadInfo];
  }
}

- (void)URLSession:(NSURLSession *)session
  downloadTask:(NSURLSessionDownloadTask *)downloadTask
  didFinishDownloadingToURL:(NSURL *)location
{
  //Get finished download
  SPDownload* download = [self downloadWithTaskIdentifier:downloadTask.taskIdentifier];

  //Get downloadInfo from download
  SPDownloadInfo* downloadInfo = [[SPDownloadInfo alloc] initWithDownload:download];

  //Remove file if it exists
  [downloadInfo removeExistingFile];

  //Get path of desired location
  NSURL* pathURL = [downloadInfo pathURL];

  //Move downloaded file to desired location
  [[NSFileManager defaultManager] moveItemAtURL:location toURL:pathURL error:nil];

  //Dispatch status bar / push notification
  [self sendNotificationWithText:[NSString stringWithFormat:@"%@: %@",
    [localizationManager localizedSPStringForKey:@"DOWNLOAD_SUCCESS"], download.filename]];

  //Reload entries if currently inside downloadsView
  [self.navigationControllerDelegate reloadTopTableView];

  //Remove download from array
  [self.pendingDownloads removeObject:download];
  download = nil;

  [self.navigationControllerDelegate reloadTopTableView];

  //Save array
  [self saveDownloadsToDisk];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
  didCompleteWithError:(NSError *)error
{
  //NSLog(@"SafariPlus - %@ didCompleteWithError", task);
  if(error)
  {
    //Get download
    SPDownload* download = [self downloadWithTaskIdentifier:task.taskIdentifier];

    if([error.localizedDescription isEqualToString:@"cancelled"])
    {
      //Remove download from array
      [self.pendingDownloads removeObject:download];
      download = nil;

      [self.navigationControllerDelegate reloadTopTableView];
    }
    else
    {
      //Get resumeData
      NSData* resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];

      //NSLog(@"SafariPlus - Got resumeData %@", resumeData);

      //Connect resumeData with download
      download.resumeData = resumeData;

      //Count how often this function was called
      self.processedErrorCount++;

      if(self.processedErrorCount == self.errorCount)
      {
        //Function was called as often as expected -> resume all downloads
        [self resumeDownloadsFromDiskLoad];
      }
    }

    //Save downloads to disk
    [self saveDownloadsToDisk];
  }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
  didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten
  totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
  //Get download that needs updating
  SPDownload* targetDownload = [self downloadWithTaskIdentifier:downloadTask.taskIdentifier];

  //Send data to download
  [targetDownload updateProgress:totalBytesWritten totalFilesize:totalBytesExpectedToWrite];
}

@end
