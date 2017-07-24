//  SafariPlusUtil.xm
//  Localization manager and preference manager

// (c) 2017 opa334


#import "SafariPlusUtil.h"

static NSString *const SarafiPlusPrefsDomain = @"com.opa334.safariplusprefs";

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

  preferences = [[HBPreferences alloc] initWithIdentifier:SarafiPlusPrefsDomain];

  [preferences registerBool:&_enableFullscreenScrolling default:NO forKey:@"fullscreenScrollingEnabled"];
  [preferences registerBool:&_forceHTTPSEnabled default:NO forKey:@"forceHTTPSEnabled"];
  [preferences registerBool:&_disablePrivateMode default:NO forKey:@"disablePrivateMode"];
  [preferences registerBool:&_uploadAnyFileOptionEnabled default:NO forKey:@"uploadAnyFileOptionEnabled"];

  [preferences registerBool:&_enhancedDownloadsEnabled default:NO forKey:@"enhancedDownloadsEnabled"];
  [preferences registerBool:&_instantDownloadsEnabled default:NO forKey:@"instantDownloadsEnabled"];
  [preferences registerInteger:&_instantDownloadsOption default:NO forKey:@"instantDownloadsOption"];
  [preferences registerBool:&_customDefaultPathEnabled default:NO forKey:@"customDefaultPathEnabled"];
  [preferences registerObject:&_customDefaultPath default:@"/User/Downloads/" forKey:@"customDefaultPath"];
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

  [preferences registerBool:&_URLLeftSwipeGestureEnabled default:NO forKey:@"URLLeftSwipeGestureEnabled"];
  [preferences registerInteger:&_URLLeftSwipeAction default:0 forKey:@"URLLeftSwipeAction"];
  [preferences registerBool:&_URLRightSwipeGestureEnabled default:NO forKey:@"URLRightSwipeGestureEnabled"];
  [preferences registerInteger:&_URLRightSwipeAction default:0 forKey:@"URLRightSwipeAction"];
  [preferences registerBool:&_URLDownSwipeGestureEnabled default:NO forKey:@"URLDownSwipeGestureEnabled"];
  [preferences registerInteger:&_URLDownSwipeAction default:0 forKey:@"URLDownSwipeAction"];
  [preferences registerBool:&_gestureBackground default:NO forKey:@"gestureBackground"];

  [preferences registerBool:&_openInNewTabOptionEnabled default:NO forKey:@"openInNewTabOptionEnabled"];
  [preferences registerBool:&_desktopButtonEnabled default:NO forKey:@"desktopButtonEnabled"];
  [preferences registerBool:&_longPressSuggestionsEnabled default:NO forKey:@"longPressSuggestionsEnabled"];

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

  return self;
}

@end

@implementation SPLocalizationManager

+ (instancetype)sharedInstance
{
  static SPLocalizationManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
      sharedInstance = [[SPLocalizationManager alloc] init];
  });
  return sharedInstance;
}

//Used to retrieve a localized string out of SafariPlus
- (NSString*)localizedSPStringForKey:(NSString*)key;
{
  NSString* localizedString = [SPBundle localizedStringForKey:key value:nil table:nil];
  if([localizedString isEqualToString:key])
  {
    //Handle missing localization
    NSDictionary *englishDict = [[NSDictionary alloc] initWithContentsOfFile:[SPBundle pathForResource:@"Localizable" ofType:@"strings" inDirectory:@"en.lproj"]];
    if([englishDict objectForKey:key])
    {
      localizedString = [englishDict objectForKey:key];
    }
  }
  return localizedString;
}

//Used to retrieve a localized string out of MobileSafari
- (NSString*)localizedMSStringForKey:(NSString*)key
{
  NSString* localizedString = [MSBundle localizedStringForKey:key value:key table:nil];
  return localizedString;
}

@end
