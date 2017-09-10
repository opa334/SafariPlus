//  SPPreferenceManager.xm
// (c) 2017 opa334

#import "SPPreferenceManager.h"

@implementation SPPreferenceManager

+ (instancetype)sharedInstance
{
    static SPPreferenceManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SPPreferenceManager alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
  self = [super init];

  #ifdef SIMJECT

  //Simject preferences (No preference bundle in Simulator)
  _forceHTTPSEnabled = YES;
  _openInOppositeModeOptionEnabled = YES;
  _openInNewTabOptionEnabled = YES;
  _uploadAnyFileOptionEnabled = YES;
  _desktopButtonEnabled = YES;
  _longPressSuggestionsEnabled = YES;
  _longPressSuggestionsDuration = 0.25;
  _longPressSuggestionsFocusEnabled = NO;

  _enhancedDownloadsEnabled = YES;
  _instantDownloadsEnabled = NO;
  _instantDownloadsOption = 0;
  _customDefaultPathEnabled = NO;
  _customDefaultPath = @"";
  _pinnedLocationsEnabled = NO;
  _onlyDownloadOnWifiEnabled = NO;
  _disablePushNotificationsEnabled = NO;
  _disableBarNotificationsEnabled = NO;

  _forceModeOnStartEnabled = YES;
  _forceModeOnStartFor = 1; //1: Normal Mode, 2: Private Mode
  _forceModeOnResumeEnabled = NO;
  _forceModeOnResumeFor = 1; //1: Normal Mode, 2: Private Mode
  _forceModeOnExternalLinkEnabled = NO;
  _forceModeOnResumeFor = 1; //1: Normal Mode, 2: Private Mode
  _autoCloseTabsEnabled = NO;
  _autoCloseTabsOn = 1; //1: Closed, 2: Minimized
  _autoCloseTabsFor = 1; //1: Active Mode, 2: Normal Mode, 3: Private Mode, 4: Both Modes
  _autoDeleteDataEnabled = NO;
  _autoDeleteDataOn = 1; //1: Closed, 2: Minimized

  //Actions:
  //1: Close Active Tab 2: New Tab, 3: Duplicate Active Tab, 4: Close all tabs from surfing mode
  //5: Switch surfing mode, 6: Switch tab backwards 7: Switch tab forwards 8: Reload active tab
  //9: Request desktop site, 10: Open search
  _URLLeftSwipeGestureEnabled = YES;
  _URLLeftSwipeAction = 6;
  _URLRightSwipeGestureEnabled = YES;
  _URLRightSwipeAction = 7;
  _URLDownSwipeGestureEnabled = YES;
  _URLDownSwipeAction = 5;

  _enableFullscreenScrolling = YES;
  _disablePrivateMode = NO;
  _alwaysOpenNewTabEnabled = NO;
  _suppressMailToDialog = NO;

  _appTintColorNormalEnabled = NO;
  _topBarColorNormalEnabled = NO;
  _URLFontColorNormalEnabled = NO;
  _progressBarColorNormalEnabled = NO;
  _tabTitleColorNormalEnabled = NO;
  _reloadColorNormalEnabled = NO;
  _lockIconColorNormalEnabled = NO;
  _bottomBarColorNormalEnabled = NO;

  _appTintColorPrivateEnabled = NO;
  _topBarColorPrivateEnabled = NO;
  _URLFontColorPrivateEnabled = NO;
  _progressBarColorPrivateEnabled = NO;
  _tabTitleColorPrivateEnabled = NO;
  _reloadColorPrivateEnabled = NO;
  _lockIconColorPrivateEnabled = NO;
  _bottomBarColorPrivateEnabled = NO;

  #else

  preferences = [[HBPreferences alloc] initWithIdentifier:SarafiPlusPrefsDomain];

  [preferences registerBool:&_forceHTTPSEnabled default:NO forKey:@"forceHTTPSEnabled"];
  [preferences registerBool:&_openInOppositeModeOptionEnabled default:NO forKey:@"openInOppositeModeOptionEnabled"];
  [preferences registerBool:&_openInNewTabOptionEnabled default:NO forKey:@"openInNewTabOptionEnabled"];
  [preferences registerBool:&_uploadAnyFileOptionEnabled default:NO forKey:@"uploadAnyFileOptionEnabled"];
  [preferences registerBool:&_desktopButtonEnabled default:NO forKey:@"desktopButtonEnabled"];
  [preferences registerBool:&_longPressSuggestionsEnabled default:NO forKey:@"longPressSuggestionsEnabled"];
  [preferences registerFloat:&_longPressSuggestionsDuration default:1 forKey:@"longPressSuggestionsDuration"];
  [preferences registerBool:&_longPressSuggestionsFocusEnabled default:YES forKey:@"longPressSuggestionsFocusEnabled"];

  [preferences registerBool:&_enhancedDownloadsEnabled default:NO forKey:@"enhancedDownloadsEnabled"];
  [preferences registerBool:&_instantDownloadsEnabled default:NO forKey:@"instantDownloadsEnabled"];
  [preferences registerInteger:&_instantDownloadsOption default:NO forKey:@"instantDownloadsOption"];
  [preferences registerBool:&_customDefaultPathEnabled default:NO forKey:@"customDefaultPathEnabled"];
  [preferences registerObject:&_customDefaultPath default:defaultDownloadPath forKey:@"customDefaultPath"];
  [preferences registerBool:&_pinnedLocationsEnabled default:NO forKey:@"pinnedLocationsEnabled"];
  [preferences registerBool:&_onlyDownloadOnWifiEnabled default:NO forKey:@"onlyDownloadOnWifiEnabled"];
  [preferences registerBool:&_disablePushNotificationsEnabled default:NO forKey:@"disablePushNotificationsEnabled"];
  [preferences registerBool:&_disableBarNotificationsEnabled default:NO forKey:@"disableBarNotificationsEnabled"];

  [preferences registerBool:&_forceModeOnStartEnabled default:NO forKey:@"forceModeOnStartEnabled"];
  [preferences registerInteger:&_forceModeOnStartFor default:0 forKey:@"forceModeOnStartFor"];
  [preferences registerBool:&_forceModeOnResumeEnabled default:NO forKey:@"forceModeOnResumeEnabled"];
  [preferences registerInteger:&_forceModeOnResumeFor default:0 forKey:@"forceModeOnResumeFor"];
  [preferences registerBool:&_forceModeOnExternalLinkEnabled default:NO forKey:@"forceModeOnExternalLinkEnabled"];
  [preferences registerInteger:&_forceModeOnExternalLinkFor default:0 forKey:@"forceModeOnExternalLinkFor"];
  [preferences registerBool:&_autoCloseTabsEnabled default:NO forKey:@"autoCloseTabsEnabled"];
  [preferences registerInteger:&_autoCloseTabsOn default:0 forKey:@"autoCloseTabsOn"];
  [preferences registerInteger:&_autoCloseTabsFor default:0 forKey:@"autoCloseTabsFor"];
  [preferences registerBool:&_autoDeleteDataEnabled default:NO forKey:@"autoDeleteDataEnabled"];
  [preferences registerInteger:&_autoDeleteDataOn default:0 forKey:@"autoDeleteDataOn"];

  [preferences registerBool:&_URLLeftSwipeGestureEnabled default:NO forKey:@"URLLeftSwipeGestureEnabled"];
  [preferences registerInteger:&_URLLeftSwipeAction default:0 forKey:@"URLLeftSwipeAction"];
  [preferences registerBool:&_URLRightSwipeGestureEnabled default:NO forKey:@"URLRightSwipeGestureEnabled"];
  [preferences registerInteger:&_URLRightSwipeAction default:0 forKey:@"URLRightSwipeAction"];
  [preferences registerBool:&_URLDownSwipeGestureEnabled default:NO forKey:@"URLDownSwipeGestureEnabled"];
  [preferences registerInteger:&_URLDownSwipeAction default:0 forKey:@"URLDownSwipeAction"];
  [preferences registerBool:&_gestureBackground default:NO forKey:@"gestureBackground"];

  [preferences registerBool:&_enableFullscreenScrolling default:NO forKey:@"fullscreenScrollingEnabled"];
  [preferences registerBool:&_disablePrivateMode default:NO forKey:@"disablePrivateMode"];
  [preferences registerBool:&_alwaysOpenNewTabEnabled default:NO forKey:@"alwaysOpenNewTabEnabled"];
  [preferences registerBool:&_suppressMailToDialog default:NO forKey:@"suppressMailToDialog"];

  [preferences registerBool:&_appTintColorNormalEnabled default:NO forKey:@"appTintColorNormalEnabled"];
  [preferences registerObject:&_appTintColorNormal default:@"#ffffff" forKey:@"appTintColorNormal"];
  [preferences registerBool:&_topBarColorNormalEnabled default:NO forKey:@"topBarColorNormalEnabled"];
  [preferences registerObject:&_topBarColorNormal default:@"#ffffff" forKey:@"topBarColorNormal"];
  [preferences registerBool:&_URLFontColorNormalEnabled default:NO forKey:@"URLFontColorNormalEnabled"];
  [preferences registerObject:&_URLFontColorNormal default:@"#ffffff" forKey:@"URLFontColorNormal"];
  [preferences registerBool:&_progressBarColorNormalEnabled default:NO forKey:@"progressBarColorNormalEnabled"];
  [preferences registerObject:&_progressBarColorNormal default:@"#ffffff" forKey:@"progressBarColorNormal"];
  [preferences registerBool:&_tabTitleColorNormalEnabled default:NO forKey:@"tabTitleColorNormalEnabled"];
  [preferences registerObject:&_tabTitleColorNormal default:@"#ffffff" forKey:@"tabTitleColorNormal"];
  [preferences registerBool:&_reloadColorNormalEnabled default:NO forKey:@"reloadColorNormalEnabled"];
  [preferences registerObject:&_reloadColorNormal default:@"#ffffff" forKey:@"reloadColorNormal"];
  [preferences registerBool:&_lockIconColorNormalEnabled default:NO forKey:@"lockIconColorNormalEnabled"];
  [preferences registerObject:&_lockIconColorNormal default:@"#ffffff" forKey:@"lockIconColorNormal"];
  [preferences registerBool:&_bottomBarColorNormalEnabled default:NO forKey:@"bottomBarColorNormalEnabled"];
  [preferences registerObject:&_bottomBarColorNormal default:@"#ffffff" forKey:@"bottomBarColorNormal"];

  [preferences registerBool:&_appTintColorPrivateEnabled default:NO forKey:@"appTintColorPrivateEnabled"];
  [preferences registerObject:&_appTintColorPrivate default:@"#ffffff" forKey:@"appTintColorPrivate"];
  [preferences registerBool:&_topBarColorPrivateEnabled default:NO forKey:@"topBarColorPrivateEnabled"];
  [preferences registerObject:&_topBarColorPrivate default:@"#ffffff" forKey:@"topBarColorPrivate"];
  [preferences registerBool:&_URLFontColorPrivateEnabled default:NO forKey:@"URLFontColorPrivateEnabled"];
  [preferences registerObject:&_URLFontColorPrivate default:@"#ffffff" forKey:@"URLFontColorPrivate"];
  [preferences registerBool:&_progressBarColorPrivateEnabled default:NO forKey:@"progressBarColorPrivateEnabled"];
  [preferences registerObject:&_progressBarColorPrivate default:@"#ffffff" forKey:@"progressBarColorPrivate"];
  [preferences registerBool:&_tabTitleColorPrivateEnabled default:NO forKey:@"tabTitleColorPrivateEnabled"];
  [preferences registerObject:&_tabTitleColorPrivate default:@"#ffffff" forKey:@"tabTitleColorPrivate"];
  [preferences registerBool:&_reloadColorPrivateEnabled default:NO forKey:@"reloadColorPrivateEnabled"];
  [preferences registerObject:&_reloadColorPrivate default:@"#ffffff" forKey:@"reloadColorPrivate"];
  [preferences registerBool:&_lockIconColorPrivateEnabled default:NO forKey:@"lockIconColorPrivateEnabled"];
  [preferences registerObject:&_lockIconColorPrivate default:@"#ffffff" forKey:@"lockIconColorPrivate"];
  [preferences registerBool:&_bottomBarColorPrivateEnabled default:NO forKey:@"bottomBarColorPrivateEnabled"];
  [preferences registerObject:&_bottomBarColorPrivate default:@"#ffffff" forKey:@"bottomBarColorPrivate"];

  #endif

  return self;
}

@end
