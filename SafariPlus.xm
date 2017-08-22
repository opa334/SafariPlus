//  SafariPlus.xm
// (c) 2017 opa334

#import "SafariPlus.h"

//Macro for setting the current browsing mode state to privateMode
#define getBrowsingMode                                          \
switch(iOSVersion)                                               \
{                                                                \
  case 9:                                                        \
  privateMode = [((Application*)[%c(Application)                 \
    sharedApplication]).shortcutController.browserController     \
    privateBrowsingEnabled];                                     \
  break;                                                         \
                                                                 \
  case 10:                                                       \
  privateMode = [((Application*)[%c(Application)                 \
    sharedApplication]).shortcutController.browserController     \
    privateBrowsingEnabled];                                     \
  break;                                                         \
}                                                                \

/****** Variables ******/

//preferenceManager and localizationManager
SPPreferenceManager* preferenceManager = [SPPreferenceManager sharedInstance];
SPLocalizationManager* localizationManager = [SPLocalizationManager sharedInstance];

//Bundles for localization
NSBundle* MSBundle = [NSBundle mainBundle];
NSBundle* SPBundle = [NSBundle bundleWithPath:
  @"/Library/Application Support/SafariPlus.bundle"];

//Bool for desktopButton state
BOOL desktopButtonSelected;

//Contains iOS Version (9, 10)
int iOSVersion;

/****** Safari Hooks ******/

%group iOS10

%hook BrowserController

//Present downloads view
%new
- (void)downloadsFromButtonBar
{
  //Create downloadsNavigationController
  downloadsNavigationController* downloadsController =
    [[downloadsNavigationController alloc] init];

  dispatch_async(dispatch_get_main_queue(), ^
  {
    //Present downloadsNavigationController
    [self.rootViewController presentViewController:downloadsController animated:YES completion:^
    {
      if([((downloadsTableViewController*)
        downloadsController.visibleViewController).downloadsAtCurrentPath count] != 0)
      {
        //Fix stuck download if a download finishes while the view presents
        [(downloadsTableViewController*)
          downloadsController.visibleViewController reloadDataAndDataSources];
      }
    }];
  });
}

//URL Swipe actions
%new
- (void)handleSwipe:(NSInteger)swipeAction
{
  //Some cases need cleaing -> Create bool for that
  __block BOOL shouldClean = NO;

  switch(swipeAction)
  {
    case 1: //Close active tab
    [self.tabController.activeTabDocument _closeTabDocumentAnimated:NO];
    shouldClean = YES;
    break;

    case 2: //Open new tab
    [self.tabController newTab];
    break;

    case 3: //Duplicate active tab
    [self loadURLInNewTab:[self.tabController.activeTabDocument URL]
      inBackground:preferenceManager.gestureBackground animated:YES];
    break;

    case 4: //Close all tabs from active mode
    [self.tabController closeAllOpenTabsAnimated:NO exitTabView:YES];
    shouldClean = YES;
    break;

    case 5: //Switch mode (Normal/Private)
    [self togglePrivateBrowsing];
    shouldClean = YES;
    break;

    case 6: //Tab backward
    {
      //Get index of previous tab
      NSInteger tabIndex = [self.tabController.currentTabDocuments
        indexOfObject:self.tabController.activeTabDocument] - 1;

      if(tabIndex >= 0)
      {
        //tabIndex is not smaller than 0 -> switch to previous tab
        [self.tabController
          setActiveTabDocument:self.tabController.currentTabDocuments[tabIndex] animated:NO];
      }
      break;
    }

    case 7: //Tab forward
    {
      //Get index of next tab
      NSInteger tabIndex = [self.tabController.currentTabDocuments
        indexOfObject:self.tabController.activeTabDocument] + 1;

      if(tabIndex < [self.tabController.currentTabDocuments count])
      {
        //tabIndex is not bigger than array -> switch to next tab
        [self.tabController
          setActiveTabDocument:self.tabController.currentTabDocuments[tabIndex] animated:NO];
      }
      break;
    }

    case 8: //Reload active tab
    [self.tabController.activeTabDocument reload];
    break;

    case 9: //Request desktop site
    [self.tabController.activeTabDocument.reloadOptionsController requestDesktopSite];
    break;

    case 10: //Open 'find on page'
    [self.tabController.activeTabDocument.findOnPageView setShouldFocusTextField:YES];
    [self.tabController.activeTabDocument.findOnPageView showFindOnPage];
    break;

    default:
    break;
  }
  if(shouldClean && [self privateBrowsingEnabled])
  {
    //Remove private mode message
    [self.tabController.tiltedTabView setShowsExplanationView:NO animated:NO];
  }
}

%end

%hook BrowserRootViewController

//Initialise status bar notifications
- (void)viewDidLoad
{
  %orig;
  if(preferenceManager.enhancedDownloadsEnabled)
  {
    //Set downloadManager delegate to self for communication
    [downloadManager sharedInstance].rootControllerDelegate = self;

    if(!preferenceManager.disableBarNotificationsEnabled && !self.statusBarNotification)
    {
      //Create Status Bar Notification and set up properties
      self.statusBarNotification = [CWStatusBarNotification new];
      self.statusBarNotification.notificationLabelBackgroundColor = [UIColor blueColor];
      self.statusBarNotification.notificationAnimationInStyle = CWNotificationAnimationStyleTop;
      self.statusBarNotification.notificationAnimationOutStyle = CWNotificationAnimationStyleTop;
    }
  }
}

%end

%hook TabDocument

//Supress mailTo alert
- (void)dialogController:(_SFDialogController*)dialogController
  willPresentDialog:(_SFDialog*)dialog
{
  if(preferenceManager.suppressMailToDialog && [[self URL].scheme isEqualToString:@"mailto"])
  {
    //Simulate press on yes button
    [dialog finishWithPrimaryAction:YES text:dialog.defaultText];

    //Dismiss dialog
    [dialogController _dismissDialog];
  }
  else
  {
    %orig;
  }
}

//Extra 'Open in new Tab' option + 'Download to option'
- (NSMutableArray*)_actionsForElement:(_WKActivatedElementInfo*)arg1
  defaultActions:(NSArray*)arg2 previewViewController:(id)arg3
{
  if(preferenceManager.enhancedDownloadsEnabled ||
    preferenceManager.openInNewTabOptionEnabled)
  {
    NSMutableArray* options = %orig;

    //Get state of tabBar from tabController
    BOOL tabBar = ((Application*) [%c(Application)
      sharedApplication]).shortcutController.browserController.tabController.usesTabBar;

    if(preferenceManager.openInNewTabOptionEnabled && arg1.type == 0 && !tabBar)
    {
      //Long pressed element is link & tabBar is not used
      //-> Create in new tab option to alert
      _WKElementAction* openInNewTabAction = [%c(_WKElementAction)
        elementActionWithTitle:[localizationManager
        localizedMSStringForKey:@"Open Link in New Tab"] actionHandler:
      ^{
        //Open URL in new tab
        [self.browserController loadURLInNewTab:arg1.URL inBackground:NO];
      }];

      //Add option to alert
      [options insertObject:openInNewTabAction atIndex:1];
    }

    if(preferenceManager.enhancedDownloadsEnabled)
    {
      //EnhancedDownloads are enabled -> create 'Download to ...' option
      _WKElementAction* downloadToAction = [%c(_WKElementAction)
        elementActionWithTitle:[localizationManager
        localizedSPStringForKey:@"DOWNLOAD_TO"] actionHandler:^
      {
        switch(arg1.type)
        {
          case 0: //Link long pressed
          {
            //Create download request from URL
            NSURLRequest* downloadRequest = [NSURLRequest requestWithURL:arg1.URL];

            //Call downloadManager with request
            [[downloadManager sharedInstance]
              prepareDownloadFromRequest:downloadRequest withSize:0
              fileName:@"site.html" customPath:YES];
            break;
          }
          case 1: //Image long pressed
          {
            //Call downloadManager with image
            [[downloadManager sharedInstance] prepareImageDownload:arg1.image
              fileName:@"image.png"];
            break;
          }
          default:
          break;
        }
      }];

      switch(arg1.type)
      {
        case 0: //Link long pressed
        {
          //Add option to alert before share option
          [options insertObject:downloadToAction atIndex:[options count] - 1];
          break;
        }
        case 1: //Image long pressed
        {
          //Add option to alert
          [options addObject:downloadToAction];
          break;
        }
        default:
        break;
      }
    }

    return options;
  }

  return %orig;
}

%end

%hook NavigationBar

//Lock icon color
- (id)_tintForLockImage:(BOOL)arg1
{
  if(preferenceManager.lockIconColorNormalEnabled ||
    preferenceManager.lockIconColorPrivateEnabled)
  {
    //Get browsing mode (iOS10)
    BOOL privateMode = [((Application*)[%c(Application)
      sharedApplication]).shortcutController.browserController
      privateBrowsingEnabled];

    if(preferenceManager.lockIconColorNormalEnabled && !privateMode)
    {
      //Replace color with the specified one
      return LCPParseColorString(preferenceManager.lockIconColorNormal, @"#FFFFFF");
    }
    else if(preferenceManager.lockIconColorPrivateEnabled && privateMode)
    {
      //Replace color with the specified one
      return LCPParseColorString(preferenceManager.lockIconColorPrivate, @"#FFFFFF");
    }
  }

  return %orig;
}

%end

%end

%group iOS9

%hook BrowserController

//Present downloads view
%new
- (void)downloadsFromButtonBar
{
  //Create downloadsNavigationController
  downloadsNavigationController* downloadsController =
    [[downloadsNavigationController alloc] init];

  dispatch_async(dispatch_get_main_queue(), ^
  {
    //Present downloadsNavigationController
    [MSHookIvar<BrowserRootViewController*>(self, "_rootViewController")
      presentViewController:downloadsController animated:YES completion:^
    {
      if([((downloadsTableViewController*)
        downloadsController.visibleViewController).downloadsAtCurrentPath
        count] != 0)
      {
        //Fixes stuck download if the download finishes while the view presents
        [(downloadsTableViewController*)downloadsController.visibleViewController
          reloadDataAndDataSources];
      }
    }];
  });
}

//URL Swipe actions
%new
- (void)handleSwipe:(NSInteger)swipeAction
{
  //Some cases need cleaing -> Create bool for that
  __block BOOL shouldClean = NO;

  switch(swipeAction)
  {
    case 1: //Close active tab
    [self.tabController.activeTabDocument _closeTabDocumentAnimated:NO];
    shouldClean = YES;
    break;

    case 2: //Open new tab
    [self.tabController newTab];
    break;

    case 3: //Duplicate active tab
    [self loadURLInNewWindow:[self.tabController.activeTabDocument URL]
      inBackground:preferenceManager.gestureBackground animated:YES];
    break;

    case 4: //Close all tabs from active mode
    [self.tabController closeAllOpenTabsAnimated:NO exitTabView:YES];
    shouldClean = YES;
    break;

    case 5: //Switch mode (Normal/Private)
    [self togglePrivateBrowsing];
    shouldClean = YES;
    break;

    case 6: //Tab backward
    {
      NSArray* currentTabs;
      if([self privateBrowsingEnabled])
      {
        //Private mode enabled -> set currentTabs to tabs of private mode
        currentTabs = self.tabController.privateTabDocuments;
      }
      else
      {
        //Private mode disabled -> set currentTabs to tabs of normal mode
        currentTabs = self.tabController.tabDocuments;
      }

      //Get index of previous tab
      NSInteger tabIndex = [currentTabs
        indexOfObject:self.tabController.activeTabDocument] - 1;

      if(tabIndex >= 0)
      {
        //tabIndex is not smaller than 0 -> switch to previous tab
        [self.tabController setActiveTabDocument:currentTabs[tabIndex] animated:NO];
      }
      break;
    }

    case 7: //Tab forward
    {
      NSArray* currentTabs;
      if([self privateBrowsingEnabled])
      {
        //Private mode enabled -> set currentTabs to tabs of private mode
        currentTabs = self.tabController.privateTabDocuments;
      }
      else
      {
        //Private mode disabled -> set currentTabs to tabs of normal mode
        currentTabs = self.tabController.tabDocuments;
      }

      //Get index of next tab
      NSInteger tabIndex = [currentTabs
        indexOfObject:self.tabController.activeTabDocument] + 1;

      if(tabIndex < [currentTabs count])
      {
        //tabIndex is not bigger than array -> switch to next tab
        [self.tabController setActiveTabDocument:currentTabs[tabIndex] animated:NO];
      }
      break;
    }

    case 8: //Reload active tab
    [self.tabController.activeTabDocument reload];
    break;

    case 9: //Request desktop site
    [self.tabController.activeTabDocument.reloadOptionsController requestDesktopSite];
    break;

    case 10: //Open 'find on page'
    self.shouldFocusFindOnPageTextField = YES;
    [self showFindOnPage];
    break;

    default:
    break;
  }
  if(shouldClean && [self privateBrowsingEnabled])
  {
    //Remove private mode message
    [self.tabController.tiltedTabView setShowsExplanationView:NO animated:NO];
  }
}

%end

%hook BrowserRootViewController

//Initialise status bar notifications
- (id)init
{
  self = %orig;
  if(preferenceManager.enhancedDownloadsEnabled)
  {
    //Set downloadManager delegate to self for communication
    [downloadManager sharedInstance].rootControllerDelegate = self;

    if(!preferenceManager.disableBarNotificationsEnabled)
    {
      //Create Status Bar Notification and set up properties
      self.statusBarNotification = [CWStatusBarNotification new];
      self.statusBarNotification.notificationLabelBackgroundColor = [UIColor blueColor];
      self.statusBarNotification.notificationAnimationInStyle = CWNotificationAnimationStyleTop;
      self.statusBarNotification.notificationAnimationOutStyle = CWNotificationAnimationStyleTop;
    }
  }
  return self;
}

%end

%hook TabDocument

//Extra 'Open in new Tab' option + 'Download to option'
- (NSMutableArray*)_actionsForElement:(_WKActivatedElementInfo*)arg1
  defaultActions:(NSArray*)arg2 previewViewController:(id)arg3
{
  if(preferenceManager.enhancedDownloadsEnabled ||
    preferenceManager.openInNewTabOptionEnabled)
  {
    NSMutableArray* options = %orig;

    //Get state of tabBar from tabController
    BOOL tabBar = MSHookIvar<BrowserController*>(((Application*)[%c(Application)
      sharedApplication]), "_controller").tabController.usesTabBar;

    if(preferenceManager.openInNewTabOptionEnabled &&
      (arg1.type == 120259084288 || arg1.type == 0) && !tabBar)
    {
      //Long pressed element is link & tabBar is not used
      //-> Create in new tab option to alert
      _WKElementAction* openInNewTabAction = [%c(_WKElementAction)
        elementActionWithTitle:[localizationManager
        localizedMSStringForKey:@"Open Link in New Tab"] actionHandler:
      ^{
        //Get browserController
        BrowserController* browserController =
          MSHookIvar<BrowserController*>(self, "_browserController");

        //Open URL in new tab
        [browserController loadURLInNewWindow:arg1.URL inBackground:NO];
      }];

      //Add option to alert
      [options insertObject:openInNewTabAction atIndex:1];
    }

    if(preferenceManager.enhancedDownloadsEnabled)
    {
      //EnhancedDownloads are enabled -> create 'Download to ...' option
      _WKElementAction* downloadToAction = [%c(_WKElementAction)
        elementActionWithTitle:[localizationManager
        localizedSPStringForKey:@"DOWNLOAD_TO"] actionHandler:^
      {
        switch(arg1.type)
        {
          case 0: //Link long pressed (Just making sure not to break it on some devices?)
          case 120259084288: //I'm not really sure why these are the numbers on iOS9
          {
            //Create download request from URL
            NSURLRequest* downloadRequest = [NSURLRequest requestWithURL:arg1.URL];

            //Call downloadManager with request
            [[downloadManager sharedInstance]
              prepareDownloadFromRequest:downloadRequest withSize:0
              fileName:@"site.html" customPath:YES];
            break;
          }
          case 1: //Image long pressed
          case 120259084289:
          {
            //Call downloadManager with image
            [[downloadManager sharedInstance] prepareImageDownload:arg1.image
              fileName:@"image.png"];
            break;
          }
          default:
          break;
        }
      }];

      switch(arg1.type)
      {
        case 0: //Link long pressed
        case 120259084288:
        {
          //Add option to alert before share option
          [options insertObject:downloadToAction atIndex:[options count] - 1];
          break;
        }
        case 1: //Image long pressed
        case 120259084289:
        {
          //Add option to alert
          [options addObject:downloadToAction];
          break;
        }
        default:
        break;
      }
    }

    return options;
  }

  return %orig;
}

%end

%hook NavigationBar

//Lock icon color
- (id)_lockImageWithTint:(id)arg1 usingMiniatureVersion:(BOOL)arg2
{
  if(preferenceManager.lockIconColorNormalEnabled ||
    preferenceManager.lockIconColorPrivateEnabled)
  {
    //Get browsing mode (iOS9)
    BOOL privateMode = [((Application*)[%c(Application)
      sharedApplication]).shortcutController.browserController
      privateBrowsingEnabled];

    if(preferenceManager.lockIconColorNormalEnabled && !privateMode)
    {
      //Replace color with the specified one
      arg1 = LCPParseColorString(preferenceManager.lockIconColorNormal, @"#FFFFFF");
    }
    else if(preferenceManager.lockIconColorPrivateEnabled && privateMode)
    {
      //Replace color with the specified one
      arg1 = LCPParseColorString(preferenceManager.lockIconColorPrivate, @"#FFFFFF");
    }
    return %orig(arg1, arg2);
  }

  return %orig;
}

%end

%end

%hook Application

%new
- (void)application:(UIApplication *)application
  handleEventsForBackgroundURLSession:(NSString *)identifier
  completionHandler:(void (^)(void))completionHandler
{
  //The bare existence of this method causes background downloads to finish properly...
  //didFinishDownloadingToURL gets called, don't ask me why tho :D
  //Otherwise files would only be moved on the next app-resume
  //I presume the application gets resumed if this method exists

  dispatch_async(dispatch_get_main_queue(),
  ^{
    completionHandler();
  });
}

- (BOOL)application:(id)arg1 didFinishLaunchingWithOptions:(id)arg2
{
  //Init plist for desktop button
  if(preferenceManager.desktopButtonEnabled)
  {
    if(![[NSFileManager defaultManager] fileExistsAtPath:otherPlistPath])
		{
      //Create plist if it does not exist already
			[@{} writeToFile:otherPlistPath atomically:NO];
		}

    //Get dictionary from plist
    NSMutableDictionary* otherPlist = [[NSMutableDictionary alloc]
      initWithContentsOfFile:otherPlistPath];

    if(![[otherPlist allKeys] containsObject:@"desktopButtonSelected"])
    {
      //Create bool if it does not exist already
      [otherPlist setObject:[NSNumber numberWithBool:NO]
        forKey:@"desktopButtonSelected"];

      //Write dictionary to plist
      [otherPlist writeToFile:otherPlistPath atomically:YES];
    }

    //Get bool from plist and set it to desktopButtonSelected
    desktopButtonSelected = [[otherPlist objectForKey:@"desktopButtonSelected"] boolValue];
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
    NSString* downloadPath = @"/User/Downloads";
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

    %orig;
  }
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

%new
- (void)updateButtonState
{
  //Create dictionary for plist
  NSMutableDictionary* otherPlist = [[NSMutableDictionary alloc]
    initWithContentsOfFile:otherPlistPath];

  //Update desktop bool
  [otherPlist setObject:[NSNumber numberWithBool:desktopButtonSelected]
    forKey:@"desktopButtonSelected"];

  //Write dictionary to plist
  [otherPlist writeToFile:otherPlistPath atomically:YES];
}

%end

%hook BrowserController

%new
- (void)clearData
{
  //Clear history
  [self clearHistoryMessageReceived];

  //Clear autoFill stuff
  [self clearAutoFillMessageReceived];
}

//Used to close tabs based on the setting
%new
- (void)autoCloseAction
{
  switch(preferenceManager.autoCloseTabsFor)
  {
    case 1: //Active mode
    //Close tabs from active surfing mode
    [self.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];
    break;

    case 2: //Normal mode
    if([self privateBrowsingEnabled])
    {
      //Surfing mode is private -> switch to normal mode
      [self togglePrivateBrowsing];

      //Close tabs from normal mode
      [self.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];

      //Switch back to private mode
      [self togglePrivateBrowsing];
    }
    else
    {
      //Surfing mode is normal -> close tabs
      [self.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];
    }
    break;

    case 3: //Private mode
    if(![self privateBrowsingEnabled])
    {
      //Surfing mode is normal -> switch to private mode
      [self togglePrivateBrowsing];

      //Close tabs from private mode
      [self.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];

      //Switch back to normal mode
      [self togglePrivateBrowsing];
    }
    else
    {
      //Surfing mode is private -> close tabs
      [self.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];
    }
    break;

    case 4: //Both modes
    //Close tabs from active surfing mode
    [self.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];

    //Switch mode
    [self togglePrivateBrowsing];

    //Close tabs from other surfing mode
    [self.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];

    //Switch back
    [self togglePrivateBrowsing];
    break;

    default:
    break;
  }
}

//Used to switch mode based on the setting
%new
- (void)modeSwitchAction:(int)switchToMode
{
  if(switchToMode == 1 /*Normal Mode*/ &&
    [self privateBrowsingEnabled])
  {
    //Private browsing mode is active -> toggle browsing mode
    [self togglePrivateBrowsing];
  }

  else if(switchToMode == 2 /*Private Mode*/  &&
    ![self privateBrowsingEnabled])
  {
    //Normal browsing mode is active -> toggle browsing mode
    [self togglePrivateBrowsing];

    //Hide private mode notice
    [self.tabController.tiltedTabView
      setShowsExplanationView:NO animated:NO];
  }
}

%new
- (BOOL)usesTabBar
{
  //Return status of tabbar (delegate function)
  return [self.tabController usesTabBar];
}

//Full screen scrolling
- (BOOL)_isVerticallyConstrained
{
  if(preferenceManager.enableFullscreenScrolling)
  {
    return true;
  }

  return %orig;
}

//Fully disable private mode
- (BOOL)isPrivateBrowsingAvailable
{
  if(preferenceManager.disablePrivateMode)
  {
    return false;
  }

  return %orig;
}

//Update tabs according to desktop button status when user toggles browsing mode
- (void)togglePrivateBrowsing
{
  %orig;
  if(preferenceManager.desktopButtonEnabled)
  {
    [self.tabController reloadTabsIfNeeded];
  }
}

//Add swipe gestures to URL bar

//Create properties for gesture recognizers
%property(nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeLeftGestureRecognizer;
%property(nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeRightGestureRecognizer;
%property(nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeDownGestureRecognizer;

- (NavigationBar *)navigationBar
{
  if(preferenceManager.URLLeftSwipeGestureEnabled ||
    preferenceManager.URLRightSwipeGestureEnabled ||
    preferenceManager.URLDownSwipeGestureEnabled)
  {
    //At least one gesture enabled -> Add enabled gestures
    id orig = %orig;

    //Get URLOutline to add the gestures to
    _SFNavigationBarURLButton* URLOutline =
      MSHookIvar<_SFNavigationBarURLButton*>(orig, "_URLOutline");

    if(preferenceManager.URLLeftSwipeGestureEnabled)
    {
      if(!self.URLBarSwipeLeftGestureRecognizer)
      {
        //Left gesture enabled and not created already

        //Create gesture recognizer
        self.URLBarSwipeLeftGestureRecognizer = [[UISwipeGestureRecognizer alloc]
          initWithTarget:self action:@selector(navigationBarURLWasSwiped:)];

        //Set swipe direction to left
        self.URLBarSwipeLeftGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;

        //Add gestureRecognizer
        [URLOutline addGestureRecognizer:self.URLBarSwipeLeftGestureRecognizer];
      }
    }
    if(preferenceManager.URLRightSwipeGestureEnabled)
    {
      if(!self.URLBarSwipeRightGestureRecognizer)
      {
        //Right gesture enabled and not created already

        //Create gesture recognizer
        self.URLBarSwipeRightGestureRecognizer = [[UISwipeGestureRecognizer alloc]
          initWithTarget:self action:@selector(navigationBarURLWasSwiped:)];

        //Set swipe direction to right
        self.URLBarSwipeRightGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;

        //Add gestureRecognizer
        [URLOutline addGestureRecognizer:self.URLBarSwipeRightGestureRecognizer];
      }
    }
    if(preferenceManager.URLDownSwipeGestureEnabled)
    {
      if(!self.URLBarSwipeDownGestureRecognizer)
      {
        //Down gesture enabled and not created already

        //Create gesture recognizer
        self.URLBarSwipeDownGestureRecognizer = [[UISwipeGestureRecognizer alloc]
          initWithTarget:self action:@selector(navigationBarURLWasSwiped:)];

        //Set swipe direction to down
        self.URLBarSwipeDownGestureRecognizer.direction = UISwipeGestureRecognizerDirectionDown;

        //Add gestureRecognizer
        [URLOutline addGestureRecognizer:self.URLBarSwipeDownGestureRecognizer];
      }
    }
    return orig;
  }
  return %orig;
}

//Call method based on the direction of the url bar swipe
%new
- (void)navigationBarURLWasSwiped:(UISwipeGestureRecognizer*)swipe
{
  switch(swipe.direction)
  {
    case UISwipeGestureRecognizerDirectionLeft:
    //Bar swiped left -> handle swipe
    [self handleSwipe:preferenceManager.URLLeftSwipeAction];
    break;

    case UISwipeGestureRecognizerDirectionRight:
    //Bar swiped right -> handle swipe
    [self handleSwipe:preferenceManager.URLRightSwipeAction];
    break;

    case UISwipeGestureRecognizerDirectionDown:
    //Bar swiped down -> handle swipe
    [self handleSwipe:preferenceManager.URLDownSwipeAction];
    break;
  }
}

%end

%hook TabController

//Property for desktop button in portrait
%property (nonatomic,retain) UIButton *tiltedTabViewDesktopModeButton;

//Set state of desktop button
- (void)tiltedTabViewDidPresent:(id)arg1
{
  %orig;
  if(preferenceManager.desktopButtonEnabled)
  {
    if(desktopButtonSelected)
    {
      //desktop button should be selected -> Select it
      self.tiltedTabViewDesktopModeButton.selected = YES;
      self.tiltedTabViewDesktopModeButton.backgroundColor = [UIColor whiteColor];
    }
    else
    {
      //desktop button should not be selected -> Unselect it
      self.tiltedTabViewDesktopModeButton.selected = NO;
      self.tiltedTabViewDesktopModeButton.backgroundColor = [UIColor clearColor];
    }
  }
}

//Desktop mode button: Portrait
- (NSArray *)tiltedTabViewToolbarItems
{
  if(preferenceManager.desktopButtonEnabled)
  {
    NSArray* old = %orig;

    if(!self.tiltedTabViewDesktopModeButton)
    {
      //desktopButton not created yet -> create and configure it

      self.tiltedTabViewDesktopModeButton = [UIButton buttonWithType:UIButtonTypeCustom];

      [self.tiltedTabViewDesktopModeButton setImage:[UIImage
        imageNamed:@"desktopButtonInactive.png" inBundle:SPBundle
        compatibleWithTraitCollection:nil] forState:UIControlStateNormal];

      [self.tiltedTabViewDesktopModeButton setImage:[UIImage
        imageNamed:@"desktopButtonActive.png" inBundle:SPBundle
        compatibleWithTraitCollection:nil]  forState:UIControlStateSelected];

      self.tiltedTabViewDesktopModeButton.imageEdgeInsets = UIEdgeInsetsMake(2.5, 2.5, 2.5, 2.5);
      self.tiltedTabViewDesktopModeButton.layer.cornerRadius = 4;
      self.tiltedTabViewDesktopModeButton.adjustsImageWhenHighlighted = true;

      [self.tiltedTabViewDesktopModeButton addTarget:self
        action:@selector(tiltedTabViewDesktopModeButtonPressed)
        forControlEvents:UIControlEventTouchUpInside];

      self.tiltedTabViewDesktopModeButton.frame = CGRectMake(0, 0, 27.5, 27.5);

      if(desktopButtonSelected)
      {
        self.tiltedTabViewDesktopModeButton.selected = YES;
        self.tiltedTabViewDesktopModeButton.backgroundColor = [UIColor whiteColor];
      }
    }

    //Create empty space button to align the bottom toolbar perfectly
    UIButton* emptySpace = [UIButton buttonWithType:UIButtonTypeCustom];
    emptySpace.imageEdgeInsets = UIEdgeInsetsMake(2.5, 2.5, 2.5, 2.5);
    emptySpace.layer.cornerRadius = 4;
    emptySpace.frame = CGRectMake(0, 0, 27.5, 27.5);

    //Create UIBarButtonItem from space
    UIBarButtonItem *customSpace = [[UIBarButtonItem alloc] initWithCustomView:emptySpace];

    //Create flexible UIBarButtonItem
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc]
      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
      target:nil action:nil];

    //Create UIBarButtonItem for desktopButton
    UIBarButtonItem *desktopBarButton = [[UIBarButtonItem alloc]
      initWithCustomView:self.tiltedTabViewDesktopModeButton];

    return @[old[0], flexibleItem, desktopBarButton, flexibleItem, old[2],
      flexibleItem, customSpace, flexibleItem, old[4], old[5]];
  }

  return %orig;
}

%new
- (void)tiltedTabViewDesktopModeButtonPressed
{
  if(desktopButtonSelected)
  {
    //Deselect desktop button
    desktopButtonSelected = NO;
    self.tiltedTabViewDesktopModeButton.selected = NO;

    //Remove white color with animation
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    self.tiltedTabViewDesktopModeButton.backgroundColor = [UIColor clearColor];
    [UIView commitAnimations];
  }
  else
  {
    //Select desktop button
    desktopButtonSelected = YES;
    self.tiltedTabViewDesktopModeButton.selected = YES;

    //Set color to white
    self.tiltedTabViewDesktopModeButton.backgroundColor = [UIColor whiteColor];
  }

  //Reload tabs
  [self reloadTabsIfNeeded];

  //Write button state to plist
  [((Application*)[%c(Application) sharedApplication]) updateButtonState];
}

//Reload tabs if the useragents needs to be changed (depending on the desktop button state)
%new
- (void)reloadTabsIfNeeded
{
  NSArray* currentTabs;
  if([self isPrivateBrowsingEnabled])
  {
    //Private mode enabled -> set currentTabs to tabs of private mode
    currentTabs = self.privateTabDocuments;
  }
  else
  {
    //Private mode disabled -> set currentTabs to tabs of normal mode
    currentTabs = self.tabDocuments;
  }

  for(TabDocument* tabDocument in currentTabs)
  {
    if(![tabDocument isBlankDocument] && ((desktopButtonSelected &&
      ([tabDocument.customUserAgent isEqualToString:@""] ||
      tabDocument.customUserAgent == nil)) || (!desktopButtonSelected &&
      [tabDocument.customUserAgent isEqualToString:desktopUserAgent])))
    {
      //Tab is not blank and it's user agent needs to be changed -> reload it
      [tabDocument reload];
    }
  }
}

%end

%hook TabDocument

//Always open in new tab option
- (void)webView:(WKWebView *)webView
  decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
  decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
  if(preferenceManager.alwaysOpenNewTabEnabled)
  {
    if(navigationAction.navigationType == WKNavigationTypeLinkActivated)
    {
      //Get array of components that are seperated by a #
      NSArray* oldComponents = [[self URL].absoluteString
        componentsSeparatedByString:@"#"];

      //Strip fragment
      NSString* oldURLWithoutFragment = oldComponents.firstObject;

      //Get array of components that are seperated by a #
      NSArray* newComponents = [navigationAction.request.URL.absoluteString
        componentsSeparatedByString:@"#"];

      //Strip fragment
      NSString* newURLWithoutFragment = newComponents.firstObject;

      if(![newURLWithoutFragment isEqualToString:oldURLWithoutFragment])
      {
        //Link doesn't contain current URL -> Open in new tab

        //Cancel site load
        decisionHandler(WKNavigationResponsePolicyCancel);
        NSLog(@"Clicked link:%@",navigationAction.request.URL.absoluteString);
        switch(iOSVersion)
        {
          case 9:
          //Load URL in new tab
          [MSHookIvar<BrowserController*>(self, "_browserController")
            loadURLInNewWindow:navigationAction.request.URL
            inBackground:NO animated:YES];
          break;

          case 10:
          //Load URL in new tab
          [self.browserController loadURLInNewTab:navigationAction.request.URL
            inBackground:NO animated:YES];
          break;
        }
        return;
      }
    }
  }

  %orig;
}

BOOL showAlert = YES;

//Present download menu if clicked link is a downloadable file
- (void)webView:(WKWebView *)webView
  decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse
  decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
  if(preferenceManager.enhancedDownloadsEnabled)
  {
    //Get MIMEType
    NSString* MIMEType = navigationResponse.response.MIMEType;

    //Check if MIMEType indicates that link is download
    if(showAlert && (!navigationResponse.canShowMIMEType ||
      [MIMEType rangeOfString:@"video/"].location != NSNotFound ||
      [MIMEType rangeOfString:@"audio/"].location != NSNotFound ||
      [MIMEType isEqualToString:@"application/pdf"]))
    {
      //Cancel loading
      decisionHandler(WKNavigationResponsePolicyCancel);

      //Reinitialise variables so they can be accessed from the actions
      __block int64_t fileSize = navigationResponse.response.expectedContentLength;

      __block NSString* fileName = navigationResponse.response.suggestedFilename;

      __block NSString* fileDetails = [NSString stringWithFormat:@"%@ (%@)",
        fileName, [NSByteCountFormatter stringFromByteCount:fileSize
        countStyle:NSByteCountFormatterCountStyleFile]];

      __block NSURLRequest* request = navigationResponse._request;

      __block WKWebView* webViewLocal = webView;

      dispatch_async(dispatch_get_main_queue(), //Ensure we're on the main thread to avoid crashes
      ^{
        if(preferenceManager.instantDownloadsEnabled &&
          preferenceManager.instantDownloadsOption == 1)
        {
          //Instant download enabled and on 'Download' option
          [[downloadManager sharedInstance] prepareDownloadFromRequest:request withSize:fileSize fileName:fileName];
        }
        else if(preferenceManager.instantDownloadsEnabled &&
          preferenceManager.instantDownloadsOption == 2)
        {
          //Instant download enabled and on 'Download to ...' option
          [[downloadManager sharedInstance] prepareDownloadFromRequest:request withSize:fileSize fileName:fileName customPath:YES];
        }
        else
        {
          //Create alert for download options
          UIAlertController *downloadAlert = [UIAlertController
            alertControllerWithTitle:fileDetails message:nil
            preferredStyle:UIAlertControllerStyleActionSheet];

          //Create 'Download' option
          UIAlertAction *downloadAction = [UIAlertAction
            actionWithTitle:[localizationManager
            localizedSPStringForKey:@"DOWNLOAD"]
            style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
          {
            //Start download through SafariPlus
            [[downloadManager sharedInstance] prepareDownloadFromRequest:request
              withSize:fileSize fileName:fileName];
          }];

          //Create 'Download to ...' option
          UIAlertAction *downloadToAction = [UIAlertAction
            actionWithTitle:[localizationManager
            localizedSPStringForKey:@"DOWNLOAD_TO"]
            style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
          {
            //Start download through SafariPlus with custom path
            [[downloadManager sharedInstance] prepareDownloadFromRequest:request
              withSize:fileSize fileName:fileName customPath:YES];
          }];

          //Create 'Open' option
          UIAlertAction *openAction = [UIAlertAction actionWithTitle:[localizationManager
            localizedSPStringForKey:@"OPEN"]
            style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
          {
            //Load request again and avoid another alert
            showAlert = NO;
            [webViewLocal loadRequest:request];
          }];

          //Create 'Cancel' option
          UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[localizationManager
            localizedSPStringForKey:@"CANCEL"]
            style:UIAlertActionStyleCancel handler:nil]; //Do nothing

          //Add options to alert
          [downloadAlert addAction:downloadAction];
          [downloadAlert addAction:downloadToAction];
          [downloadAlert addAction:openAction];
          [downloadAlert addAction:cancelAction];

          //Get browserController
          BrowserController* browserController =
            MSHookIvar<BrowserController*>(self, "_browserController");

          //Get rootViewController
          BrowserRootViewController* rootViewController =
            MSHookIvar<BrowserRootViewController*>(browserController, "_rootViewController");

          //iPad positions
          downloadAlert.popoverPresentationController.sourceView = rootViewController.view;
          downloadAlert.popoverPresentationController.sourceRect =
            CGRectMake(rootViewController.view.bounds.size.width / 2.0,
            rootViewController.view.bounds.size.height / 2, 1.0, 1.0);
          [downloadAlert.popoverPresentationController
            setPermittedArrowDirections:UIPopoverArrowDirectionDown];

          //Present alert on rootViewController
          [rootViewController presentViewController:downloadAlert
            animated:YES completion:nil];
        }
      });
    }
    else
    {
      showAlert = YES;
      %orig;
    }
  }
  else
  {
    %orig;
  }
}

//desktop mode + ForceHTTPS
- (id)_initWithTitle:(id)arg1 URL:(NSURL*)arg2 UUID:(id)arg3
  privateBrowsingEnabled:(BOOL)arg4 bookmark:(id)arg5
  browserController:(id)arg6 createDocumentView:(id)arg7
{
  if((preferenceManager.forceHTTPSEnabled ||
    preferenceManager.desktopButtonEnabled) && arg2)
  {
    return %orig(arg1, [self URLHandler:arg2], arg3, arg4, arg5, arg6, arg7);
  }
  return %orig;
}

- (id)_loadURLInternal:(NSURL*)arg1 userDriven:(BOOL)arg2
{
  if((preferenceManager.forceHTTPSEnabled ||
    preferenceManager.desktopButtonEnabled) && arg1)
  {
    return %orig([self URLHandler:arg1], arg2);
  }
  return %orig;
}

- (id)loadURL:(NSURL*)arg1 fromBookmark:(id)arg2
{
  if((preferenceManager.forceHTTPSEnabled ||
    preferenceManager.desktopButtonEnabled) && arg1)
  {
    return %orig([self URLHandler:arg1], arg2);
  }
  return %orig;
}

- (void)_loadStartedDuringSimulatedClickForURL:(NSURL*)arg1
{
  if((preferenceManager.forceHTTPSEnabled ||
    preferenceManager.desktopButtonEnabled) && arg1)
  {
    NSURL* newURL = [self URLHandler:arg1];
    if(![[newURL absoluteString] isEqualToString:[arg1 absoluteString]])
    {
      //arg1 and newURL are not the same -> load newURL
      [self loadURL:newURL userDriven:NO];
      return;
    }
  }

  %orig;
}

- (void)reload
{
  if(preferenceManager.forceHTTPSEnabled || preferenceManager.desktopButtonEnabled)
  {
    NSURL* currentURL = (NSURL*)[self URL];
    NSURL* tmpURL = [self URLHandler:currentURL];
    if(![[tmpURL absoluteString] isEqualToString:[currentURL absoluteString]])
    {
      //currentURL and tmpURL are not the same -> load tmpURL
      [self loadURL:tmpURL userDriven:NO];
      return;
    }
  }

  %orig;
}

//Convert http url into https url and change user agent if needed
%new
- (NSURL*)URLHandler:(NSURL*)URL
{
  //Get URL components
  NSURLComponents* URLComponents = [NSURLComponents componentsWithURL:URL
    resolvingAgainstBaseURL:NO];

  if(preferenceManager.forceHTTPSEnabled && [URL.scheme isEqualToString:@"http"] &&
    [self shouldRequestHTTPS:URL])
  {
    //ForceHTTPS enabled & current scheme is http & no exception for current URL
    //-> change scheme to https
    URLComponents.scheme = @"https";
  }

  if(preferenceManager.desktopButtonEnabled && desktopButtonSelected)
  {
    //desktop button is selected -> change user agent to desktop agent
    [self setCustomUserAgent:desktopUserAgent];
  }
  else if(preferenceManager.desktopButtonEnabled && !desktopButtonSelected)
  {
    //desktop button is selected -> change user agent to mobile agent
    [self setCustomUserAgent:@""];
  }

  return URLComponents.URL;
}

//Exception because method uses NSString instead of NSURL
- (NSString*)loadUserTypedAddress:(NSString*)arg1
{
  if(preferenceManager.forceHTTPSEnabled || preferenceManager.desktopButtonEnabled)
  {
    NSString* newURL = arg1;
    if((preferenceManager.forceHTTPSEnabled && newURL) &&
      ([newURL rangeOfString:@"https://"].location == NSNotFound))
    {
      if([newURL rangeOfString:@"://"].location == NSNotFound)
      {
        //URL has not scheme -> Default to http://
        newURL = [@"http://" stringByAppendingString:newURL];
      }

      if([self shouldRequestHTTPS:[NSURL URLWithString:newURL]])
      {
        //Set scheme to https://
        newURL = [newURL stringByReplacingOccurrencesOfString:@"http://"
          withString:@"https://"];
      }
    }

    if(preferenceManager.desktopButtonEnabled && desktopButtonSelected)
    {
      //desktop button is selected -> change user agent to desktop agent
      [self setCustomUserAgent:desktopUserAgent];
    }
    else if(preferenceManager.desktopButtonEnabled && !desktopButtonSelected)
    {
      //desktop button is selected -> change user agent to mobile agent
      [self setCustomUserAgent:@""];
    }

    return %orig(newURL);
  }
  return %orig;
}

//Checks through exceptions whether https should be forced or not
%new
- (BOOL)shouldRequestHTTPS:(NSURL*)URL
{
  //Get dictionary from plist
  NSMutableDictionary* plist = [[NSMutableDictionary alloc]
    initWithContentsOfFile:otherPlistPath];

  //Get https exception array from dictionary
  NSMutableArray* ForceHTTPSExceptions = [plist objectForKey:@"ForceHTTPSExceptions"];

  for(NSString* exception in ForceHTTPSExceptions)
  {
    if([[URL host] rangeOfString:exception].location != NSNotFound)
    {
      //Array contains host -> return false
      return false;
    }
  }
  //Array doesn't contain host -> return false
  return true;
}

%end

//Long press on Search / Site suggestions

%hook CatalogViewController

- (UITableViewCell *)tableView:(id)tableView cellForRowAtIndexPath:(id)indexPath
{
  if(preferenceManager.longPressSuggestionsEnabled)
  {
    UITableViewCell* orig = %orig;

    //Get item class from cell
    id target = [self _completionItemAtIndexPath:indexPath];

    if([target isKindOfClass:[%c(WBSBookmarkAndHistoryCompletionMatch) class]]
      || [target isKindOfClass:[%c(SearchSuggestion) class]])
    {
      //Cell is suggestion from bookmarks / history or a search suggestion
      //-> add long press recognizer
      UILongPressGestureRecognizer* longPressRecognizer = [[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleLongPress:)];

      //Get long press duration to one second
      longPressRecognizer.minimumPressDuration = 1.0;

      //Add recognizer to cell
      [orig addGestureRecognizer:longPressRecognizer];
    }

    return orig;
  }

  return %orig;
}

%new
- (void)handleLongPress:(UILongPressGestureRecognizer*)gestureRecognizer
{
  if(gestureRecognizer.state == UIGestureRecognizerStateBegan)
  {
    //Get tableViewController for suggestions
    CompletionListTableViewController* completionTableController =
      MSHookIvar<CompletionListTableViewController*>(self, "_completionTableController");

    //Get tapped CGPoint
    CGPoint p = [gestureRecognizer locationInView:completionTableController.tableView];

    //Get IndexPath for tapped CGPoint
    NSIndexPath *indexPath = [completionTableController.tableView indexPathForRowAtPoint:p];

    if(indexPath != nil)
    {
      //Get tapped cell
      UITableViewCell *cell = [completionTableController.tableView cellForRowAtIndexPath:indexPath];

      if(cell.isHighlighted)
      {
        //Get completiton item for cell
        id target = [self _completionItemAtIndexPath:indexPath];

        //Get URL textfield
        UnifiedField* textField = MSHookIvar<UnifiedField*>(self, "_textField");

        if([target isKindOfClass:[%c(WBSBookmarkAndHistoryCompletionMatch) class]])
        {
          //Set long pressed URL to textField
          [textField setText:[target originalURLString]];
        }
        else //SearchSuggestion
        {
          //Set long pressed search string to textField
          [textField setText:[target string]];
        }

        //Pull up keyboard
        [textField becomeFirstResponder];

        //Update Entries
        [textField _textDidChangeFromTyping];
        [self _textFieldEditingChanged];
      }
    }
  }
}
%end

%hook TabOverview

//Property for landscape desktop button
%property (nonatomic,retain) UIButton *desktopModeButton;

//Desktop mode button: Landscape
- (void)layoutSubviews
{
  %orig;
  if(preferenceManager.desktopButtonEnabled)
  {
    if(!self.desktopModeButton)
    {
      //desktopButton not created yet -> create and configure it
      self.desktopModeButton = [UIButton buttonWithType:UIButtonTypeCustom];

      [self.desktopModeButton setImage:[UIImage imageNamed:@"desktopButtonInactive.png"
        inBundle:SPBundle compatibleWithTraitCollection:nil]
        forState:UIControlStateNormal];

      [self.desktopModeButton setImage:[UIImage imageNamed:@"desktopButtonActive.png"
        inBundle:SPBundle compatibleWithTraitCollection:nil]
        forState:UIControlStateSelected];

      self.desktopModeButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
      self.desktopModeButton.layer.cornerRadius = 4;
      self.desktopModeButton.adjustsImageWhenHighlighted = true;

      [self.desktopModeButton addTarget:self
        action:@selector(desktopModeButtonPressed)
        forControlEvents:UIControlEventTouchUpInside];

      self.desktopModeButton.frame = CGRectMake(
        self.privateBrowsingButton.frame.origin.x - 57.5,
        self.privateBrowsingButton.frame.origin.y,
        self.privateBrowsingButton.frame.size.height,
        self.privateBrowsingButton.frame.size.height);

      if(desktopButtonSelected)
      {
        self.desktopModeButton.selected = YES;
        self.desktopModeButton.backgroundColor = [UIColor whiteColor];
      }
    }

    //Add desktopButton to top bar
    switch(iOSVersion)
    {
      case 9:
      [MSHookIvar<UIView*>(self, "_header") addSubview:self.desktopModeButton];
      break;
      case 10:
      [MSHookIvar<_UIBackdropView*>(self, "_header").contentView
        addSubview:self.desktopModeButton];
      break;
    }
  }
}

%new
- (void)desktopModeButtonPressed
{
  if(desktopButtonSelected)
  {
    //Deselect desktop button
    desktopButtonSelected = NO;
    self.desktopModeButton.selected = NO;

    //Remove white color with animation
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    self.desktopModeButton.backgroundColor = [UIColor clearColor];
    [UIView commitAnimations];
  }
  else
  {
    //Select desktop button
    desktopButtonSelected = YES;
    self.desktopModeButton.selected = YES;

    //Set color to white
    self.desktopModeButton.backgroundColor = [UIColor whiteColor];
  }

  //Reload tabs
  switch(iOSVersion)
  {
    case 9:
    [MSHookIvar<BrowserController*>(((Application*)[%c(Application)
      sharedApplication]), "_controller").tabController reloadTabsIfNeeded];
    break;

    case 10:
    [((Application*)[%c(Application)
      sharedApplication]).shortcutController.browserController.tabController
      reloadTabsIfNeeded];
    break;
  }

  //Write button state to plist
  [((Application*)[%c(Application) sharedApplication]) updateButtonState];
}

%end

%hook BrowserToolbar

//Property for downloads button
%property (nonatomic,retain) UIBarButtonItem *_downloadsItem;

//Correctly enable / disable downloads button when needed
- (void)setEnabled:(BOOL)arg1
{
  %orig;
  if(preferenceManager.enhancedDownloadsEnabled)
  {
    [self setDownloadsEnabled:arg1];
  }
}

%new
- (void)setDownloadsEnabled:(BOOL)enabled
{
  [self._downloadsItem setEnabled:enabled];
}

//Add downloads button to toolbar
- (NSMutableArray *)defaultItems
{
  if(preferenceManager.enhancedDownloadsEnabled)
  {
    NSMutableArray* orig = %orig;

    if(![orig containsObject:self._downloadsItem])
    {
      if(!self._downloadsItem)
      {
        self._downloadsItem = [[UIBarButtonItem alloc] initWithImage:[UIImage
          imageNamed:@"downloadsButton.png" inBundle:SPBundle
          compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain
          target:self.browserDelegate action:@selector(downloadsFromButtonBar)];
      }

      //Portrait + Landscape on iPad
      if(IS_PAD)
      {
        ((UIBarButtonItem*)orig[10]).width = ((UIBarButtonItem*)orig[10]).width / 3;
        ((UIBarButtonItem*)orig[12]).width = ((UIBarButtonItem*)orig[12]).width / 3;
        [orig insertObject:orig[10] atIndex:8];
        [orig insertObject:self._downloadsItem atIndex:8];
      }
      else
      {
        //Portrait mode on plus models, portrait + landscape on non-plus models
        if(![self.browserDelegate usesTabBar] || [orig count] < 15) //count thing fixes crash
        {
          UIBarButtonItem* flexibleItem = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
            target:nil action:nil];

          UIBarButtonItem *fixedItem = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
            target:nil action:nil];

          UIBarButtonItem *fixedItemHalf = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
            target:nil action:nil];

          //Make everything flexible, thanks apple!
          fixedItem.width = 15;
          fixedItemHalf.width = 7.5f;

          UIBarButtonItem *fixedItemTwo = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
            target:nil action:nil];

          fixedItemTwo.width = 6;

          orig = (NSMutableArray*)@[orig[1], fixedItem, flexibleItem,
            fixedItemHalf, orig[4], fixedItemHalf, flexibleItem, fixedItemTwo,
            orig[7], flexibleItem, orig[10], flexibleItem, self._downloadsItem,
            flexibleItem, orig[13]];
        }
        //Landscape on plus models
        else
        {
          ((UIBarButtonItem*)orig[10]).width = ((UIBarButtonItem*)orig[10]).width / 10;
          ((UIBarButtonItem*)orig[12]).width = ((UIBarButtonItem*)orig[12]).width / 10;
          ((UIBarButtonItem*)orig[15]).width = 0;
          [orig insertObject:orig[10] atIndex:9];
          [orig insertObject:self._downloadsItem atIndex:9];
        }
      }

      return orig;
    }
  }

  return %orig;
}

%end

%hook BrowserRootViewController

%property(nonatomic, retain) CWStatusBarNotification *statusBarNotification;

//Dispatch status bar notification
%new
- (void)dispatchNotificationWithText:(NSString*)text
{
  dispatch_async(dispatch_get_main_queue(), ^
  {
    [self.statusBarNotification displayNotificationWithMessage:text forDuration:2.0f];
  });
}

//Dismiss notification
%new
- (void)dismissNotificationWithCompletion:(void (^)(void))completion
{
  dispatch_async(dispatch_get_main_queue(), ^
  {
    [self.statusBarNotification dismissNotificationWithCompletion:completion];
  });
}

//Present viewController on rootController
%new
- (void)presentViewController:(id)viewController
{
  dispatch_async(dispatch_get_main_queue(), ^
  {
    [self presentViewController:viewController animated:YES completion:nil];
  });
}

%end

//Some attempts with custom bookmark pictures that did not work

/*%hook SingleBookmarkNavigationController

- (id)initWithCollection:(id)arg1
{
  id orig = %orig;
  _SFBookmarkInfoViewController* infoViewController = MSHookIvar<_SFBookmarkInfoViewController*>(orig, "_infoViewController");
  if(infoViewController)
  {
    _SFSiteIconView* iconImageView = MSHookIvar<_SFSiteIconView*>(infoViewController, "_iconImageView");
    NSLog(@"iconImageView: %@", iconImageView);
  }
  return orig;
}

+ (id)newBookmarkInfoViewControllerWithBookmark:(id)arg1 inCollection:(id)arg2 addingBookmark:(BOOL)arg3 toFavorites:(BOOL)arg4 willBeDisplayedModally:(BOOL)arg5
{
  id orig = %orig;

  _SFSiteIconView* iconImageView = MSHookIvar<_SFSiteIconView*>(orig, "_iconImageView");
  UIButton* invisibleButton = [UIButton buttonWithType:UIButtonTypeCustom];

  invisibleButton.adjustsImageWhenHighlighted = YES;
  invisibleButton.frame = iconImageView.frame;

  UILongPressGestureRecognizer *siteIconLongPressRecognizer = [[UILongPressGestureRecognizer alloc] init];
  [siteIconLongPressRecognizer addTarget:self action:@selector(siteIconLongPressed:)];
  [siteIconLongPressRecognizer setMinimumPressDuration:0.5];


  [invisibleButton addGestureRecognizer:siteIconLongPressRecognizer];
  [iconImageView addSubview:invisibleButton];
  NSLog(@"iconImageView: %@", iconImageView);

  return orig;
}

- (void)siteIconLongPressed:(UILongPressGestureRecognizer*)sender
{
  NSLog(@"icon long pressed!!!");
}

%end*/

//Custom colors

%hook NavigationBar

- (void)_updateBackdropStyle
{
  %orig;
  if(preferenceManager.appTintColorNormalEnabled ||
    preferenceManager.appTintColorPrivateEnabled)
  {
    BOOL privateMode;

    getBrowsingMode;

    if(preferenceManager.appTintColorNormalEnabled && !privateMode)
    {
      self.tintColor = LCPParseColorString(preferenceManager.appTintColorNormal, @"#FFFFFF");
    }
    else if(preferenceManager.appTintColorPrivateEnabled && privateMode)
    {
      self.tintColor = LCPParseColorString(preferenceManager.appTintColorPrivate, @"#FFFFFF");
    }
    else
    {
      [self _updateControlTints]; //Apply default color
    }
  }

  if(preferenceManager.topBarColorNormalEnabled ||
    preferenceManager.topBarColorPrivateEnabled)
  {
    BOOL privateMode;

    getBrowsingMode;

    _SFNavigationBarBackdrop* backdrop =
      MSHookIvar<_SFNavigationBarBackdrop*>(self, "_backdrop");

    if(preferenceManager.topBarColorNormalEnabled && !privateMode) //Normal Mode
    {
      backdrop.grayscaleTintView.backgroundColor =
        LCPParseColorString(preferenceManager.topBarColorNormal, @"#FFFFFF");
    }

    else if(preferenceManager.topBarColorPrivateEnabled && privateMode) //Private Mode
    {
      backdrop.grayscaleTintView.backgroundColor =
        LCPParseColorString(preferenceManager.topBarColorPrivate, @"#FFFFFF");
    }
  }
}

//Progress bar color
- (void)_updateProgressView
{
  %orig;
  if(preferenceManager.progressBarColorNormalEnabled ||
    preferenceManager.progressBarColorPrivateEnabled)
  {
    BOOL privateMode;

    getBrowsingMode;

    _SFFluidProgressView* progressView = MSHookIvar<_SFFluidProgressView*>(self, "_progressView");
    if(preferenceManager.progressBarColorNormalEnabled && !privateMode)
    {
      progressView.progressBarFillColor =
        LCPParseColorString(preferenceManager.progressBarColorNormal, @"#FFFFFF");
    }
    else if(preferenceManager.progressBarColorPrivateEnabled && privateMode)
    {
      progressView.progressBarFillColor =
        LCPParseColorString(preferenceManager.progressBarColorPrivate, @"#FFFFFF");
    }
  }
}

//Text color
- (id)_URLTextColor
{
  if(preferenceManager.URLFontColorNormalEnabled ||
    preferenceManager.URLFontColorPrivateEnabled)
  {
    BOOL privateMode;

    getBrowsingMode;

    if(preferenceManager.URLFontColorNormalEnabled && !privateMode)
    {
      return LCPParseColorString(preferenceManager.URLFontColorNormal, @"#FFFFFF");
    }
    else if(preferenceManager.URLFontColorPrivateEnabled && privateMode)
    {
      return LCPParseColorString(preferenceManager.URLFontColorPrivate, @"#FFFFFF");
    }
  }

  return %orig;
}

//Text color of search text, needs to be less visible
- (id)_placeholderColor
{
  if(preferenceManager.URLFontColorNormalEnabled ||
    preferenceManager.URLFontColorPrivateEnabled)
  {
    BOOL privateMode;

    getBrowsingMode;

    UIColor* customColor;
    if(preferenceManager.URLFontColorNormalEnabled && !privateMode)
    {
      customColor = LCPParseColorString(preferenceManager.URLFontColorNormal, @"#FFFFFF");
      return [customColor colorWithAlphaComponent:0.5];
    }
    else if(preferenceManager.URLFontColorPrivateEnabled && privateMode)
    {
      customColor = LCPParseColorString(preferenceManager.URLFontColorNormal, @"#FFFFFF");
      return [customColor colorWithAlphaComponent:0.5];
    }
  }

  return %orig;
}

//Reload button color
- (id)_URLControlsColor
{
  if(preferenceManager.reloadColorNormalEnabled ||
    preferenceManager.reloadColorPrivateEnabled)
  {
    BOOL privateMode;

    getBrowsingMode;

    if(preferenceManager.reloadColorNormalEnabled && !privateMode)
    {
      return LCPParseColorString(preferenceManager.reloadColorNormal, @"#FFFFFF");
    }
    else if(preferenceManager.reloadColorPrivateEnabled && privateMode)
    {
      return LCPParseColorString(preferenceManager.reloadColorPrivate, @"#FFFFFF");
    }
  }

  return %orig;
}
%end

//Tab Title Color

%hook TabBarStyle
- (UIColor *)itemTitleColor
{
  if(preferenceManager.tabTitleColorNormalEnabled ||
    preferenceManager.tabTitleColorPrivateEnabled)
  {
    BOOL privateMode;

    getBrowsingMode;

    UIColor* customColor = %orig;
    if(preferenceManager.tabTitleColorNormalEnabled && !privateMode)
    {
      customColor = LCPParseColorString(preferenceManager.tabTitleColorNormal, @"#FFFFFF");
    }
    else if(preferenceManager.tabTitleColorPrivateEnabled && privateMode)
    {
      customColor = LCPParseColorString(preferenceManager.tabTitleColorPrivate, @"#FFFFFF");
    }
    return customColor;
  }

  return %orig;
}
%end

%hook TiltedTabItem
- (UIColor *)titleColor
{
  if(preferenceManager.tabTitleColorNormalEnabled ||
    preferenceManager.tabTitleColorPrivateEnabled)
  {
    BOOL privateMode;

    getBrowsingMode;

    UIColor* customColor = %orig;
    if(preferenceManager.tabTitleColorNormalEnabled && !privateMode)
    {
      customColor = LCPParseColorString(preferenceManager.tabTitleColorNormal, @"#FFFFFF");
    }
    else if(preferenceManager.tabTitleColorPrivateEnabled && privateMode)
    {
      customColor = LCPParseColorString(preferenceManager.tabTitleColorPrivate, @"#FFFFFF");
    }
    return customColor;
  }

  return %orig;
}
%end

%hook TabOverviewItem
- (UIColor *)titleColor
{
  if(preferenceManager.tabTitleColorNormalEnabled ||
    preferenceManager.tabTitleColorPrivateEnabled)
  {
    BOOL privateMode;

    getBrowsingMode;

    UIColor* customColor = %orig;
    if(preferenceManager.tabTitleColorNormalEnabled && !privateMode)
    {
      customColor = LCPParseColorString(preferenceManager.tabTitleColorNormal, @"#FFFFFF");
    }
    else if(preferenceManager.tabTitleColorPrivateEnabled && privateMode)
    {
      customColor = LCPParseColorString(preferenceManager.tabTitleColorPrivate, @"#FFFFFF");
    }
    return customColor;
  }

  return %orig;
}
%end

%hook BrowserToolbar

- (void)layoutSubviews
{
  //Tint Color
  if(preferenceManager.appTintColorNormalEnabled ||
    preferenceManager.appTintColorPrivateEnabled)
  {
    BOOL privateMode;

    getBrowsingMode;

    if(preferenceManager.appTintColorNormalEnabled && !privateMode)
    {
      self.tintColor = LCPParseColorString(preferenceManager.appTintColorNormal, @"#FFFFFF");
    }
    else if(preferenceManager.appTintColorPrivateEnabled && privateMode)
    {
      self.tintColor = LCPParseColorString(preferenceManager.appTintColorPrivate, @"#FFFFFF");
    }
  }

  //Bottom Bar Color (kinda broken? For some reason it only works properly when SafariDownloader + is installed?)
  if(preferenceManager.bottomBarColorNormalEnabled ||
    preferenceManager.bottomBarColorPrivateEnabled)
  {
    BOOL privateMode;

    getBrowsingMode;

    _UIBackdropView* backgroundView = MSHookIvar<_UIBackdropView*>(self, "_backgroundView");
    backgroundView.grayscaleTintView.hidden = NO;
    if(preferenceManager.bottomBarColorNormalEnabled && !privateMode)
    {
      backgroundView.grayscaleTintView.backgroundColor =
        LCPParseColorString(preferenceManager.bottomBarColorNormal, @"#FFFFFF");
    }
    else if(preferenceManager.bottomBarColorPrivateEnabled && privateMode)
    {
      backgroundView.grayscaleTintView.backgroundColor =
        LCPParseColorString(preferenceManager.bottomBarColorPrivate, @"#FFFFFF");
    }
    else
    {
      [self updateTintColor];
    }
  }

  %orig;
}
%end

/****** Preference stuff ******/

%ctor
{
  if(kCFCoreFoundationVersionNumber < 1348.00)
  {
    iOSVersion = 9;
    %init(iOS9);
  }
  else
  {
    iOSVersion = 10;
    %init(iOS10);
  }
  %init;

}
