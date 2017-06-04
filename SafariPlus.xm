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

UIButton* userAgentButtonPortrait = [UIButton buttonWithType:UIButtonTypeCustom];
UIButton* userAgentButtonLandscape = [UIButton buttonWithType:UIButtonTypeCustom];

NSMutableDictionary* plist;

/****** Safari Hooks ******/

%hook Application
- (BOOL)application:(id)arg1 didFinishLaunchingWithOptions:(id)arg2
{
  BOOL orig = %orig;

  //Auto switch mode on launch
  if(forceModeOnStartEnabled)
  {
    [self modeSwitchAction:forceModeOnStartFor];
  }

  //Init plist and apply contents to buttons
  if(desktopButtonEnabled)
  {
    if(!plist)
    {
      plist = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    }

    if(![[plist allKeys] containsObject:@"desktopButtonSelected"])
    {
      [plist setObject:[NSNumber numberWithBool:NO] forKey:@"desktopButtonSelected"];
      [plist writeToFile:plistPath atomically:YES];
    }

    if([[plist objectForKey:@"desktopButtonSelected"] boolValue])
    {
      userAgentButtonPortrait.backgroundColor = [UIColor whiteColor];
      userAgentButtonPortrait.selected = YES;

      userAgentButtonLandscape.backgroundColor = [UIColor whiteColor];
      userAgentButtonLandscape.selected = YES;
    }
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

//Auto close tabs when Safari gets closed
- (void)applicationWillTerminate
{
  if(autoCloseTabsEnabled && autoCloseTabsOn == 1 /*Safari closed*/)
  {
    [self autoCloseAction];
  }
  if(desktopButtonEnabled)
  {
    [plist setObject:[NSNumber numberWithBool:userAgentButtonPortrait.selected] forKey:@"desktopButtonSelected"];
    [plist writeToFile:plistPath atomically:YES];
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

//Gets called to switch mode based on the setting
%new
- (void)modeSwitchAction:(int)switchToMode
{
    if(switchToMode == 1 /*Normal Mode*/ && [self isPrivateBrowsingEnabledInAnyWindow])
    {
      [self.shortcutController.browserController togglePrivateBrowsing];
    }

    else if(switchToMode == 2 /*Private Mode*/  && ![self isPrivateBrowsingEnabledInAnyWindow])
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
    if([self isPrivateBrowsingEnabledInAnyWindow])
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
    if(![self isPrivateBrowsingEnabledInAnyWindow])
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

//Auto switch mode on external URL opened
- (id)handleExternalURL:(id)arg1
{
  if(forceModeOnExternalLinkEnabled && arg1)
  {
    if(forceModeOnExternalLinkFor == 1 /*Normal Mode*/ && [self privateBrowsingEnabled])
    {
      [self togglePrivateBrowsing];
    }
    else if(forceModeOnExternalLinkFor == 2 /*Private Mode*/ && ![self privateBrowsingEnabled])
    {
      [self togglePrivateBrowsing];
      [self.tabController.tiltedTabView setShowsExplanationView:NO animated:NO]; //Fixes a little issue with the "private mode" description
    }
  }
  return %orig;
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
    [self loadURLInNewTab:[self.tabController.activeTabDocument URL] inBackground:gestureBackground animated:1];
    break;

    case 4: //Close all tabs from active mode
    [self.tabController closeAllOpenTabsAnimated:NO exitTabView:YES];
    shouldClean = YES;
    break;

    case 5: //Switch mode (Normal/Private)
    [self togglePrivateBrowsing];
    shouldClean = YES;
    break;

    default:
    break;
  }
  if(shouldClean && [self privateBrowsingEnabled])
  {
    [self.tabController.tiltedTabView setShowsExplanationView:NO animated:NO];
  }
}

//Desktop mode button : Landscape
- (void)willPresentTabOverview
{
  %orig;
  if(desktopButtonEnabled)
  {
    [userAgentButtonLandscape setImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/desktopButtonInactive.png", bundlePath]] forState:UIControlStateNormal];
    [userAgentButtonLandscape setImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/desktopButtonActive.png", bundlePath]] forState:UIControlStateSelected];
    userAgentButtonLandscape.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    userAgentButtonLandscape.layer.cornerRadius = 4;
    userAgentButtonLandscape.adjustsImageWhenHighlighted = true;
    [userAgentButtonLandscape addTarget:self action:@selector(userAgentButtonLandscapePressed) forControlEvents:UIControlEventTouchUpInside];
    userAgentButtonLandscape.frame = CGRectMake(self.tabController.tabOverview.privateBrowsingButton.frame.origin.x - 57.5, self.tabController.tabOverview.privateBrowsingButton.frame.origin.y, self.tabController.tabOverview.privateBrowsingButton.frame.size.height, self.tabController.tabOverview.privateBrowsingButton.frame.size.height);

    _UIBackdropView* header = MSHookIvar<_UIBackdropView*>(self.tabController.tabOverview, "_header");
    [header.contentView addSubview:userAgentButtonLandscape];
  }
}

%new
- (void)userAgentButtonLandscapePressed
{
  if(userAgentButtonLandscape.selected)
  {
    userAgentButtonLandscape.selected = NO;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    userAgentButtonLandscape.backgroundColor = [UIColor clearColor];
    [UIView commitAnimations];

    userAgentButtonPortrait.selected = NO;
    userAgentButtonPortrait.backgroundColor = [UIColor clearColor];
  }
  else
  {
    userAgentButtonLandscape.selected = YES;
    userAgentButtonLandscape.backgroundColor = [UIColor whiteColor]; //NOTE: Eclipse replaces this color with grey, fix needed (if even possible)

    userAgentButtonPortrait.selected = YES;
    userAgentButtonPortrait.backgroundColor = [UIColor whiteColor];
  }
}
%end

%hook TabController

//Desktop mode button : Portrait
- (NSArray *)tiltedTabViewToolbarItems
{
  if(desktopButtonEnabled)
  {
    [userAgentButtonPortrait setImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/desktopButtonInactive.png", bundlePath]] forState:UIControlStateNormal];
    [userAgentButtonPortrait setImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/desktopButtonActive.png", bundlePath]] forState:UIControlStateSelected];
    userAgentButtonPortrait.imageEdgeInsets = UIEdgeInsetsMake(2.5, 2.5, 2.5, 2.5);
    userAgentButtonPortrait.layer.cornerRadius = 4;
    userAgentButtonPortrait.adjustsImageWhenHighlighted = true;
    [userAgentButtonPortrait addTarget:self action:@selector(userAgentButtonPortraitPressed) forControlEvents:UIControlEventTouchUpInside];
    userAgentButtonPortrait.frame = CGRectMake(0, 0, 27.5, 27.5);

    UIBarButtonItem *userAgentBarButton = [[UIBarButtonItem alloc] initWithCustomView:userAgentButtonPortrait];

    NSArray* old = %orig;
    NSArray* newArray = [NSArray array];
    newArray = @[old[0], old[1], userAgentBarButton, old[1], old[2], old[3], old[1], old[1], old[4], old[5]];
    return newArray;
  }

  return %orig;
}

%new
- (void)userAgentButtonPortraitPressed
{
  if(userAgentButtonPortrait.selected)
  {
    userAgentButtonPortrait.selected = NO;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    userAgentButtonPortrait.backgroundColor = [UIColor clearColor];
    [UIView commitAnimations];

    userAgentButtonLandscape.selected = NO;
    userAgentButtonLandscape.backgroundColor = [UIColor clearColor];
  }
  else
  {
    userAgentButtonPortrait.selected = YES;
    userAgentButtonPortrait.backgroundColor = [UIColor whiteColor];

    userAgentButtonLandscape.selected = YES;
    userAgentButtonLandscape.backgroundColor = [UIColor whiteColor];
  }
}

%end

%hook TabDocument

//Extra 'Open in new Tab' option

- (NSArray*)_actionsForElement:(_WKActivatedElementInfo*)arg1 defaultActions:(NSArray*)arg2 previewViewController:(id)arg3
{
  if(openInNewTabOptionEnabled)
  {
    NSArray* oldArray = %orig;

    _WKElementAction* openInNewTab = [%c(_WKElementAction) elementActionWithTitle:[LGShared localisedStringForKey:@"OPEN_IN_NEW_TAB_OPTION"] actionHandler:^
    {
      [self.browserController loadURLInNewTab:arg1.URL inBackground:0];
    }];

    NSArray* newArray = [NSArray array];
    newArray = @[oldArray[0], openInNewTab, oldArray[1], oldArray[2], oldArray[3], oldArray[4]];

    return newArray;
  }
  return %orig;
}

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
    %orig([self URLHandler:arg1]);
  }
  else
  {
    %orig;
  }
}

%new
- (NSURL*)URLHandler:(NSURL*)URL
{
  if(forceHTTPSEnabled && [URL.port intValue] != 443 /*HTTPS port*/)
  {
    URL = [NSURL URLWithString:[[URL absoluteString] stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"]];
  }

  if(desktopButtonEnabled && userAgentButtonPortrait.selected && !self.reloadOptionsController.loadedUsingDesktopUserAgent)
  {
    [self.reloadOptionsController requestDesktopSiteWithURL:URL];
  }

  return URL;
}

//Exception because method uses NSString instead of NSURL
- (NSString*)loadUserTypedAddress:(NSString*)arg1
{
  if(forceHTTPSEnabled || desktopButtonEnabled)
  {
    NSString* newURL = arg1;
    if(forceHTTPSEnabled && arg1)
    {
      if([arg1 rangeOfString:@"http://"].location != NSNotFound)
      {
        newURL = [arg1 stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
      }
      else if([arg1 rangeOfString:@"https://"].location == NSNotFound)
      {
        newURL = [@"https://" stringByAppendingString:arg1];
      }
    }

    if(desktopButtonEnabled && userAgentButtonPortrait.selected && !self.reloadOptionsController.loadedUsingDesktopUserAgent)
    {
      [self.reloadOptionsController requestDesktopSiteWithURL:[NSURL URLWithString:newURL]];
      return nil;
    }

    return %orig(newURL);
  }
  return %orig;
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
    if (indexPath != nil)
    {
      UITableViewCell *cell = [completionTableController.tableView cellForRowAtIndexPath:indexPath];
      if(cell.isHighlighted)
      {
        id target = [self _completionItemAtIndexPath:indexPath];
        if([target isKindOfClass:[%c(WBSBookmarkAndHistoryCompletionMatch) class]])
        {
          //Set URL to textField
          [self.textField setText:[target originalURLString]];
        }
        else //SearchSuggestion
        {
          //Set search string to textField
          [self.textField setText:[target string]];
        }

        //Pull up keyboard, if not active already
        if(![self.textField isFirstResponder])
        {
          [self.textField becomeFirstResponder];
        }

        //Update Entries
        [self.textField _textDidChangeFromTyping];
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
    BOOL privateMode = [((Application*)[%c(Application) sharedApplication]) isPrivateBrowsingEnabledInAnyWindow];

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
    BOOL privateMode = [((Application*)[%c(Application) sharedApplication]) isPrivateBrowsingEnabledInAnyWindow];
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
    BOOL privateMode = [((Application*)[%c(Application) sharedApplication]) isPrivateBrowsingEnabledInAnyWindow];
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
    BOOL privateMode = [((Application*)[%c(Application) sharedApplication]) isPrivateBrowsingEnabledInAnyWindow];
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
    BOOL privateMode = [((Application*)[%c(Application) sharedApplication]) isPrivateBrowsingEnabledInAnyWindow];
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
    BOOL privateMode = [((Application*)[%c(Application) sharedApplication]) isPrivateBrowsingEnabledInAnyWindow];
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

//Lock icon color
- (id)_tintForLockImage:(BOOL)arg1
{
  if(lockIconColorNormalEnabled || lockIconColorPrivateEnabled)
  {
    BOOL privateMode = [((Application*)[%c(Application) sharedApplication]) isPrivateBrowsingEnabledInAnyWindow];
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

%end

//Tab Title Color

%hook TabBarStyle
- (UIColor *)itemTitleColor
{
  if(tabTitleColorNormalEnabled || tabTitleColorPrivateEnabled)
  {
    BOOL privateMode = [((Application*)[%c(Application) sharedApplication]) isPrivateBrowsingEnabledInAnyWindow];
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
    BOOL privateMode = [((Application*)[%c(Application) sharedApplication]) isPrivateBrowsingEnabledInAnyWindow];
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
    BOOL privateMode = [((Application*)[%c(Application) sharedApplication]) isPrivateBrowsingEnabledInAnyWindow];
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
    BOOL privateMode = [((Application*)[%c(Application) sharedApplication]) isPrivateBrowsingEnabledInAnyWindow];
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
    BOOL privateMode = [((Application*)[%c(Application) sharedApplication]) isPrivateBrowsingEnabledInAnyWindow];
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

}
