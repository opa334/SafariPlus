//  SafariPlus.xm
//  Safari Hooks

// (c) 2017 opa334

#import "SafariPlus.h"

/****** Variables ******/

SPPreferenceManager* preferenceManager = [SPPreferenceManager sharedInstance];
SPLocalizationManager* localizationManager = [SPLocalizationManager sharedInstance];
NSBundle* MSBundle = [NSBundle mainBundle];
NSBundle* SPBundle = [NSBundle bundleWithPath:@"/Library/Application Support/SafariPlus.bundle"];
BOOL desktopButtonSelected;

/****** Safari Hooks ******/

%group iOS10

%hook Application

//Used to clear browser data
%new
- (void)clearData
{
  [self.shortcutController.browserController clearHistoryMessageReceived];
  [self.shortcutController.browserController clearAutoFillMessageReceived];
}

//Used to update the tabs on startup
%new
- (void)updateDesktopMode
{
  [self.shortcutController.browserController.tabController reloadTabsIfNeeded];
}

//Used to switch mode based on the setting
%new
- (void)modeSwitchAction:(int)switchToMode
{
  if(switchToMode == 1 /*Normal Mode*/ && [self.shortcutController.browserController privateBrowsingEnabled])
  {
    [self.shortcutController.browserController togglePrivateBrowsing];
  }

  else if(switchToMode == 2 /*Private Mode*/  && ![self.shortcutController.browserController privateBrowsingEnabled])
  {
    [self.shortcutController.browserController togglePrivateBrowsing];
    [self.shortcutController.browserController.tabController.tiltedTabView setShowsExplanationView:NO animated:NO];
  }
}

//Used to close tabs based on the setting
%new
- (void)autoCloseAction
{
  switch(preferenceManager.autoCloseTabsFor)
  {
    case 1: //Active mode
    [self.shortcutController.browserController.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];
    break;

    case 2: //Normal mode
    if([self.shortcutController.browserController privateBrowsingEnabled])
    {
      [self.shortcutController.browserController togglePrivateBrowsing];
      [self.shortcutController.browserController.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];
      [self.shortcutController.browserController togglePrivateBrowsing];
    }
    else
    {
      [self.shortcutController.browserController.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];
    }
    break;

    case 3: //Private mode
    if(![self.shortcutController.browserController privateBrowsingEnabled])
    {
      [self.shortcutController.browserController togglePrivateBrowsing];
      [self.shortcutController.browserController.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];
      [self.shortcutController.browserController togglePrivateBrowsing];
    }
    else
    {
      [self.shortcutController.browserController.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];
    }
    break;

    case 4: //Both modes
    [self.shortcutController.browserController.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];
    [self.shortcutController.browserController togglePrivateBrowsing];
    [self.shortcutController.browserController.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];
    [self.shortcutController.browserController togglePrivateBrowsing];
    break;

    default:
    break;
  }
}

%end

%hook BrowserController

//Present downloads view
%new
- (void)downloadsFromButtonBar
{
  downloadsNavigationController* downloadsController = [[downloadsNavigationController alloc] init];

  dispatch_async(dispatch_get_main_queue(), ^
  {
    [self.rootViewController presentViewController:downloadsController animated:YES completion:^
    {
      if([((downloadsTableViewController*)downloadsController.visibleViewController).downloadsAtCurrentPath count] != 0)
      {
        [(downloadsTableViewController*)downloadsController.visibleViewController reloadDataAndDataSources]; //Fixes stuck download if the download finishes while the view presents
      }
    }];
  });
}

//URL Swipe actions
%new
- (void)handleSwipe:(NSInteger)swipeAction
{
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
    [self loadURLInNewTab:[self.tabController.activeTabDocument URL] inBackground:preferenceManager.gestureBackground animated:YES];
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
      NSInteger tabIndex = [self.tabController.currentTabDocuments indexOfObject:self.tabController.activeTabDocument] - 1;
      if(tabIndex >= 0)
      {
        [self.tabController setActiveTabDocument:self.tabController.currentTabDocuments[tabIndex] animated:NO];
      }
      break;
    }

    case 7: //Tab forward
    {
      NSInteger tabIndex = [self.tabController.currentTabDocuments indexOfObject:self.tabController.activeTabDocument] + 1;
      if(tabIndex < [self.tabController.currentTabDocuments count])
      {
        [self.tabController setActiveTabDocument:self.tabController.currentTabDocuments[tabIndex] animated:NO];
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
    [self.tabController.tiltedTabView setShowsExplanationView:NO animated:NO];
  }
}

%end

%hook BrowserRootViewController

//Initialise status bar notifications
- (void)viewDidLoad
{
  %orig;
  if(preferenceManager.enhancedDownloadsEnabled && !preferenceManager.disableBarNotificationsEnabled && !self.statusBarNotification)
  {
    self.statusBarNotification = [CWStatusBarNotification new];
    self.statusBarNotification.notificationLabelBackgroundColor = [UIColor blueColor];
    self.statusBarNotification.notificationAnimationInStyle = CWNotificationAnimationStyleTop;
    self.statusBarNotification.notificationAnimationOutStyle = CWNotificationAnimationStyleTop;
    [downloadManager sharedInstance].rootControllerDelegate = self;
  }
}

%end

%hook TabOverview

%property (nonatomic,retain) UIButton *desktopModeButton;

//Desktop mode button : Landscape
- (void)layoutSubviews
{
  %orig;
  if(preferenceManager.desktopButtonEnabled)
  {
    if(!self.desktopModeButton)
    {
      UIButton* desktopModeButton = [UIButton buttonWithType:UIButtonTypeCustom];

      [desktopModeButton setImage:[UIImage imageNamed:@"desktopButtonInactive.png" inBundle:SPBundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
      [desktopModeButton setImage:[UIImage imageNamed:@"desktopButtonActive.png" inBundle:SPBundle compatibleWithTraitCollection:nil]  forState:UIControlStateSelected];
      desktopModeButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
      desktopModeButton.layer.cornerRadius = 4;
      desktopModeButton.adjustsImageWhenHighlighted = true;
      [desktopModeButton addTarget:self action:@selector(desktopModeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
      desktopModeButton.frame = CGRectMake(self.privateBrowsingButton.frame.origin.x - 57.5, self.privateBrowsingButton.frame.origin.y, self.privateBrowsingButton.frame.size.height, self.privateBrowsingButton.frame.size.height);

      if(desktopButtonSelected)
      {
        desktopModeButton.selected = YES;
        desktopModeButton.backgroundColor = [UIColor whiteColor];
      }

      [self setDesktopModeButton:desktopModeButton];
    }

    _UIBackdropView* header = MSHookIvar<_UIBackdropView*>(self, "_header");
    [header.contentView addSubview:self.desktopModeButton];
  }
}

%new
- (void)desktopModeButtonPressed
{
  if(desktopButtonSelected)
  {
    desktopButtonSelected = NO;
    self.desktopModeButton.selected = NO;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    self.desktopModeButton.backgroundColor = [UIColor clearColor];
    [UIView commitAnimations];
  }
  else
  {
    desktopButtonSelected = YES;

    self.desktopModeButton.selected = YES;
    self.desktopModeButton.backgroundColor = [UIColor whiteColor];
  }
  [((Application*)[%c(Application) sharedApplication]).shortcutController.browserController.tabController reloadTabsIfNeeded];
  [((Application*)[%c(Application) sharedApplication]) updateButtonState];
}

%end

%hook TabDocument

- (void)dialogController:(_SFDialogController*)dialogController willPresentDialog:(_SFDialog*)dialog
{
  if(preferenceManager.suppressMailToDialog && [[self URL].scheme isEqualToString:@"mailto"])
  {
    [dialog finishWithPrimaryAction:YES text:dialog.defaultText];
    [dialogController _dismissDialog];
  }
  else
  {
    %orig;
  }
}

//Extra 'Open in new Tab' option
- (NSMutableArray*)_actionsForElement:(_WKActivatedElementInfo*)arg1 defaultActions:(NSArray*)arg2 previewViewController:(id)arg3
{
  BOOL tabBar = ((Application*)[%c(Application) sharedApplication]).shortcutController.browserController.tabController.usesTabBar;
  if(preferenceManager.openInNewTabOptionEnabled && arg1.type == 0 && !tabBar) //Showing the option is not needed, when a TabBar exists
  {
    NSMutableArray* options = %orig;

    _WKElementAction* openInNewTab = [%c(_WKElementAction) elementActionWithTitle:[localizationManager localizedMSStringForKey:@"Open Link in New Tab"] actionHandler:^
    {
      [self.browserController loadURLInNewTab:arg1.URL inBackground:NO];
    }];

    [options insertObject:openInNewTab atIndex:1];

    return options;
  }
  return %orig;
}

%end

%hook NavigationBar

//Lock icon color
- (id)_tintForLockImage:(BOOL)arg1
{
  if(preferenceManager.lockIconColorNormalEnabled || preferenceManager.lockIconColorPrivateEnabled)
  {
    BOOL privateMode = [self getBrowsingMode];
    if(preferenceManager.lockIconColorNormalEnabled && !privateMode)
    {
      return LCPParseColorString(preferenceManager.lockIconColorNormal, @"#FFFFFF");
    }
    else if(preferenceManager.lockIconColorPrivateEnabled && privateMode)
    {
      return LCPParseColorString(preferenceManager.lockIconColorPrivate, @"#FFFFFF");
    }
  }

  return %orig;
}

%new
- (BOOL)getBrowsingMode
{
  return [((Application*)[%c(Application) sharedApplication]).shortcutController.browserController privateBrowsingEnabled];
}
%end

%hook TabBarStyle

%new
- (BOOL)getBrowsingMode
{
  return [((Application*)[%c(Application) sharedApplication]).shortcutController.browserController privateBrowsingEnabled];
}

%end

%hook TiltedTabItem

%new
- (BOOL)getBrowsingMode
{
  return [((Application*)[%c(Application) sharedApplication]).shortcutController.browserController privateBrowsingEnabled];
}

%end

%hook TabOverviewItem

%new
- (BOOL)getBrowsingMode
{
  return [((Application*)[%c(Application) sharedApplication]).shortcutController.browserController privateBrowsingEnabled];
}

%end

%hook BrowserToolbar

%new
- (BOOL)getBrowsingMode
{
  return [((Application*)[%c(Application) sharedApplication]).shortcutController.browserController privateBrowsingEnabled];
}

%end

%end


%group iOS9

%hook Application

//Used to clear browser data
%new
- (void)clearData
{
  BrowserController* controller = MSHookIvar<BrowserController*>(self, "_controller");
  [controller clearHistoryMessageReceived];
  [controller clearAutoFillMessageReceived];
}

//Used to update the tabs on startup
%new
- (void)updateDesktopMode
{
  BrowserController* browserController = MSHookIvar<BrowserController*>(self, "_controller");
  [browserController.tabController reloadTabsIfNeeded];
}

//Used to switch mode based on the setting
%new
- (void)modeSwitchAction:(int)switchToMode
{
  BrowserController* browserController = MSHookIvar<BrowserController*>(self, "_controller");

  if(switchToMode == 1 /*Normal Mode*/ && [browserController privateBrowsingEnabled])
  {
    [browserController togglePrivateBrowsing];
  }

  else if(switchToMode == 2 /*Private Mode*/  && ![browserController privateBrowsingEnabled])
  {
    [browserController togglePrivateBrowsing];
    [browserController.tabController.tiltedTabView setShowsExplanationView:NO animated:NO];
  }
}

//Used to close tabs based on the setting
%new
- (void)autoCloseAction
{
  BrowserController* browserController = MSHookIvar<BrowserController*>(self, "_controller");

  switch(preferenceManager.autoCloseTabsFor)
  {
    case 1: //Active mode
    [browserController.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];
    break;

    case 2: //Normal mode
    if([browserController privateBrowsingEnabled])
    {
      [browserController togglePrivateBrowsing];
      [browserController.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];
      [browserController togglePrivateBrowsing];
    }
    else
    {
      [browserController.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];
    }
    break;

    case 3: //Private mode
    if(![browserController privateBrowsingEnabled])
    {
      [browserController togglePrivateBrowsing];
      [browserController.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];
      [browserController togglePrivateBrowsing];
    }
    else
    {
      [browserController.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];
    }
    break;

    case 4: //Both modes
    [browserController.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];
    [browserController togglePrivateBrowsing];
    [browserController.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];
    [browserController togglePrivateBrowsing];
    break;

    default:
    break;
  }
}

%end

%hook BrowserController

//Present downloads view
%new
- (void)downloadsFromButtonBar
{
  downloadsNavigationController* downloadsController = [[downloadsNavigationController alloc] init];

  dispatch_async(dispatch_get_main_queue(), ^
  {
    [MSHookIvar<BrowserRootViewController*>(self, "_rootViewController") presentViewController:downloadsController animated:YES completion:^
    {
      if([((downloadsTableViewController*)downloadsController.visibleViewController).downloadsAtCurrentPath count] != 0)
      {
        [(downloadsTableViewController*)downloadsController.visibleViewController reloadDataAndDataSources]; //Fixes stuck download if the download finishes while the view presents
      }
    }];
  });
}

//URL Swipe actions
%new
- (void)handleSwipe:(NSInteger)swipeAction
{
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
    [self loadURLInNewWindow:[self.tabController.activeTabDocument URL] inBackground:preferenceManager.gestureBackground animated:YES];
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
        currentTabs = self.tabController.privateTabDocuments;
      }
      else
      {
        currentTabs = self.tabController.tabDocuments;
      }
      NSInteger tabIndex = [currentTabs indexOfObject:self.tabController.activeTabDocument] - 1;
      if(tabIndex >= 0)
      {
        [self.tabController setActiveTabDocument:currentTabs[tabIndex] animated:NO];
      }
      break;
    }

    case 7: //Tab forward
    {
      NSArray* currentTabs;
      if([self privateBrowsingEnabled])
      {
        currentTabs = self.tabController.privateTabDocuments;
      }
      else
      {
        currentTabs = self.tabController.tabDocuments;
      }
      NSInteger tabIndex = [currentTabs indexOfObject:self.tabController.activeTabDocument] + 1;
      if(tabIndex < [currentTabs count])
      {
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
    [downloadManager sharedInstance].rootControllerDelegate = self;

    if(!preferenceManager.disableBarNotificationsEnabled)
    {
      self.statusBarNotification = [CWStatusBarNotification new];
      self.statusBarNotification.notificationLabelBackgroundColor = [UIColor blueColor];
      self.statusBarNotification.notificationAnimationInStyle = CWNotificationAnimationStyleTop;
      self.statusBarNotification.notificationAnimationOutStyle = CWNotificationAnimationStyleTop;
    }
  }
  return self;
}

%end

%hook TabOverview

%property (nonatomic,retain) UIButton *desktopModeButton;

//Desktop mode button : Landscape
- (void)layoutSubviews
{
  %orig;
  if(preferenceManager.desktopButtonEnabled)
  {
    if(!self.desktopModeButton)
    {
      UIButton* desktopModeButton = [UIButton buttonWithType:UIButtonTypeCustom];
      [desktopModeButton setImage:[UIImage imageNamed:@"desktopButtonInactive.png" inBundle:SPBundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
      [desktopModeButton setImage:[UIImage imageNamed:@"desktopButtonActive.png" inBundle:SPBundle compatibleWithTraitCollection:nil]  forState:UIControlStateSelected];
      desktopModeButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
      desktopModeButton.layer.cornerRadius = 4;
      desktopModeButton.adjustsImageWhenHighlighted = true;
      [desktopModeButton addTarget:self action:@selector(desktopModeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
      desktopModeButton.frame = CGRectMake(self.privateBrowsingButton.frame.origin.x - 57.5, self.privateBrowsingButton.frame.origin.y, self.privateBrowsingButton.frame.size.height, self.privateBrowsingButton.frame.size.height);

      if(desktopButtonSelected)
      {
        desktopModeButton.selected = YES;
        desktopModeButton.backgroundColor = [UIColor whiteColor];
      }

      [self setDesktopModeButton:desktopModeButton];
    }

    UIView* header = MSHookIvar<UIView*>(self, "_header");
    [header addSubview:self.desktopModeButton];
  }
}

%new
- (void)desktopModeButtonPressed
{
  if(desktopButtonSelected)
  {
    desktopButtonSelected = NO;
    self.desktopModeButton.selected = NO;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    self.desktopModeButton.backgroundColor = [UIColor clearColor];
    [UIView commitAnimations];
  }
  else
  {
    desktopButtonSelected = YES;

    self.desktopModeButton.selected = YES;
    self.desktopModeButton.backgroundColor = [UIColor whiteColor];
  }
  [MSHookIvar<BrowserController*>(((Application*)[%c(Application) sharedApplication]), "_controller").tabController reloadTabsIfNeeded];
  [((Application*)[%c(Application) sharedApplication]) updateButtonState];
}


%end

%hook TabDocument

//Extra 'Open in new Tab' option
- (NSMutableArray*)_actionsForElement:(_WKActivatedElementInfo*)arg1 defaultActions:(NSArray*)arg2 previewViewController:(id)arg3
{
  BOOL tabBar = MSHookIvar<BrowserController*>(((Application*)[%c(Application) sharedApplication]), "_controller").tabController.usesTabBar;
  if(preferenceManager.openInNewTabOptionEnabled && arg1.type == 0 && !tabBar) //Showing the option is not needed when a TabBar exists
  {
    NSMutableArray* options = %orig;

    _WKElementAction* openInNewTab = [%c(_WKElementAction) elementActionWithTitle:[localizationManager localizedSPStringForKey:@"OPEN_IN_NEW_TAB_OPTION"] actionHandler:^
    {
      BrowserController* browserController = MSHookIvar<BrowserController*>(self, "_browserController");
      [browserController loadURLInNewWindow:arg1.URL inBackground:NO];
    }];

    [options insertObject:openInNewTab atIndex:1];

    return options;
  }
  return %orig;
}

%end

%hook NavigationBar
//Lock icon color
- (id)_lockImageWithTint:(id)arg1 usingMiniatureVersion:(BOOL)arg2
{
  if(preferenceManager.lockIconColorNormalEnabled || preferenceManager.lockIconColorPrivateEnabled)
  {
    BOOL privateMode = [self getBrowsingMode];
    if(preferenceManager.lockIconColorNormalEnabled && !privateMode)
    {
      arg1 = LCPParseColorString(preferenceManager.lockIconColorNormal, @"#FFFFFF");
    }
    else if(preferenceManager.lockIconColorPrivateEnabled && privateMode)
    {
      arg1 = LCPParseColorString(preferenceManager.lockIconColorPrivate, @"#FFFFFF");
    }
    return %orig(arg1, arg2);
  }

  return %orig;
}

%new
- (BOOL)getBrowsingMode
{
  return [MSHookIvar<BrowserController*>(((Application*)[%c(Application) sharedApplication]), "_controller") privateBrowsingEnabled];
}

%end

%hook TabBarStyle

%new
- (BOOL)getBrowsingMode
{
  return [MSHookIvar<BrowserController*>(((Application*)[%c(Application) sharedApplication]), "_controller") privateBrowsingEnabled];
}

%end

%hook TiltedTabItem

%new
- (BOOL)getBrowsingMode
{
  return [MSHookIvar<BrowserController*>(((Application*)[%c(Application) sharedApplication]), "_controller") privateBrowsingEnabled];
}

%end

%hook TabOverviewItem

%new
- (BOOL)getBrowsingMode
{
  return [MSHookIvar<BrowserController*>(((Application*)[%c(Application) sharedApplication]), "_controller") privateBrowsingEnabled];
}

%end

%hook BrowserToolbar

%new
- (BOOL)getBrowsingMode
{
  return [MSHookIvar<BrowserController*>(((Application*)[%c(Application) sharedApplication]), "_controller") privateBrowsingEnabled];
}

%end

%end


%hook Application

%new
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler
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

    NSMutableDictionary* otherPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:otherPlistPath];

    if(![[otherPlist allKeys] containsObject:@"desktopButtonSelected"])
    {
      //Create bool if it does not exist already
      [otherPlist setObject:[NSNumber numberWithBool:NO] forKey:@"desktopButtonSelected"];
      [otherPlist writeToFile:otherPlistPath atomically:YES];
    }

    desktopButtonSelected = [[otherPlist objectForKey:@"desktopButtonSelected"] boolValue];
  }

  BOOL orig = %orig;

  //Auto switch mode on launch
  if(preferenceManager.forceModeOnStartEnabled)
  {
    [self modeSwitchAction:preferenceManager.forceModeOnStartFor];
  }

  if(preferenceManager.desktopButtonEnabled)
  {
    [self updateDesktopMode];
  }

  return orig;
}

//Auto switch mode on app resume
- (void)applicationWillEnterForeground:(id)arg1
{
  %orig;
  if(preferenceManager.forceModeOnResumeEnabled)
  {
    [self modeSwitchAction:preferenceManager.forceModeOnResumeFor];
  }
}

//Auto switch mode on external URL opened
- (void)applicationOpenURL:(id)arg1
{
  if(preferenceManager.forceModeOnExternalLinkEnabled && arg1)
  {
    [self modeSwitchAction:preferenceManager.forceModeOnExternalLinkFor];
  }

  return %orig;
}

//Auto close tabs when Safari gets closed
- (void)applicationWillTerminate
{
  if(preferenceManager.autoCloseTabsEnabled && preferenceManager.autoCloseTabsOn == 1 /*Safari closed*/)
  {
    [self autoCloseAction];
  }
  if(preferenceManager.autoDeleteDataEnabled && preferenceManager.autoDeleteDataOn == 1 /*Safari closed*/)
  {
    [self clearData];
  }

  %orig;
}


//Auto close tabs when Safari gets minimized
- (void)applicationDidEnterBackground:(id)arg1
{
  if(preferenceManager.autoCloseTabsEnabled && preferenceManager.autoCloseTabsOn == 2 /*Safari minimized*/)
  {
    [self autoCloseAction];
  }
  if(preferenceManager.autoDeleteDataEnabled && preferenceManager.autoDeleteDataOn == 2 /*Safari closed*/)
  {
    [self clearData];
  }

  %orig;
}

//Write current status of desktop button to plist
%new
- (void)updateButtonState
{
  NSMutableDictionary* otherPlist = [[NSMutableDictionary alloc] initWithContentsOfFile:otherPlistPath];
  [otherPlist setObject:[NSNumber numberWithBool:desktopButtonSelected] forKey:@"desktopButtonSelected"];
  [otherPlist writeToFile:otherPlistPath atomically:YES];
}

%end

%hook BrowserController

//Returns status of tabbar (delegate function)
%new
- (BOOL)usesTabBar
{
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

%property(nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeLeftGestureRecognizer;
%property(nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeRightGestureRecognizer;
%property(nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeDownGestureRecognizer;

- (NavigationBar *)navigationBar
{
  if(preferenceManager.URLLeftSwipeGestureEnabled || preferenceManager.URLRightSwipeGestureEnabled || preferenceManager.URLDownSwipeGestureEnabled)
  {
    id orig = %orig;
    _SFNavigationBarURLButton* URLOutline = MSHookIvar<_SFNavigationBarURLButton*>(orig, "_URLOutline");
    if(preferenceManager.URLLeftSwipeGestureEnabled)
    {
      if(!self.URLBarSwipeLeftGestureRecognizer)
      {
        self.URLBarSwipeLeftGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(navigationBarURLWasSwiped:)];
        self.URLBarSwipeLeftGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
        [URLOutline addGestureRecognizer:self.URLBarSwipeLeftGestureRecognizer];
      }
    }
    if(preferenceManager.URLRightSwipeGestureEnabled)
    {
      if(!self.URLBarSwipeRightGestureRecognizer)
      {
        self.URLBarSwipeRightGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(navigationBarURLWasSwiped:)];
        self.URLBarSwipeRightGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
        [URLOutline addGestureRecognizer:self.URLBarSwipeRightGestureRecognizer];
      }
    }
    if(preferenceManager.URLDownSwipeGestureEnabled)
    {
      if(!self.URLBarSwipeDownGestureRecognizer)
      {
        self.URLBarSwipeDownGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(navigationBarURLWasSwiped:)];
        self.URLBarSwipeDownGestureRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
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
    [self handleSwipe:preferenceManager.URLLeftSwipeAction];
    break;

    case UISwipeGestureRecognizerDirectionRight:
    [self handleSwipe:preferenceManager.URLRightSwipeAction];
    break;

    case UISwipeGestureRecognizerDirectionDown:
    [self handleSwipe:preferenceManager.URLDownSwipeAction];
    break;
  }
}

%end

%hook TabController

%property (nonatomic,retain) UIButton *tiltedTabViewDesktopModeButton;

//Set state of desktop button
- (void)tiltedTabViewDidPresent:(id)arg1
{
  %orig;
  if(preferenceManager.desktopButtonEnabled)
  {
    if(desktopButtonSelected)
    {
      self.tiltedTabViewDesktopModeButton.selected = YES;
      self.tiltedTabViewDesktopModeButton.backgroundColor = [UIColor whiteColor];
    }
    else
    {
      self.tiltedTabViewDesktopModeButton.selected = NO;
      self.tiltedTabViewDesktopModeButton.backgroundColor = [UIColor clearColor];
    }
  }
}

//Desktop mode button : Portrait

- (NSArray *)tiltedTabViewToolbarItems
{
  if(preferenceManager.desktopButtonEnabled)
  {
    NSArray* old = %orig;

    if(!self.tiltedTabViewDesktopModeButton)
    {
      UIButton* desktopModeButtonPortrait = [UIButton buttonWithType:UIButtonTypeCustom];

      [desktopModeButtonPortrait setImage:[UIImage imageNamed:@"desktopButtonInactive.png" inBundle:SPBundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
      [desktopModeButtonPortrait setImage:[UIImage imageNamed:@"desktopButtonActive.png" inBundle:SPBundle compatibleWithTraitCollection:nil]  forState:UIControlStateSelected];
      desktopModeButtonPortrait.imageEdgeInsets = UIEdgeInsetsMake(2.5, 2.5, 2.5, 2.5);
      desktopModeButtonPortrait.layer.cornerRadius = 4;
      desktopModeButtonPortrait.adjustsImageWhenHighlighted = true;
      [desktopModeButtonPortrait addTarget:self action:@selector(tiltedTabViewDesktopModeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
      desktopModeButtonPortrait.frame = CGRectMake(0, 0, 27.5, 27.5);
      if(desktopButtonSelected)
      {
        desktopModeButtonPortrait.selected = YES;
        desktopModeButtonPortrait.backgroundColor = [UIColor whiteColor];
      }
      [self setTiltedTabViewDesktopModeButton:desktopModeButtonPortrait];
    }

    UIButton* emptySpace = [UIButton buttonWithType:UIButtonTypeCustom];
    emptySpace.imageEdgeInsets = UIEdgeInsetsMake(2.5, 2.5, 2.5, 2.5);
    emptySpace.layer.cornerRadius = 4;
    emptySpace.frame = CGRectMake(0, 0, 27.5, 27.5);

    UIBarButtonItem *customSpace = [[UIBarButtonItem alloc] initWithCustomView:emptySpace];

    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    UIBarButtonItem *userAgentBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.tiltedTabViewDesktopModeButton];

    return @[old[0], flexibleItem, userAgentBarButton, flexibleItem, old[2], flexibleItem, customSpace, flexibleItem, old[4], old[5]];
  }

  return %orig;
}

%new
- (void)tiltedTabViewDesktopModeButtonPressed
{
  if(desktopButtonSelected)
  {
    desktopButtonSelected = NO;
    self.tiltedTabViewDesktopModeButton.selected = NO;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    self.tiltedTabViewDesktopModeButton.backgroundColor = [UIColor clearColor];
    [UIView commitAnimations];
  }
  else
  {
    desktopButtonSelected = YES;
    self.tiltedTabViewDesktopModeButton.selected = YES;
    self.tiltedTabViewDesktopModeButton.backgroundColor = [UIColor whiteColor];
  }

  [self reloadTabsIfNeeded];
  [((Application*)[%c(Application) sharedApplication]) updateButtonState];
}

//Reload tabs if the useragents needs to be changed (depending on the desktop button state)
%new
- (void)reloadTabsIfNeeded
{
  NSArray* currentTabs;
  if([self isPrivateBrowsingEnabled])
  {
    currentTabs = self.privateTabDocuments;
  }
  else
  {
    currentTabs = self.tabDocuments;
  }

  for(TabDocument* tabDocument in currentTabs)
  {
    if(![tabDocument isBlankDocument] &&
      ((desktopButtonSelected && ([tabDocument.customUserAgent isEqualToString:@""] || tabDocument.customUserAgent == nil)) ||
      (!desktopButtonSelected && [tabDocument.customUserAgent isEqualToString:desktopUserAgent])))
    {
      [tabDocument reload];
    }
  }
}

%end

%hook TabDocument

BOOL showAlert = YES;

//Present download menu if clicked link is a downloadable file
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
  if(preferenceManager.enhancedDownloadsEnabled)
  {
    NSString* MIMEType = navigationResponse.response.MIMEType;

    //Check if alert should be presented
    if(showAlert && (!navigationResponse.canShowMIMEType || [MIMEType rangeOfString:@"video/"].location != NSNotFound || [MIMEType rangeOfString:@"audio/"].location != NSNotFound || [MIMEType isEqualToString:@"application/pdf"]))
    {
      //Cancel loading
      decisionHandler(WKNavigationResponsePolicyCancel);

      //Init variables so they can be accessed from the actions
      __block int64_t fileSize = navigationResponse.response.expectedContentLength;
      __block NSString* fileName = navigationResponse.response.suggestedFilename;
      __block NSString* fileDetails = [NSString stringWithFormat:@"%@ (%@)",
          fileName, [NSByteCountFormatter stringFromByteCount:fileSize countStyle:NSByteCountFormatterCountStyleFile]];
      __block NSURLRequest* request = navigationResponse._request;
      __block WKWebView* webViewLocal = webView;

      dispatch_async(dispatch_get_main_queue(), //Ensure we're on the main thread to avoid crashes
      ^{
        if(preferenceManager.instantDownloadsEnabled && preferenceManager.instantDownloadsOption == 1)
        {
          [[downloadManager sharedInstance] prepareDownloadFromRequest:request withSize:fileSize fileName:fileName];
        }
        else if(preferenceManager.instantDownloadsEnabled && preferenceManager.instantDownloadsOption == 2)
        {
          [[downloadManager sharedInstance] prepareDownloadFromRequest:request withSize:fileSize fileName:fileName customPath:YES];
        }
        else
        {
          //Create alert
          UIAlertController *downloadAlert = [UIAlertController alertControllerWithTitle:fileDetails message:nil preferredStyle:UIAlertControllerStyleActionSheet];

          UIAlertAction *downloadAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"DOWNLOAD"]
                style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                {
                  //Start download through SafariPlus
                  [[downloadManager sharedInstance] prepareDownloadFromRequest:request withSize:fileSize fileName:fileName];
                }];

          UIAlertAction *downloadToAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"DOWNLOAD_TO"]
                style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                {
                  //Start download through SafariPlus with custom path
                  [[downloadManager sharedInstance] prepareDownloadFromRequest:request withSize:fileSize fileName:fileName customPath:YES];
                }];

          UIAlertAction *viewAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"OPEN"]
                style:UIAlertActionStyleDefault handler:^(UIAlertAction * action)
                {
                  //Load request again and avoid another alert
                  showAlert = NO;
                  [webViewLocal loadRequest:request];
                }];

          UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CANCEL"]
                style:UIAlertActionStyleCancel handler:nil]; //Do nothing

          //Add actions to alert
          [downloadAlert addAction:downloadAction];
          [downloadAlert addAction:downloadToAction];
          [downloadAlert addAction:viewAction];
          [downloadAlert addAction:cancelAction];

          BrowserController* browserController = MSHookIvar<BrowserController*>(self, "_browserController");
          BrowserRootViewController* rootViewController = MSHookIvar<BrowserRootViewController*>(browserController, "_rootViewController");

          //iPad fix
          downloadAlert.popoverPresentationController.sourceView = rootViewController.view;
          downloadAlert.popoverPresentationController.sourceRect = CGRectMake(rootViewController.view.bounds.size.width / 2.0, rootViewController.view.bounds.size.height / 2, 1.0, 1.0);
          [downloadAlert.popoverPresentationController setPermittedArrowDirections:UIPopoverArrowDirectionDown];

          //Present alert on rootViewController
          [rootViewController presentViewController:downloadAlert animated:YES completion:nil];
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

- (id)_initWithTitle:(id)arg1 URL:(NSURL*)arg2 UUID:(id)arg3 privateBrowsingEnabled:(BOOL)arg4 bookmark:(id)arg5 browserController:(id)arg6 createDocumentView:(id)arg7
{
  if((preferenceManager.forceHTTPSEnabled || preferenceManager.desktopButtonEnabled) && arg2)
  {
    return %orig(arg1, [self URLHandler:arg2], arg3, arg4, arg5, arg6, arg7);
  }
  return %orig;
}

- (id)_loadURLInternal:(NSURL*)arg1 userDriven:(BOOL)arg2
{
  if((preferenceManager.forceHTTPSEnabled || preferenceManager.desktopButtonEnabled) && arg1)
  {
    return %orig([self URLHandler:arg1], arg2);
  }
  return %orig;
}

- (id)loadURL:(NSURL*)arg1 fromBookmark:(id)arg2
{
  if((preferenceManager.forceHTTPSEnabled || preferenceManager.desktopButtonEnabled) && arg1)
  {
    return %orig([self URLHandler:arg1], arg2);
  }
  return %orig;
}

- (void)_loadStartedDuringSimulatedClickForURL:(NSURL*)arg1
{
  if((preferenceManager.forceHTTPSEnabled || preferenceManager.desktopButtonEnabled) && arg1)
  {
    NSURL* newURL = [self URLHandler:arg1];
    if(![[newURL absoluteString] isEqualToString:[arg1 absoluteString]])
    {
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
  NSURLComponents* URLComponents = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:NO];

  if(preferenceManager.forceHTTPSEnabled && [URL.scheme isEqualToString:@"http"] && [self shouldRequestHTTPS:URL])
  {
    URLComponents.scheme = @"https";
  }

  if(preferenceManager.desktopButtonEnabled && desktopButtonSelected)
  {
    [self setCustomUserAgent:desktopUserAgent];
  }
  else if(preferenceManager.desktopButtonEnabled && !desktopButtonSelected)
  {
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
    if(preferenceManager.forceHTTPSEnabled && newURL)
    {
      if(([newURL rangeOfString:@"http://"].location == NSNotFound) && ([newURL rangeOfString:@"https://"].location == NSNotFound))
      {
        newURL = [@"http://" stringByAppendingString:newURL];
      }

      if([self shouldRequestHTTPS:[NSURL URLWithString:newURL]])
      {
        if([newURL rangeOfString:@"http://"].location != NSNotFound)
        {
          newURL = [newURL stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
        }
        else if([newURL rangeOfString:@"https://"].location == NSNotFound)
        {
          newURL = [@"https://" stringByAppendingString:newURL];
        }
      }
    }

    if(preferenceManager.desktopButtonEnabled && desktopButtonSelected)
    {
      [self setCustomUserAgent:desktopUserAgent];
    }
    else if(preferenceManager.desktopButtonEnabled && !desktopButtonSelected)
    {
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
  NSMutableDictionary* plist = [[NSMutableDictionary alloc] initWithContentsOfFile:otherPlistPath];

  NSMutableArray* ForceHTTPSExceptions = [plist objectForKey:@"ForceHTTPSExceptions"];

  for(NSString* exception in ForceHTTPSExceptions)
  {
    if([[URL host] rangeOfString:exception].location != NSNotFound)
    {
      return false;
    }
  }
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
    @autoreleasepool
    {
      id target = [self _completionItemAtIndexPath:indexPath];
      if([target isKindOfClass:[%c(WBSBookmarkAndHistoryCompletionMatch) class]]
      || [target isKindOfClass:[%c(SearchSuggestion) class]])
      {
        UILongPressGestureRecognizer* longPressRecognizer = [[UILongPressGestureRecognizer alloc]
                              initWithTarget:self action:@selector(handleLongPress:)];

        longPressRecognizer.minimumPressDuration = 1.0;
        [orig addGestureRecognizer:longPressRecognizer];
      }
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
    CompletionListTableViewController* completionTableController = MSHookIvar<CompletionListTableViewController*>(self, "_completionTableController");
    CGPoint p = [gestureRecognizer locationInView:completionTableController.tableView];
    NSIndexPath *indexPath = [completionTableController.tableView indexPathForRowAtPoint:p];
    if(indexPath != nil)
    {
      UITableViewCell *cell = [completionTableController.tableView cellForRowAtIndexPath:indexPath];
      if(cell.isHighlighted)
      {
        id target = [self _completionItemAtIndexPath:indexPath];

        UnifiedField* textField = MSHookIvar<UnifiedField*>(self, "_textField");

        if([target isKindOfClass:[%c(WBSBookmarkAndHistoryCompletionMatch) class]])
        {
          //Set URL to textField
          [textField setText:[target originalURLString]];
        }
        else //SearchSuggestion
        {
          //Set search string to textField
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

%hook BrowserToolbar

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
        self._downloadsItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"downloadsButton.png" inBundle:SPBundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self.browserDelegate action:@selector(downloadsFromButtonBar)];
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
          UIBarButtonItem* flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
          UIBarButtonItem *fixedItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
          UIBarButtonItem *fixedItemHalf = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];

          //Make everything flexible, thanks apple!
          fixedItem.width = 15;
          fixedItemHalf.width = 7.5f;
          UIBarButtonItem *fixedItemTwo = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
          fixedItemTwo.width = 6;

          orig = (NSMutableArray*)@[orig[1], fixedItem, flexibleItem, fixedItemHalf, orig[4], fixedItemHalf, flexibleItem, fixedItemTwo, orig[7], flexibleItem, orig[10], flexibleItem, self._downloadsItem, flexibleItem, orig[13]];
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
  if(preferenceManager.appTintColorNormalEnabled || preferenceManager.appTintColorPrivateEnabled)
  {
    BOOL privateMode = [self getBrowsingMode];
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

  if(preferenceManager.topBarColorNormalEnabled || preferenceManager.topBarColorPrivateEnabled)
  {
    BOOL privateMode = [self getBrowsingMode];
    _SFNavigationBarBackdrop* backdrop = MSHookIvar<_SFNavigationBarBackdrop*>(self, "_backdrop");

    if(preferenceManager.topBarColorNormalEnabled && !privateMode) //Normal Mode
    {
      backdrop.grayscaleTintView.backgroundColor = LCPParseColorString(preferenceManager.topBarColorNormal, @"#FFFFFF");
    }

    else if(preferenceManager.topBarColorPrivateEnabled && privateMode) //Private Mode
    {
      backdrop.grayscaleTintView.backgroundColor = LCPParseColorString(preferenceManager.topBarColorPrivate, @"#FFFFFF");
    }
  }
}

//Progress bar color
- (void)_updateProgressView
{
  %orig;
  if(preferenceManager.progressBarColorNormalEnabled || preferenceManager.progressBarColorPrivateEnabled)
  {
    BOOL privateMode = [self getBrowsingMode];
    _SFFluidProgressView* progressView = MSHookIvar<_SFFluidProgressView*>(self, "_progressView");
    if(preferenceManager.progressBarColorNormalEnabled && !privateMode)
    {
      progressView.progressBarFillColor = LCPParseColorString(preferenceManager.progressBarColorNormal, @"#FFFFFF");
    }
    else if(preferenceManager.progressBarColorPrivateEnabled && privateMode)
    {
      progressView.progressBarFillColor = LCPParseColorString(preferenceManager.progressBarColorPrivate, @"#FFFFFF");
    }
  }
}

//Text color
- (id)_URLTextColor
{
  if(preferenceManager.URLFontColorNormalEnabled || preferenceManager.URLFontColorPrivateEnabled)
  {
    BOOL privateMode = [self getBrowsingMode];
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
  if(preferenceManager.URLFontColorNormalEnabled || preferenceManager.URLFontColorPrivateEnabled)
  {
    BOOL privateMode = [self getBrowsingMode];
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
  if(preferenceManager.reloadColorNormalEnabled || preferenceManager.reloadColorPrivateEnabled)
  {
    BOOL privateMode = [self getBrowsingMode];
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
  if(preferenceManager.tabTitleColorNormalEnabled || preferenceManager.tabTitleColorPrivateEnabled)
  {
    BOOL privateMode = [self getBrowsingMode];
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
  if(preferenceManager.tabTitleColorNormalEnabled || preferenceManager.tabTitleColorPrivateEnabled)
  {
    BOOL privateMode = [self getBrowsingMode];
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
  if(preferenceManager.tabTitleColorNormalEnabled || preferenceManager.tabTitleColorPrivateEnabled)
  {
    BOOL privateMode = [self getBrowsingMode];
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
  if(preferenceManager.appTintColorNormalEnabled || preferenceManager.appTintColorPrivateEnabled)
  {
    BOOL privateMode = [self getBrowsingMode];
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
  if(preferenceManager.bottomBarColorNormalEnabled || preferenceManager.bottomBarColorPrivateEnabled)
  {
    BOOL privateMode = [self getBrowsingMode];
    _UIBackdropView* backgroundView = MSHookIvar<_UIBackdropView*>(self, "_backgroundView");
    backgroundView.grayscaleTintView.hidden = NO;
    if(preferenceManager.bottomBarColorNormalEnabled && !privateMode)
    {
      backgroundView.grayscaleTintView.backgroundColor = LCPParseColorString(preferenceManager.bottomBarColorNormal, @"#FFFFFF");
    }
    else if(preferenceManager.bottomBarColorPrivateEnabled && privateMode)
    {
      backgroundView.grayscaleTintView.backgroundColor = LCPParseColorString(preferenceManager.bottomBarColorPrivate, @"#FFFFFF");
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
    %init(iOS9);
  }
  else
  {
    %init(iOS10);
  }
  %init;

}
