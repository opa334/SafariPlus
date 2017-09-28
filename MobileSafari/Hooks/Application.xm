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
    switch(iOSVersion)
    {
      case 9:
      //Switch mode to specified mode
      [MSHookIvar<BrowserController*>(self, "_controller")
        modeSwitchAction:preferenceManager.forceModeOnStartFor];
      break;

      case 10:
      //Switch mode to specified mode
      [self.shortcutController.browserController
        modeSwitchAction:preferenceManager.forceModeOnStartFor];
      break;
    }
  }

  if(preferenceManager.desktopButtonEnabled)
  {
    switch(iOSVersion)
    {
      case 9:
      //Reload tabs
      [MSHookIvar<BrowserController*>(self, "_controller").tabController reloadTabsIfNeeded];
      break;

      case 10:
      //Reload tabs
      [self.shortcutController.browserController.tabController reloadTabsIfNeeded];
      break;
    }
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
    switch(iOSVersion)
    {
      case 9:
      //Switch mode to specified mode
      [MSHookIvar<BrowserController*>(self, "_controller")
        modeSwitchAction:preferenceManager.forceModeOnResumeFor];
      break;

      case 10:
      //Switch mode to specified mode
      [self.shortcutController.browserController
        modeSwitchAction:preferenceManager.forceModeOnResumeFor];
      break;
    }
  }
}

//Auto switch mode on external URL opened
- (void)applicationOpenURL:(id)arg1
{
  if(preferenceManager.forceModeOnExternalLinkEnabled && arg1)
  {
    switch(iOSVersion)
    {
    case 9:
    //Switch mode to specified mode
    [MSHookIvar<BrowserController*>(self, "_controller")
      modeSwitchAction:preferenceManager.forceModeOnExternalLinkFor];
    break;

    case 10:
    //Switch mode to specified mode
    [self.shortcutController.browserController
      modeSwitchAction:preferenceManager.forceModeOnExternalLinkFor];
    break;
    }
  }

  %orig;
}

//Auto close tabs when Safari gets closed
- (void)applicationWillTerminate
{
  if(preferenceManager.autoCloseTabsEnabled &&
    preferenceManager.autoCloseTabsOn == 1 /*Safari closed*/)
  {
    switch(iOSVersion)
    {
      case 9:
      //Close all tabs for specified modes
      [MSHookIvar<BrowserController*>(self, "_controller") autoCloseAction];
      break;

      case 10:
      //Close all tabs for specified modes
      [self.shortcutController.browserController autoCloseAction];
      break;
    }
  }

  if(preferenceManager.autoDeleteDataEnabled &&
    preferenceManager.autoDeleteDataOn == 1 /*Safari closed*/)
  {
    switch(iOSVersion)
    {
      case 9:
      //Clear browser data
      [MSHookIvar<BrowserController*>(self, "_controller") clearData];
      break;

      case 10:
      //Clear browser data
      [self.shortcutController.browserController clearData];
      break;
    }
  }

  %orig;
}

//Auto close tabs when Safari gets minimized
- (void)applicationDidEnterBackground:(id)arg1
{
  if(preferenceManager.autoCloseTabsEnabled &&
    preferenceManager.autoCloseTabsOn == 2 /*Safari minimized*/)
  {
    switch(iOSVersion)
    {
      case 9:
      //Close all tabs for specified modes
      [MSHookIvar<BrowserController*>(self, "_controller") autoCloseAction];
      break;

      case 10:
      //Close all tabs for specified modes
      [self.shortcutController.browserController autoCloseAction];
      break;
    }
  }

  if(preferenceManager.autoDeleteDataEnabled &&
    preferenceManager.autoDeleteDataOn == 2 /*Safari closed*/)
  {
    switch(iOSVersion)
    {
      case 9:
      //Clear browser data
      [MSHookIvar<BrowserController*>(self, "_controller") clearData];
      break;

      case 10:
      //Clear browser data
      [self.shortcutController.browserController clearData];
      break;
    }
  }

  %orig;
}

%end
