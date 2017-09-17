//  SPDownloadManager.xm
// (c) 2017 opa334

#import "SPDownloadManager.h"

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

  self.pendingDownloads = [NSMutableArray new];

  //Create message center to communicate with SpringBoard through RocketBootstrap
  CPDistributedMessagingCenter* tmpCenter = [%c(CPDistributedMessagingCenter)
    centerNamed:@"com.opa334.SafariPlus.MessagingCenter"];

  #ifndef SIMJECT
  rocketbootstrap_distributedmessagingcenter_apply(tmpCenter);
  #endif

  //Set message center to property
  self.SPMessagingCenter = tmpCenter;

  //Remove download storage if needed
  [self checkDownloadStorageRevision];

  //Get downloads from file
  [self loadDownloadsFromDisk];

  //Set session up
  [self setUpSession];

  return self;
}

- (NSURLSession*)sharedDownloadSession
{
  return self.downloadSession;
}

- (void)setUpSession
{
  //Create background configuration for shared session
  NSURLSessionConfiguration* config = [NSURLSessionConfiguration
    backgroundSessionConfigurationWithIdentifier:@"com.opa334.SafariPlus.sharedSession"];

  //Configure cellular access
  config.allowsCellularAccess = !preferenceManager.onlyDownloadOnWifiEnabled;

  //Create shared session with configuration
  self.downloadSession = [NSURLSession sessionWithConfiguration:config
    delegate:self delegateQueue:nil];

  self.errorCount = 0;
  self.errorsCounted = 0;

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
      }
      else
      {
        //Count how often didCompleteWithError will get called
        self.errorCount++;
      }
    }
  }];
}

- (void)checkDownloadStorageRevision
{
  loadOtherPlist();

  int storageRevision = [[otherPlist objectForKey:@"downloadFormatRevision"] intValue];

  if(storageRevision != DownloadStorageRevision)
  {
    //Remove stored downloads
    [self removeStoredDownloads];

    //Also clear temp files
    [self clearTempFiles];

    storageRevision = DownloadStorageRevision;

    [otherPlist setObject:[NSNumber numberWithInt:storageRevision]
      forKey:@"downloadFormatRevision"];

    saveOtherPlist();
  }
}

- (void)removeStoredDownloads
{
  if([[NSFileManager defaultManager] fileExistsAtPath:downloadsStorePath])
  {
    [[NSFileManager defaultManager] removeItemAtPath:downloadsStorePath error:nil];
  }
}

- (void)clearTempFiles
{
  //Get files in tmp directory
  NSArray* tmpFiles = [[NSFileManager defaultManager]
    contentsOfDirectoryAtURL:[NSURL fileURLWithPath:NSTemporaryDirectory()]
    includingPropertiesForKeys:nil
    options:nil
    error:nil];

  for(NSURL* tmpFile in tmpFiles)
  {
    if([tmpFile.lastPathComponent containsString:@"CFNetworkDownload"])
    {
      //File is download -> remove it
      [[NSFileManager defaultManager] removeItemAtPath:[tmpFile path] error:nil];
    }
  }

  //Get nsurlsessiond cache path
  NSString* cachePath = [NSHomeDirectory()
    stringByAppendingString:@"/Library/Caches/com.apple.nsurlsessiond"];

  if([[NSFileManager defaultManager] fileExistsAtPath:cachePath])
  {
    //Remove cache directory
    [[NSFileManager defaultManager] removeItemAtPath:cachePath error:nil];
  }

  //NOTE: Sometimes temp files are saved in /tmp and sometimes in caches
}

- (void)resumeDownloadsFromDiskLoad
{
  for(SPDownload* download in self.pendingDownloads)
  {
    if(download.resumeData)
    {
      [download startDownloadFromResumeData];
    }
    else
    {
      [download startDownload];
    }
  }
}

- (void)loadDownloadsFromDisk
{
  if([[NSFileManager defaultManager] fileExistsAtPath:downloadsStorePath])
  {
    NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:downloadsStorePath]];
    self.pendingDownloads = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    for(SPDownload* download in self.pendingDownloads)
    {
      download.downloadManagerDelegate = self;
    }
  }
}

- (void)saveDownloadsToDisk
{
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.pendingDownloads];
  [data writeToFile:downloadsStorePath atomically:YES];
}

- (void)sendNotificationWithText:(NSString*)text
{
  if([[UIApplication sharedApplication] applicationState] == 0 &&
    !preferenceManager.disableBarNotificationsEnabled)
  {
    //Application is active -> Use status bar notification if not disabled
    //Dissmiss current status notification (if one exists)
    [self.rootControllerDelegate dismissNotificationWithCompletion:^
    {
      //Dispatch status notification with given text
      [self.rootControllerDelegate dispatchNotificationWithText:text];
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
    [self.SPMessagingCenter sendMessageName:@"pushNotification" userInfo:userInfo];
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
      //Download is at wanted path -> add it to array
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
      return YES;
    }
  }
  return NO;
}

- (void)configureDownloadWithInfo:(SPDownloadInfo*)downloadInfo
{
  if(downloadInfo.customPath)
  {
    if(preferenceManager.pinnedLocationsEnabled)
    {
      [self presentPinnedLocationsWithDownloadInfo:downloadInfo];
    }
    else
    {
      [self presentDirectoryPickerWithDownloadInfo:downloadInfo];
    }
  }
  else
  {
    if(preferenceManager.customDefaultPathEnabled)
    {
      downloadInfo.targetPath = [NSURL fileURLWithPath:preferenceManager.customDefaultPath];
    }
    else
    {
      downloadInfo.targetPath = [NSURL fileURLWithPath:defaultDownloadPath];
    }

    if([downloadInfo fileExists] || [self downloadExistsAtURL:[downloadInfo pathURL]])
    {
      [self presentFileExistsAlertWithDownloadInfo:downloadInfo];
    }
    else
    {
      [self startDownloadWithInfo:downloadInfo];
    }
  }
}

- (void)startDownloadWithInfo:(SPDownloadInfo*)downloadInfo
{
  if(downloadInfo.image)
  {
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

    [self saveDownloadsToDisk];

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

- (void)presentDirectoryPickerWithDownloadInfo:(SPDownloadInfo*)downloadInfo
{
  SPDirectoryPickerNavigationController* directoryPicker =
    [[SPDirectoryPickerNavigationController alloc] initWithDownloadInfo:downloadInfo];

  [self.rootControllerDelegate presentViewController:directoryPicker];
}

- (void)presentPinnedLocationsWithDownloadInfo:(SPDownloadInfo*)downloadInfo
{
  //Load plist
  loadOtherPlist();

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
    [pinnedLocationAlert addAction:[UIAlertAction actionWithTitle:name
      style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
    {
      NSInteger index = [pinnedLocationAlert.actions indexOfObject:action];
      __block NSURL* path = [NSURL fileURLWithPath:[PinnedLocationPaths objectAtIndex:index]];

      UIAlertController* filenameAlert = [UIAlertController
        alertControllerWithTitle:[localizationManager
        localizedSPStringForKey:@"CHOOSE_FILENAME"] message:nil
        preferredStyle:UIAlertControllerStyleAlert];

      [filenameAlert addTextFieldWithConfigurationHandler:^(UITextField *textField)
      {
        textField.placeholder = [localizationManager
          localizedSPStringForKey:@"FILENAME"];
        textField.textColor = [UIColor blackColor];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleNone;
        textField.text = downloadInfo.filename;
      }];

      UIAlertAction* chooseAction = [UIAlertAction actionWithTitle:
        [localizationManager localizedSPStringForKey:@"CHOOSE"]
        style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
      {
        downloadInfo.filename = filenameAlert.textFields[0].text;

        //Resolve possible symlinks
        path = path.URLByResolvingSymlinksInPath;

        //Do some magic to fix up the path (why, apple?)
        path = [NSURL fileURLWithPath:[[path path]
          stringByReplacingOccurrencesOfString:@"/var"
          withString:@"/private/var"]];

        downloadInfo.targetPath = path;

        [self pathSelectionResponseWithDownloadInfo:downloadInfo];
      }];

      [filenameAlert addAction:chooseAction];

      UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:
        [localizationManager localizedSPStringForKey:@"CANCEL"]
        style:UIAlertActionStyleCancel handler:nil];

      [filenameAlert addAction:cancelAction];

      [self.rootControllerDelegate presentViewController:filenameAlert];
    }]];
  }

  UIAlertAction* browseAction = [UIAlertAction actionWithTitle:
    [localizationManager localizedSPStringForKey:@"BROWSE"]
    style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
  {
    //Present directory picker
    [self presentDirectoryPickerWithDownloadInfo:downloadInfo];
  }];

  [pinnedLocationAlert addAction:browseAction];

  UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:
    [localizationManager localizedSPStringForKey:@"CANCEL"]
    style:UIAlertActionStyleCancel handler:nil];

  [pinnedLocationAlert addAction:cancelAction];

  [self.rootControllerDelegate presentAlertControllerSheet:pinnedLocationAlert];
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
  [self.rootControllerDelegate presentViewController:errorAlert];
}

- (void)pathSelectionResponseWithDownloadInfo:(SPDownloadInfo*)downloadInfo
{
  if([downloadInfo fileExists] || [self downloadExistsAtURL:[downloadInfo pathURL]])
  {
    [self presentFileExistsAlertWithDownloadInfo:downloadInfo];
  }
  else
  {
    [self startDownloadWithInfo:downloadInfo];
  }
}

- (void)URLSession:(NSURLSession *)session
  downloadTask:(NSURLSessionDownloadTask *)downloadTask
  didFinishDownloadingToURL:(NSURL *)location
{
  //Get finished download
  SPDownload* download = [self downloadWithTaskIdentifier:downloadTask.taskIdentifier];

  //Get path of desired location
  NSURL* pathURL = [download.targetPath URLByAppendingPathComponent:download.filename];

  //Remove file if it exists
  if([[NSFileManager defaultManager] fileExistsAtPath:[pathURL path]])
  {
    [[NSFileManager defaultManager] removeItemAtPath:[pathURL path] error:nil];
  }

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

      //Connect resumeData with download
      download.resumeData = resumeData;

      //Count how often this function was called
      self.errorsCounted++;

      if(self.errorsCounted == self.errorCount)
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
  [targetDownload updateProgress:totalBytesWritten];
}

@end
