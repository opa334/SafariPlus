// Application.xm
// (c) 2017 opa334

#import "../SafariPlus.h"

%hook Application

%new
- (void)application:(UIApplication *)application
  handleEventsForBackgroundURLSession:(NSString *)identifier
  completionHandler:(void (^)(void))completionHandler
{
  //The bare existence of this method causes background downloads to finish properly...
  //didFinishDownloadingToURL gets called, don't ask me why tho :D
  //Otherwise files would only be moved on the next app-resume
  //I presume the application only gets resumed if this method exists

  dispatch_async(dispatch_get_main_queue(),
  ^{
    completionHandler();
  });
}

- (BOOL)application:(id)arg1 didFinishLaunchingWithOptions:(id)arg2
{
  loadOtherPlist();

  //Init plist for desktop button
  if(preferenceManager.desktopButtonEnabled)
  {
    if(![[otherPlist allKeys] containsObject:@"desktopButtonSelected"])
    {
      //Set BOOL to false
      desktopButtonSelected = NO;

      //Add BOOL to dictionary
      [otherPlist setObject:[NSNumber numberWithBool:desktopButtonSelected]
        forKey:@"desktopButtonSelected"];

      //Save changes
      saveOtherPlist();
    }
    else
    {
      //Get bool from plist and set it to desktopButtonSelected
      desktopButtonSelected = [[otherPlist objectForKey:@"desktopButtonSelected"] boolValue];
    }
  }

  BOOL orig = %orig;

  //Auto switch mode on launch
  if(preferenceManager.forceModeOnStartEnabled)
  {
    //Switch mode to specified mode
    [mainBrowserController() modeSwitchAction:preferenceManager.forceModeOnStartFor];
  }

  if(preferenceManager.desktopButtonEnabled)
  {
    //Reload tabs
    [mainBrowserController().tabController reloadTabsIfNeeded];
  }


  if(preferenceManager.enhancedDownloadsEnabled)
  {
    NSString* downloadPath = defaultDownloadPath;
    if(![[NSFileManager defaultManager] fileExistsAtPath:downloadPath])
    {
      //Downloads directory doesn't exist -> create it
      [[NSFileManager defaultManager] createDirectoryAtPath:downloadPath
        withIntermediateDirectories:NO attributes:nil error:nil];
    }
  }

  return orig;
}

//Auto switch mode on app resume
- (void)applicationWillEnterForeground:(id)arg1
{
  %orig;
  if(preferenceManager.forceModeOnResumeEnabled)
  {
    //Switch mode to specified mode
    [mainBrowserController() modeSwitchAction:preferenceManager.forceModeOnResumeFor];
  }
}

//Auto switch mode on external URL opened
- (void)applicationOpenURL:(id)arg1
{
  if(preferenceManager.forceModeOnExternalLinkEnabled && arg1)
  {
    //Switch mode to specified mode
    [mainBrowserController() modeSwitchAction:preferenceManager.forceModeOnExternalLinkFor];
  }

  %orig;
}

//Auto close tabs when Safari gets closed
- (void)applicationWillTerminate
{
  if(preferenceManager.autoCloseTabsEnabled &&
    preferenceManager.autoCloseTabsOn == 1 /*Safari closed*/)
  {
    [mainBrowserController() autoCloseAction];
  }

  if(preferenceManager.autoDeleteDataEnabled &&
    preferenceManager.autoDeleteDataOn == 1 /*Safari closed*/)
  {
    //Clear browser data
    [mainBrowserController() clearData];
  }

  %orig;
}

//Auto close tabs when Safari gets minimized
- (void)applicationDidEnterBackground:(id)arg1
{
  if(preferenceManager.autoCloseTabsEnabled &&
    preferenceManager.autoCloseTabsOn == 2 /*Safari minimized*/)
  {
    //Close all tabs for specified modes
    [mainBrowserController() autoCloseAction];
  }

  if(preferenceManager.autoDeleteDataEnabled &&
    preferenceManager.autoDeleteDataOn == 2 /*Safari closed*/)
  {
    //Clear browser data
    [mainBrowserController() clearData];
  }

  %orig;
}

%end
