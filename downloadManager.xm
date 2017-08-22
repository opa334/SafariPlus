//  downloadManager.xm
// (c) 2017 opa334

#import "Download.h"
#import "downloadManager.h"

@implementation downloadManager

+ (instancetype)sharedInstance
{
    static downloadManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,
    ^{
      //Initialise instance and properties
      sharedInstance = [[downloadManager alloc] init];
      sharedInstance.downloads = [NSMutableArray new];

      //Create message center to communicate with SpringBoard through RocketBootstrap
      CPDistributedMessagingCenter* tmpCenter = [%c(CPDistributedMessagingCenter) centerNamed:@"com.opa334.SafariPlus.MessagingCenter"];
      rocketbootstrap_distributedmessagingcenter_apply(tmpCenter);

      //Set message center to property
      sharedInstance.SPMessagingCenter = tmpCenter;
    });
    return sharedInstance;
}

- (NSMutableArray*)getDownloadsForPath:(NSURL*)path
{
  //Return pending downloads of given path
  NSMutableArray* downloadsForPath = [NSMutableArray new];
  for(Download* download in self.downloads)
  {
    if([download.filePath.path isEqualToString:path.path])
    {
      [downloadsForPath addObject:download];
    }
  }
  return downloadsForPath;
}

- (void)removeDownloadWithIdentifier:(NSString*)identifier
{
  for(Download* download in self.downloads)
  {
    if([download.identifier isEqualToString:identifier])
    {
      //Identifier is equal -> remove download from array
      [self.downloads removeObject:download];
      return;
    }
  }
}

- (NSString*)generateIdentifier
{
  //Generate random identifier for download
  NSString* bundleID = @"com.opa334.SafariPlus.download";
  NSString* UUID = [[NSUUID UUID] UUIDString];
  return [NSString stringWithFormat:@"%@-%@", bundleID, UUID];
}

- (void)prepareDownloadFromRequest:(NSURLRequest*)request withSize:(int64_t)size fileName:(NSString*)fileName
{
  [self prepareDownloadFromRequest:request withSize:size fileName:fileName customPath:NO];
}

- (void)prepareDownloadFromRequest:(NSURLRequest*)request withSize:(int64_t)size fileName:(NSString*)fileName customPath:(BOOL)customPath
{
  NSURL* path;
  if(!customPath)
  {
    if(preferenceManager.customDefaultPathEnabled)
    {
      //Get path from preferences
      path = [NSURL fileURLWithPath:[NSString stringWithFormat:@"/User%@", preferenceManager.customDefaultPath]];
      BOOL isDir;
      BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[path path] isDirectory:&isDir];

      //Check if path is valid
      if(!isDir || !exists)
      {
        //If path is invalid, present an error message and return
        UIAlertController *errorAlert = [UIAlertController
          alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"ERROR"]
          message:[localizationManager localizedSPStringForKey:@"CUSTOM_DEFAULT_PATH_ERROR_MESSAGE"]
          preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
          style:UIAlertActionStyleDefault handler:nil];

        [errorAlert addAction:okAction];

        [self.rootControllerDelegate presentViewController:errorAlert];
        return;
      }
    }
    else
    {
      //Choose default path
      path = [NSURL fileURLWithPath:@"/User/Downloads/"];
    }
  }
  else
  {
    if(preferenceManager.pinnedLocationsEnabled)
    {
      NSMutableDictionary* plist = [[NSMutableDictionary alloc] initWithContentsOfFile:otherPlistPath];

      NSArray* PinnedLocationNames = [NSArray new];
      NSArray* PinnedLocationPaths = [NSArray new];
      PinnedLocationNames = [plist objectForKey:@"PinnedLocationNames"];
      PinnedLocationPaths = [plist objectForKey:@"PinnedLocationPaths"];

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
            textField.text = fileName;
        	}];

          UIAlertAction* chooseAction = [UIAlertAction actionWithTitle:
            [localizationManager localizedSPStringForKey:@"CHOOSE"]
            style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
          {
            NSString* newFilename = filenameAlert.textFields[0].text;

            //Resolve possible symlinks
            path = path.URLByResolvingSymlinksInPath;

            //Do some magic to fix up the path (why apple?)
            path = [NSURL fileURLWithPath:[[path path] stringByReplacingOccurrencesOfString:@"/var" withString:@"/private/var"]];

            //Check if file already exists
            if([[NSFileManager defaultManager] fileExistsAtPath:[[path URLByAppendingPathComponent:fileName] path]])
            {
              //File exists -> Present alert
              [self presentFileExistsAlert:request size:size fileName:newFilename path:path];
            }
            else
            {
              //File doesn't exist -> start download
              [self startDownloadFromRequest:request size:size fileName:newFilename path:path shouldReplace:NO];
            }
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
        //User chose to pick a custom path -> present directory picker
        directoryPickerNavigationController* directoryPicker =
          [[directoryPickerNavigationController alloc] initWithRequest:request
          size:size path:path fileName:fileName];

        [self.rootControllerDelegate presentViewController:directoryPicker];
      }];

      [pinnedLocationAlert addAction:browseAction];

      UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:
        [localizationManager localizedSPStringForKey:@"CANCEL"]
        style:UIAlertActionStyleCancel handler:nil];

      [pinnedLocationAlert addAction:cancelAction];

      [self.rootControllerDelegate presentViewController:pinnedLocationAlert];
    }
    else
    {
      //User chose to pick a custom path -> present directory picker
      directoryPickerNavigationController* directoryPicker =
        [[directoryPickerNavigationController alloc] initWithRequest:request
        size:size path:path fileName:fileName];

      [self.rootControllerDelegate presentViewController:directoryPicker];
    }
    return;
  }

  //Resolve possible symlinks
  path = path.URLByResolvingSymlinksInPath;

  //Do some magic to fix up the path (why apple?)
  path = [NSURL fileURLWithPath:[[path path] stringByReplacingOccurrencesOfString:@"/var" withString:@"/private/var"]];

  //Check if file already exists
  if([[NSFileManager defaultManager] fileExistsAtPath:[[path URLByAppendingPathComponent:fileName] path]])
  {
    //File exists -> Present alert
    [self presentFileExistsAlert:request size:size fileName:fileName path:path];
  }
  else
  {
    //File doesn't exist -> start download
    [self startDownloadFromRequest:request size:size fileName:fileName path:path shouldReplace:NO];
  }
}

- (void)prepareImageDownload:(UIImage*)image fileName:(NSString*)fileName
{
  if(preferenceManager.pinnedLocationsEnabled)
  {
    NSMutableDictionary* plist = [[NSMutableDictionary alloc] initWithContentsOfFile:otherPlistPath];

    NSArray* PinnedLocationNames = [NSArray new];
    NSArray* PinnedLocationPaths = [NSArray new];
    PinnedLocationNames = [plist objectForKey:@"PinnedLocationNames"];
    PinnedLocationPaths = [plist objectForKey:@"PinnedLocationPaths"];

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
          textField.text = fileName;
        }];

        UIAlertAction* chooseAction = [UIAlertAction actionWithTitle:
          [localizationManager localizedSPStringForKey:@"CHOOSE"]
          style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
        {
          NSString* newFilename = filenameAlert.textFields[0].text;

          //Resolve possible symlinks
          path = path.URLByResolvingSymlinksInPath;

          //Do some magic to fix up the path (why apple?)
          path = [NSURL fileURLWithPath:[[path path] stringByReplacingOccurrencesOfString:@"/var" withString:@"/private/var"]];

          //Check if image already exists
          if([[NSFileManager defaultManager] fileExistsAtPath:[[path URLByAppendingPathComponent:newFilename] path]])
          {
            //Image exists -> Present alert
            [self presentFileExistsAlert:nil size:0 fileName:newFilename path:path isImage:YES image:image];
          }
          else
          {
            //Image doesn't exist -> save it
            [self saveImage:image fileName:newFilename path:path shouldReplace:NO];
          }
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
      //Present directory picker for image download
      directoryPickerNavigationController* directoryPicker =
        [[directoryPickerNavigationController alloc] initWithImage:image
        fileName:fileName];

      [self.rootControllerDelegate presentViewController:directoryPicker];
    }];

    [pinnedLocationAlert addAction:browseAction];

    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:
      [localizationManager localizedSPStringForKey:@"CANCEL"]
      style:UIAlertActionStyleCancel handler:nil];

    [pinnedLocationAlert addAction:cancelAction];

    [self.rootControllerDelegate presentViewController:pinnedLocationAlert];
  }
  else
  {
    //Present directory picker for image download
    directoryPickerNavigationController* directoryPicker =
      [[directoryPickerNavigationController alloc] initWithImage:image
      fileName:fileName];

    [self.rootControllerDelegate presentViewController:directoryPicker];
  }
}

- (void)presentFileExistsAlert:(NSURLRequest*)request size:(int64_t)size fileName:(NSString*)fileName path:(NSURL*)path
{
  [self presentFileExistsAlert:request size:size fileName:fileName path:path isImage:NO image:nil];
}

- (void)presentFileExistsAlert:(NSURLRequest*)request size:(int64_t)size fileName:(NSString*)fileName path:(NSURL*)path isImage:(BOOL)isImage image:(UIImage*)image;
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
    if(isImage)
    {
      //Download is image -> save image and replace existing image
      [self saveImage:image fileName:fileName path:path shouldReplace:YES];
    }
    else
    {
      //Download is regular file -> start file download abd replace existing file
      [self startDownloadFromRequest:request size:size fileName:fileName path:path shouldReplace:YES];
    }
  }];

  //Change path action
  UIAlertAction *changePathAction = [UIAlertAction
    actionWithTitle:[localizationManager localizedSPStringForKey:@"CHANGE_PATH"]
    style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
  {
    if(isImage)
    {
      //Fallback to preparation
      [self prepareImageDownload:image fileName:fileName];
    }
    else
    {
      //Fallback to preparation with custom path
      [self prepareDownloadFromRequest:request withSize:size fileName:fileName customPath:YES];
    }
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

- (void)handleDirectoryPickerResponse:(NSURLRequest*)request size:(int64_t)size fileName:(NSString*)fileName path:(NSURL*)path
{
  //Check if file already exists
  if([[NSFileManager defaultManager] fileExistsAtPath:[[path URLByAppendingPathComponent:fileName] path]])
  {
    //File exists -> Present alert
    [self presentFileExistsAlert:request size:size fileName:fileName path:path];
  }
  else
  {
    //File doesn't exist -> start download
    [self startDownloadFromRequest:request size:size fileName:fileName path:path shouldReplace:NO];
  }
}

- (void)handleDirectoryPickerImageResponse:(UIImage*)image fileName:(NSString*)fileName path:(NSURL*)path
{
  //Check if image already exists
  if([[NSFileManager defaultManager] fileExistsAtPath:[[path URLByAppendingPathComponent:fileName] path]])
  {
    //Image exists -> Present alert
    [self presentFileExistsAlert:nil size:0 fileName:fileName path:path isImage:YES image:image];
  }
  else
  {
    //Image doesn't exist -> save it
    [self saveImage:image fileName:fileName path:path shouldReplace:NO];
  }
}

- (void)startDownloadFromRequest:(NSURLRequest*)request size:(int64_t)size fileName:(NSString*)fileName path:(NSURL*)path shouldReplace:(BOOL)shouldReplace
{
  //Initialise download with needed properties, start it and add it to array
  Download* download = [[Download alloc] init];
  download.downloadManagerDelegate = self;
  download.fileSize = size;
  download.fileName = fileName;
  download.filePath = path;
  download.replaceFile = shouldReplace;
  download.identifier = [self generateIdentifier];
  [download startDownloadFromRequest:request];
  [self.downloads addObject:download];

  //Dispatch status bar / push notification
  [self dispatchNotificationWithText:
    [NSString stringWithFormat:@"%@: %@", [localizationManager
    localizedSPStringForKey:@"DOWNLOAD_STARTED"], fileName]];
}

- (void)saveImage:(UIImage*)image fileName:(NSString*)fileName path:(NSURL*)path shouldReplace:(BOOL)shouldReplace
{
  //Create filePath using path and fileName
  NSString* filePath = [[path URLByAppendingPathComponent:fileName] path];

  if(shouldReplace)
  {
    //Image should be replaced -> delete existing image
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
  }

  //Write image to file
  [UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES];

  [self dispatchNotificationWithText:
    [NSString stringWithFormat:@"%@: %@", [localizationManager
    localizedSPStringForKey:@"SAVED_IMAGE"], fileName]];
}

- (void)downloadFinished:(Download*)download withLocation:(NSURL*)location
{
  //Remove download from array
  [self removeDownloadWithIdentifier:download.identifier];

  //Get path of desired location
  NSURL* path = [download.filePath URLByAppendingPathComponent:download.fileName];

  if(download.replaceFile)
  {
    //File should be replaced -> delete existing file
    [[NSFileManager defaultManager] removeItemAtPath:[path path] error:nil];
  }

  //Move downloaded file to desired location
  [[NSFileManager defaultManager] moveItemAtURL:location toURL:path error:nil];

  //Dispatch status bar / push notification
  [self dispatchNotificationWithText:[NSString stringWithFormat:@"%@: %@",
    [localizationManager localizedSPStringForKey:@"DOWNLOAD_SUCCESS"], download.fileName]];

  //Reload entries if currently inside downloadsView
  [self.downloadTableDelegate reloadDataAndDataSources];

  //nil out download
  download = nil;
}

- (void)downloadCancelled:(Download*)download
{
  //Remove download from array
  [self removeDownloadWithIdentifier:download.identifier];

  //nil out download
  download = nil;

  //Reload entries if currently inside downloadsView
  [self.downloadTableDelegate reloadDataAndDataSources];
}

- (void)dispatchNotificationWithText:(NSString*)text
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

@end
