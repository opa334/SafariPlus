//  SafariPlus.xm
//  Safari Hooks

// (c) 2017 opa334

#import "SafariPlus.h"

/****** Preference variables ******/

HBPreferences *preferences;

static BOOL enableFullscreenScrolling;
static BOOL forceHTTPSEnabled;
static BOOL disablePrivateMode;

static BOOL forceModeOnStartEnabled;
static NSInteger forceModeOnStartFor;
static BOOL forceModeOnResumeEnabled;
static NSInteger forceModeOnResumeFor;
static BOOL forceModeOnExternalLinkEnabled;
static NSInteger forceModeOnExternalLinkFor;
static BOOL autoCloseTabsEnabled;
static NSInteger autoCloseTabsOn;
static NSInteger autoCloseTabsFor;

static BOOL URLLeftSwipeGestureEnabled;
static NSInteger URLLeftSwipeAction;
static BOOL URLRightSwipeGestureEnabled;
static NSInteger URLRightSwipeAction;
static BOOL URLDownSwipeGestureEnabled;
static NSInteger URLDownSwipeAction;
static BOOL gestureBackground;

static BOOL openInNewTabOptionEnabled;
static BOOL desktopButtonEnabled;
static BOOL longPressSuggestionsEnabled;

static BOOL appTintColorNormalEnabled;
static NSString* appTintColorNormal;
static BOOL topBarColorNormalEnabled;
static NSString* topBarColorNormal;
static BOOL URLFontColorNormalEnabled;
static NSString* URLFontColorNormal;
static BOOL progressBarColorNormalEnabled;
static NSString* progressBarColorNormal;
static BOOL tabTitleColorNormalEnabled;
static NSString* tabTitleColorNormal;
static BOOL reloadColorNormalEnabled;
static NSString* reloadColorNormal;
static BOOL lockIconColorNormalEnabled;
static NSString* lockIconColorNormal;
static BOOL bottomBarColorNormalEnabled;
static NSString* bottomBarColorNormal;

static BOOL appTintColorPrivateEnabled;
static NSString* appTintColorPrivate;
static BOOL topBarColorPrivateEnabled;
static NSString* topBarColorPrivate;
static BOOL URLFontColorPrivateEnabled;
static NSString* URLFontColorPrivate;
static BOOL progressBarColorPrivateEnabled;
static NSString* progressBarColorPrivate;
static BOOL tabTitleColorPrivateEnabled;
static NSString* tabTitleColorPrivate;
static BOOL reloadColorPrivateEnabled;
static NSString* reloadColorPrivate;
static BOOL lockIconColorPrivateEnabled;
static NSString* lockIconColorPrivate;
static BOOL bottomBarColorPrivateEnabled;
static NSString* bottomBarColorPrivate;

/****** Other stuff ******/

BOOL desktopButtonSelected;

/****** Safari Hooks ******/

%group iOS10

%hook Application

//Gets called to update the tabs on startup
%new
- (void)updateDesktopMode
{
  [self.shortcutController.browserController.tabController reloadTabsIfNeeded];
}

//Gets called to switch mode based on the setting
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

//Gets called to close tabs based on the setting
%new
- (void)autoCloseAction
{
  switch(autoCloseTabsFor)
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
    [self loadURLInNewTab:[self.tabController.activeTabDocument URL] inBackground:gestureBackground animated:YES];
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

%hook TabOverview

%property (nonatomic,retain) UIButton *desktopModeButton;

//Desktop mode button : Landscape
- (void)layoutSubviews
{
  %orig;
  if(desktopButtonEnabled)
  {
    if(!self.desktopModeButton)
    {
      UIButton* desktopModeButton = [UIButton buttonWithType:UIButtonTypeCustom];

      [desktopModeButton setImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/desktopButtonInactive.png", bundlePath]] forState:UIControlStateNormal];
      [desktopModeButton setImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/desktopButtonActive.png", bundlePath]] forState:UIControlStateSelected];
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

//Extra 'Open in new Tab' option
- (NSMutableArray*)_actionsForElement:(_WKActivatedElementInfo*)arg1 defaultActions:(NSArray*)arg2 previewViewController:(id)arg3
{
  BOOL tabBar = ((Application*)[%c(Application) sharedApplication]).shortcutController.browserController.tabController.usesTabBar;
  if(openInNewTabOptionEnabled && arg1.type == 0 && !tabBar) //Showing the option is not needed, when a TabBar exists
  {
    NSMutableArray* options = %orig;

    _WKElementAction* openInNewTab = [%c(_WKElementAction) elementActionWithTitle:[LGShared localisedStringForKey:@"OPEN_IN_NEW_TAB_OPTION"] actionHandler:^
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
  if(lockIconColorNormalEnabled || lockIconColorPrivateEnabled)
  {
    BOOL privateMode = [self getBrowsingMode];
    if(lockIconColorNormalEnabled && !privateMode)
    {
      return LCPParseColorString(lockIconColorNormal, @"#FFFFFF");
    }
    else if(lockIconColorPrivateEnabled && privateMode)
    {
      return LCPParseColorString(lockIconColorPrivate, @"#FFFFFF");
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

//Gets called to update the tabs on startup
%new
- (void)updateDesktopMode
{
  BrowserController* browserController = MSHookIvar<BrowserController*>(self, "_controller");
  [browserController.tabController reloadTabsIfNeeded];
}

//Gets called to switch mode based on the setting
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

//Gets called to close tabs based on the setting
%new
- (void)autoCloseAction
{
  BrowserController* browserController = MSHookIvar<BrowserController*>(self, "_controller");

  switch(autoCloseTabsFor)
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
    [self loadURLInNewWindow:[self.tabController.activeTabDocument URL] inBackground:gestureBackground animated:YES];
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

%hook TabOverview

%property (nonatomic,retain) UIButton *desktopModeButton;

//Desktop mode button : Landscape
- (void)layoutSubviews
{
  %orig;
  if(desktopButtonEnabled)
  {
    if(!self.desktopModeButton)
    {
      UIButton* desktopModeButton = [UIButton buttonWithType:UIButtonTypeCustom];

      [desktopModeButton setImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/desktopButtonInactive.png", bundlePath]] forState:UIControlStateNormal];
      [desktopModeButton setImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/desktopButtonActive.png", bundlePath]] forState:UIControlStateSelected];
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
  if(openInNewTabOptionEnabled && arg1.type == 0 && !tabBar) //Showing the option is not needed, when a TabBar exists
  {
    NSMutableArray* options = %orig;

    _WKElementAction* openInNewTab = [%c(_WKElementAction) elementActionWithTitle:[LGShared localisedStringForKey:@"OPEN_IN_NEW_TAB_OPTION"] actionHandler:^
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
-(id)_lockImageWithTint:(id)arg1 usingMiniatureVersion:(BOOL)arg2
{
  if(lockIconColorNormalEnabled || lockIconColorPrivateEnabled)
  {
    BOOL privateMode = [self getBrowsingMode];
    if(lockIconColorNormalEnabled && !privateMode)
    {
      arg1 = LCPParseColorString(lockIconColorNormal, @"#FFFFFF");
    }
    else if(lockIconColorPrivateEnabled && privateMode)
    {
      arg1 = LCPParseColorString(lockIconColorPrivate, @"#FFFFFF");
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
- (BOOL)application:(id)arg1 didFinishLaunchingWithOptions:(id)arg2
{
  //Init plist for desktop button
  if(desktopButtonEnabled)
  {
    NSMutableDictionary* plist = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];

    if(![[plist allKeys] containsObject:@"desktopButtonSelected"])
    {
      [plist setObject:[NSNumber numberWithBool:NO] forKey:@"desktopButtonSelected"];
      [plist writeToFile:plistPath atomically:YES];
    }

    if([[plist objectForKey:@"desktopButtonSelected"] boolValue])
    {
      desktopButtonSelected = YES;
    }
  }

  BOOL orig = %orig;

  //Auto switch mode on launch
  if(forceModeOnStartEnabled)
  {
    [self modeSwitchAction:forceModeOnStartFor];
  }

  if(desktopButtonEnabled)
  {
    [self updateDesktopMode];
  }

  return orig;
}

//Auto switch mode on resume
- (void)applicationWillEnterForeground:(id)arg1
{
  %orig;
  if(forceModeOnResumeEnabled)
  {
    [self modeSwitchAction:forceModeOnResumeFor];
  }
}

//Auto switch mode on external URL opened
-(void)applicationOpenURL:(id)arg1
{
  if(forceModeOnExternalLinkEnabled && arg1)
  {
    [self modeSwitchAction:forceModeOnExternalLinkFor];
  }
  return %orig;
}

//Auto close tabs when Safari gets closed
- (void)applicationWillTerminate
{
  if(autoCloseTabsEnabled && autoCloseTabsOn == 1 /*Safari closed*/)
  {
    [self autoCloseAction];
  }
  %orig;
}


//Auto close tabs when Safari gets minimized
- (void)applicationDidEnterBackground:(id)arg1
{
  if(autoCloseTabsEnabled && autoCloseTabsOn == 2 /*Safari minimized*/)
  {
    [self autoCloseAction];
  }
  %orig;
}

%new
- (void)updateButtonState
{
  NSMutableDictionary* plist = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
  [plist setObject:[NSNumber numberWithBool:desktopButtonSelected] forKey:@"desktopButtonSelected"];
  [plist writeToFile:plistPath atomically:YES];
}

%end

%hook BrowserController

//Full screen scrolling
- (BOOL)_isVerticallyConstrained
{
  if(enableFullscreenScrolling)
  {
    return true;
  }

  return %orig;
}

//Fully disable private mode
- (BOOL)isPrivateBrowsingAvailable
{
  if(disablePrivateMode)
  {
    return false;
  }

  return %orig;
}

- (void)togglePrivateBrowsing
{
  %orig;
  if(desktopButtonEnabled)
  {
    [self.tabController reloadTabsIfNeeded];
  }
}

//Add swipe gestures to URL bar

UISwipeGestureRecognizer *swipeLeftGestureRecognizer;
UISwipeGestureRecognizer *swipeRightGestureRecognizer;
UISwipeGestureRecognizer *swipeDownGestureRecognizer;

- (NavigationBar *)navigationBar
{
  if(URLLeftSwipeGestureEnabled || URLRightSwipeGestureEnabled || URLDownSwipeGestureEnabled)
  {
    id orig = %orig;
    _SFNavigationBarURLButton* URLOutline = MSHookIvar<_SFNavigationBarURLButton*>(orig, "_URLOutline");
    if(URLLeftSwipeGestureEnabled)
    {
      if(!swipeLeftGestureRecognizer)
      {
        swipeLeftGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(navigationBarURLWasSwiped:)];
        swipeLeftGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
      }
      [URLOutline addGestureRecognizer:swipeLeftGestureRecognizer];
    }
    if(URLRightSwipeGestureEnabled)
    {
      if(!swipeRightGestureRecognizer)
      {
        swipeRightGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(navigationBarURLWasSwiped:)];
        swipeRightGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
      }
      [URLOutline addGestureRecognizer:swipeRightGestureRecognizer];
    }
    if(URLDownSwipeGestureEnabled)
    {
      if(!swipeDownGestureRecognizer)
      {
        swipeDownGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(navigationBarURLWasSwiped:)];
        swipeDownGestureRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
      }
      [URLOutline addGestureRecognizer:swipeDownGestureRecognizer];
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
    [self handleSwipe:URLLeftSwipeAction];
    break;

    case UISwipeGestureRecognizerDirectionRight:
    [self handleSwipe:URLRightSwipeAction];
    break;

    case UISwipeGestureRecognizerDirectionDown:
    [self handleSwipe:URLDownSwipeAction];
    break;
  }
}

%end

%hook TabController

%property (nonatomic,retain) UIButton *tiltedTabViewDesktopModeButton;

-(void)tiltedTabViewDidPresent:(id)arg1
{
  %orig;
  if(desktopButtonEnabled)
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
  if(desktopButtonEnabled)
  {
    NSArray* old = %orig;

    if(!self.tiltedTabViewDesktopModeButton)
    {
      UIButton* desktopModeButtonPortrait = [UIButton buttonWithType:UIButtonTypeCustom];

      [desktopModeButtonPortrait setImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/desktopButtonInactive.png", bundlePath]] forState:UIControlStateNormal];
      [desktopModeButtonPortrait setImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/desktopButtonActive.png", bundlePath]] forState:UIControlStateSelected];
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

  for(int i = 0; i < ([currentTabs count]); i++)
  {
    if(![(TabDocument*)currentTabs[i] isBlankDocument] &&
      ((desktopButtonSelected && (([((NSString*)((TabDocument*)currentTabs[i]).customUserAgent) isEqual:@""]) || (((NSString*)((TabDocument*)currentTabs[i]).customUserAgent) == nil))) ||
      (!desktopButtonSelected && [((NSString*)((TabDocument*)currentTabs[i]).customUserAgent) isEqual:desktopUserAgent])))
    {
      [(TabDocument*)currentTabs[i] reload];
    }
  }
}

%end

%hook TabDocument

//desktop mode + ForceHTTPS

- (id)_initWithTitle:(id)arg1 URL:(NSURL*)arg2 UUID:(id)arg3 privateBrowsingEnabled:(BOOL)arg4 bookmark:(id)arg5 browserController:(id)arg6 createDocumentView:(id)arg7
{
  if((forceHTTPSEnabled || desktopButtonEnabled) && arg2)
  {
    return %orig(arg1, [self URLHandler:arg2], arg3, arg4, arg5, arg6, arg7);
  }
  return %orig;
}

- (id)_loadURLInternal:(NSURL*)arg1 userDriven:(BOOL)arg2
{
  if((forceHTTPSEnabled || desktopButtonEnabled) && arg1)
  {
    return %orig([self URLHandler:arg1], arg2);
  }
  return %orig;
}

- (id)loadURL:(NSURL*)arg1 fromBookmark:(id)arg2
{
  if((forceHTTPSEnabled || desktopButtonEnabled) && arg1)
  {
    return %orig([self URLHandler:arg1], arg2);
  }
  return %orig;
}

- (void)_loadStartedDuringSimulatedClickForURL:(NSURL*)arg1
{
  if((forceHTTPSEnabled || desktopButtonEnabled) && arg1)
  {
    NSURL* newURL = [self URLHandler:arg1];
    if(![[newURL absoluteString] isEqual:[arg1 absoluteString]])
    {
      [self loadURL:newURL userDriven:NO];
      return;
    }
  }

  %orig;
}

- (void)reload
{
  if(forceHTTPSEnabled || desktopButtonEnabled)
  {
    NSURL* currentURL = (NSURL*)[self URL];
    NSURL* tmpURL = [self URLHandler:currentURL];
    if(![[tmpURL absoluteString] isEqual:[currentURL absoluteString]])
    {
      [self loadURL:tmpURL userDriven:NO];
      return;
    }
  }

  %orig;
}

%new
- (NSURL*)URLHandler:(NSURL*)URL
{
  NSURLComponents* URLComponents = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:NO];
  if(forceHTTPSEnabled)
  {
    if([self shouldRequestHTTPS:URL])
    {
      URLComponents.scheme = @"https";
    }
    else
    {
      URLComponents.scheme = @"http";
    }
  }


  if(desktopButtonEnabled && desktopButtonSelected)
  {
    [self setCustomUserAgent:desktopUserAgent];
  }
  else if(desktopButtonEnabled && !desktopButtonSelected)
  {
    [self setCustomUserAgent:@""];
  }

  return URLComponents.URL;
}

//Exception because method uses NSString instead of NSURL
- (NSString*)loadUserTypedAddress:(NSString*)arg1
{
  if(forceHTTPSEnabled || desktopButtonEnabled)
  {
    NSString* newURL = arg1;
    if(forceHTTPSEnabled && newURL)
    {
      if([self shouldRequestHTTPS:[NSURL URLWithString:arg1]])
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

    if(desktopButtonEnabled && desktopButtonSelected)
    {
      [self setCustomUserAgent:desktopUserAgent];
    }
    else if(desktopButtonEnabled && !desktopButtonSelected)
    {
      [self setCustomUserAgent:@""];
    }

    return %orig(newURL);
  }
  return %orig;
}

%new
- (BOOL)shouldRequestHTTPS:(NSURL*)URL
{
  NSMutableDictionary* plist = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];

  NSMutableArray* ForceHTTPSExceptions = [plist objectForKey:@"ForceHTTPSExceptions"];

  for(int i = 0; i < [ForceHTTPSExceptions count]; i++)
  {
    if([[URL host] rangeOfString:ForceHTTPSExceptions[i]].location != NSNotFound)
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
  if(longPressSuggestionsEnabled)
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

//Custom colors

%hook NavigationBar

- (void)_updateBackdropStyle
{
  %orig;
  if(appTintColorNormalEnabled || appTintColorPrivateEnabled)
  {
    BOOL privateMode = [self getBrowsingMode];
    if(appTintColorNormalEnabled && !privateMode)
    {
      self.tintColor = LCPParseColorString(appTintColorNormal, @"#FFFFFF");
    }
    else if(appTintColorPrivateEnabled && privateMode)
    {
      self.tintColor = LCPParseColorString(appTintColorPrivate, @"#FFFFFF");
    }
    else
    {
      [self _updateControlTints]; //Apply default color
    }
  }

  if(topBarColorNormalEnabled || topBarColorPrivateEnabled)
  {
    BOOL privateMode = [self getBrowsingMode];
    _SFNavigationBarBackdrop* backdrop = MSHookIvar<_SFNavigationBarBackdrop*>(self, "_backdrop");

    if(topBarColorNormalEnabled && !privateMode) //Normal Mode
    {
      backdrop.grayscaleTintView.backgroundColor = LCPParseColorString(topBarColorNormal, @"#FFFFFF");
    }

    else if(topBarColorPrivateEnabled && privateMode) //Private Mode
    {
      backdrop.grayscaleTintView.backgroundColor = LCPParseColorString(topBarColorPrivate, @"#FFFFFF");
    }
  }
}

//Progress bar color
- (void)_updateProgressView
{
  %orig;
  if(progressBarColorNormalEnabled || progressBarColorPrivateEnabled)
  {
    BOOL privateMode = [self getBrowsingMode];
    _SFFluidProgressView* progressView = MSHookIvar<_SFFluidProgressView*>(self, "_progressView");
    if(progressBarColorNormalEnabled && !privateMode)
    {
      progressView.progressBarFillColor = LCPParseColorString(progressBarColorNormal, @"#FFFFFF");
    }
    else if(progressBarColorPrivateEnabled && privateMode)
    {
      progressView.progressBarFillColor = LCPParseColorString(progressBarColorPrivate, @"#FFFFFF");
    }
  }
}

//Text color
- (id)_URLTextColor
{
  if(URLFontColorNormalEnabled || URLFontColorPrivateEnabled)
  {
    BOOL privateMode = [self getBrowsingMode];
    if(URLFontColorNormalEnabled && !privateMode)
    {
      return LCPParseColorString(URLFontColorNormal, @"#FFFFFF");
    }
    else if(URLFontColorPrivateEnabled && privateMode)
    {
      return LCPParseColorString(URLFontColorPrivate, @"#FFFFFF");
    }
  }

  return %orig;
}

//Text color of search text, needs to be less visible
- (id)_placeholderColor
{
  if(URLFontColorNormalEnabled || URLFontColorPrivateEnabled)
  {
    BOOL privateMode = [self getBrowsingMode];
    UIColor* customColor;
    if(URLFontColorNormalEnabled && !privateMode)
    {
      customColor = LCPParseColorString(URLFontColorNormal, @"#FFFFFF");
      return [customColor colorWithAlphaComponent:0.5];
    }
    else if(URLFontColorPrivateEnabled && privateMode)
    {
      customColor = LCPParseColorString(URLFontColorNormal, @"#FFFFFF");
      return [customColor colorWithAlphaComponent:0.5];
    }
  }

  return %orig;
}

//Reload button color
- (id)_URLControlsColor
{
  if(reloadColorNormalEnabled || reloadColorPrivateEnabled)
  {
    BOOL privateMode = [self getBrowsingMode];
    if(reloadColorNormalEnabled && !privateMode)
    {
      return LCPParseColorString(reloadColorNormal, @"#FFFFFF");
    }
    else if(reloadColorPrivateEnabled && privateMode)
    {
      return LCPParseColorString(reloadColorPrivate, @"#FFFFFF");
    }
  }

  return %orig;
}
%end

//Tab Title Color

%hook TabBarStyle
- (UIColor *)itemTitleColor
{
  if(tabTitleColorNormalEnabled || tabTitleColorPrivateEnabled)
  {
    BOOL privateMode = [self getBrowsingMode];
    UIColor* customColor = %orig;
    if(tabTitleColorNormalEnabled && !privateMode)
    {
      customColor = LCPParseColorString(tabTitleColorNormal, @"#FFFFFF");
    }
    else if(tabTitleColorPrivateEnabled && privateMode)
    {
      customColor = LCPParseColorString(tabTitleColorPrivate, @"#FFFFFF");
    }
    return customColor;
  }

  return %orig;
}
%end

%hook TiltedTabItem
- (UIColor *)titleColor
{
  if(tabTitleColorNormalEnabled || tabTitleColorPrivateEnabled)
  {
    BOOL privateMode = [self getBrowsingMode];
    UIColor* customColor = %orig;
    if(tabTitleColorNormalEnabled && !privateMode)
    {
      customColor = LCPParseColorString(tabTitleColorNormal, @"#FFFFFF");
    }
    else if(tabTitleColorPrivateEnabled && privateMode)
    {
      customColor = LCPParseColorString(tabTitleColorPrivate, @"#FFFFFF");
    }
    return customColor;
  }

  return %orig;
}
%end

%hook TabOverviewItem
- (UIColor *)titleColor
{
  if(tabTitleColorNormalEnabled || tabTitleColorPrivateEnabled)
  {
    BOOL privateMode = [self getBrowsingMode];
    UIColor* customColor = %orig;
    if(tabTitleColorNormalEnabled && !privateMode)
    {
      customColor = LCPParseColorString(tabTitleColorNormal, @"#FFFFFF");
    }
    else if(tabTitleColorPrivateEnabled && privateMode)
    {
      customColor = LCPParseColorString(tabTitleColorPrivate, @"#FFFFFF");
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
  if(appTintColorNormalEnabled || appTintColorPrivateEnabled)
  {
    BOOL privateMode = [self getBrowsingMode];
    if(appTintColorNormalEnabled && !privateMode)
    {
      self.tintColor = LCPParseColorString(appTintColorNormal, @"#FFFFFF");
    }
    else if(appTintColorPrivateEnabled && privateMode)
    {
      self.tintColor = LCPParseColorString(appTintColorPrivate, @"#FFFFFF");
    }
  }

  //Bottom Bar Color (kinda broken? For some reason it only works properly when SafariDownloader + is installed?)
  if(bottomBarColorNormalEnabled || bottomBarColorPrivateEnabled)
  {
    BOOL privateMode = [self getBrowsingMode];
    _UIBackdropView* backgroundView = MSHookIvar<_UIBackdropView*>(self, "_backgroundView");
    backgroundView.grayscaleTintView.hidden = NO;
    if(bottomBarColorNormalEnabled && !privateMode)
    {
      backgroundView.grayscaleTintView.backgroundColor = LCPParseColorString(bottomBarColorNormal, @"#FFFFFF");
    }
    else if(bottomBarColorPrivateEnabled && privateMode)
    {
      backgroundView.grayscaleTintView.backgroundColor = LCPParseColorString(bottomBarColorPrivate, @"#FFFFFF");
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

static NSString *const SarafiPlusPrefsDomain = @"com.opa334.safariplusprefs";

%ctor
{
  preferences = [[HBPreferences alloc] initWithIdentifier:SarafiPlusPrefsDomain];

  [preferences registerBool:&enableFullscreenScrolling default:NO forKey:@"fullscreenScrollingEnabled"];
  [preferences registerBool:&forceHTTPSEnabled default:NO forKey:@"forceHTTPSEnabled"];
  [preferences registerBool:&disablePrivateMode default:NO forKey:@"disablePrivateMode"];

  [preferences registerBool:&forceModeOnStartEnabled default:NO forKey:@"forceModeOnStartEnabled"];
  [preferences registerInteger:&forceModeOnStartFor default:0 forKey:@"forceModeOnStartFor"];
  [preferences registerBool:&forceModeOnResumeEnabled default:NO forKey:@"forceModeOnResumeEnabled"];
  [preferences registerInteger:&forceModeOnResumeFor default:0 forKey:@"forceModeOnResumeFor"];
  [preferences registerBool:&forceModeOnExternalLinkEnabled default:NO forKey:@"forceModeOnExternalLinkEnabled"];
  [preferences registerInteger:&forceModeOnExternalLinkFor default:0 forKey:@"forceModeOnExternalLinkFor"];
  [preferences registerBool:&autoCloseTabsEnabled default:NO forKey:@"autoCloseTabsEnabled"];
  [preferences registerInteger:&autoCloseTabsOn default:0 forKey:@"autoCloseTabsOn"];
  [preferences registerInteger:&autoCloseTabsFor default:0 forKey:@"autoCloseTabsFor"];

  [preferences registerBool:&URLLeftSwipeGestureEnabled default:NO forKey:@"URLLeftSwipeGestureEnabled"];
  [preferences registerInteger:&URLLeftSwipeAction default:0 forKey:@"URLLeftSwipeAction"];
  [preferences registerBool:&URLRightSwipeGestureEnabled default:NO forKey:@"URLRightSwipeGestureEnabled"];
  [preferences registerInteger:&URLRightSwipeAction default:0 forKey:@"URLRightSwipeAction"];
  [preferences registerBool:&URLDownSwipeGestureEnabled default:NO forKey:@"URLDownSwipeGestureEnabled"];
  [preferences registerInteger:&URLDownSwipeAction default:0 forKey:@"URLDownSwipeAction"];
  [preferences registerBool:&gestureBackground default:NO forKey:@"gestureBackground"];

  [preferences registerBool:&openInNewTabOptionEnabled default:NO forKey:@"openInNewTabOptionEnabled"];
  [preferences registerBool:&desktopButtonEnabled default:NO forKey:@"desktopButtonEnabled"];
  [preferences registerBool:&longPressSuggestionsEnabled default:NO forKey:@"longPressSuggestionsEnabled"];

  [preferences registerBool:&appTintColorNormalEnabled default:NO forKey:@"appTintColorNormalEnabled"];
  [preferences registerObject:&appTintColorNormal default:@"#ffffff" forKey:@"appTintColorNormal"];
  [preferences registerBool:&topBarColorNormalEnabled default:NO forKey:@"topBarColorNormalEnabled"];
  [preferences registerObject:&topBarColorNormal default:@"#ffffff" forKey:@"topBarColorNormal"];
  [preferences registerBool:&URLFontColorNormalEnabled default:NO forKey:@"URLFontColorNormalEnabled"];
  [preferences registerObject:&URLFontColorNormal default:@"#ffffff" forKey:@"URLFontColorNormal"];
  [preferences registerBool:&progressBarColorNormalEnabled default:NO forKey:@"progressBarColorNormalEnabled"];
  [preferences registerObject:&progressBarColorNormal default:@"#ffffff" forKey:@"progressBarColorNormal"];
  [preferences registerBool:&tabTitleColorNormalEnabled default:NO forKey:@"tabTitleColorNormalEnabled"];
  [preferences registerObject:&tabTitleColorNormal default:@"#ffffff" forKey:@"tabTitleColorNormal"];
  [preferences registerBool:&reloadColorNormalEnabled default:NO forKey:@"reloadColorNormalEnabled"];
  [preferences registerObject:&reloadColorNormal default:@"#ffffff" forKey:@"reloadColorNormal"];
  [preferences registerBool:&lockIconColorNormalEnabled default:NO forKey:@"lockIconColorNormalEnabled"];
  [preferences registerObject:&lockIconColorNormal default:@"#ffffff" forKey:@"lockIconColorNormal"];
  [preferences registerBool:&bottomBarColorNormalEnabled default:NO forKey:@"bottomBarColorNormalEnabled"];
  [preferences registerObject:&bottomBarColorNormal default:@"#ffffff" forKey:@"bottomBarColorNormal"];

  [preferences registerBool:&appTintColorPrivateEnabled default:NO forKey:@"appTintColorPrivateEnabled"];
  [preferences registerObject:&appTintColorPrivate default:@"#ffffff" forKey:@"appTintColorPrivate"];
  [preferences registerBool:&topBarColorPrivateEnabled default:NO forKey:@"topBarColorPrivateEnabled"];
  [preferences registerObject:&topBarColorPrivate default:@"#ffffff" forKey:@"topBarColorPrivate"];
  [preferences registerBool:&URLFontColorPrivateEnabled default:NO forKey:@"URLFontColorPrivateEnabled"];
  [preferences registerObject:&URLFontColorPrivate default:@"#ffffff" forKey:@"URLFontColorPrivate"];
  [preferences registerBool:&progressBarColorPrivateEnabled default:NO forKey:@"progressBarColorPrivateEnabled"];
  [preferences registerObject:&progressBarColorPrivate default:@"#ffffff" forKey:@"progressBarColorPrivate"];
  [preferences registerBool:&tabTitleColorPrivateEnabled default:NO forKey:@"tabTitleColorPrivateEnabled"];
  [preferences registerObject:&tabTitleColorPrivate default:@"#ffffff" forKey:@"tabTitleColorPrivate"];
  [preferences registerBool:&reloadColorPrivateEnabled default:NO forKey:@"reloadColorPrivateEnabled"];
  [preferences registerObject:&reloadColorPrivate default:@"#ffffff" forKey:@"reloadColorPrivate"];
  [preferences registerBool:&lockIconColorPrivateEnabled default:NO forKey:@"lockIconColorPrivateEnabled"];
  [preferences registerObject:&lockIconColorPrivate default:@"#ffffff" forKey:@"lockIconColorPrivate"];
  [preferences registerBool:&bottomBarColorPrivateEnabled default:NO forKey:@"bottomBarColorPrivateEnabled"];
  [preferences registerObject:&bottomBarColorPrivate default:@"#ffffff" forKey:@"bottomBarColorPrivate"];

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
