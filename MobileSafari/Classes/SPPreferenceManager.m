// SPPreferenceManager.m
// (c) 2017 opa334

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import "SPPreferenceManager.h"

#import "../Defines.h"
#import "../Shared.h"

#if !defined(SIMJECT)
#import <Cephei/HBPreferences.h>
#import "libcolorpicker.h"
#endif

void reloadOtherPlist()
{
  [preferenceManager reloadOtherPlist];
}

void reloadColors()
{
  [preferenceManager reloadColors];
}

@implementation SPPreferenceManager

+ (instancetype)sharedInstance
{
  static SPPreferenceManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken,
  ^{
    sharedInstance = [[SPPreferenceManager alloc] init];
  });
  return sharedInstance;
}

- (id)init
{
  self = [super init];

  #if defined(SIMJECT)

  //Simject preferences (No PreferenceLoader in Simulator)
  _forceHTTPSEnabled = YES;
  _openInOppositeModeOptionEnabled = YES;
  _openInNewTabOptionEnabled = NO;
  _uploadAnyFileOptionEnabled = YES;
  _desktopButtonEnabled = YES;
  _longPressSuggestionsEnabled = YES;
  _longPressSuggestionsDuration = 0.25;
  _longPressSuggestionsFocusEnabled = NO;

  _enhancedDownloadsEnabled = YES;
  _videoDownloadingEnabled = YES;
  _instantDownloadsEnabled = NO;
  _instantDownloadsOption = 0;
  _customDefaultPathEnabled = NO;
  _customDefaultPath = @"";
  _pinnedLocationsEnabled = YES;
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

  _fullscreenScrollingEnabled = YES;
  _disablePrivateMode = NO;
  _alwaysOpenNewTabEnabled = NO;
  _suppressMailToDialog = NO;

  _topBarNormalTintColorEnabled = NO;
  _topBarNormalBackgroundColorEnabled = NO;
  _topBarNormalURLFontColorEnabled = NO;
  _topBarNormalProgressBarColorEnabled = NO;
  _topBarNormalLockIconColorEnabled = NO;
  _topBarNormalReloadButtonColorEnabled = NO;
  _topBarNormalTabBarTitleColorEnabled = NO;
  _bottomBarNormalTintColorEnabled = NO;
  _bottomBarNormalBackgroundColorEnabled = NO;
  _tabTitleBarNormalTextColorEnabled = NO;
  _tabTitleBarNormalBackgroundColorEnabled = YES;

  _topBarPrivateTintColorEnabled = NO;
  _topBarPrivateBackgroundColorEnabled = NO;
  _topBarPrivateURLFontColorEnabled = NO;
  _topBarPrivateProgressBarColorEnabled = NO;
  _topBarPrivateLockIconColorEnabled = NO;
  _topBarPrivateReloadButtonColorEnabled = NO;
  _topBarPrivateTabBarTitleColorEnabled = NO;
  _bottomBarPrivateTintColorEnabled = NO;
  _bottomBarPrivateBackgroundColorEnabled = NO;
  _tabTitleBarPrivateTextColorEnabled = YES;
  _tabTitleBarPrivateBackgroundColorEnabled = NO;

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
  [preferences registerBool:&_videoDownloadingEnabled default:NO forKey:@"videoDownloadingEnabled"];
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

  [preferences registerBool:&_fullscreenScrollingEnabled default:NO forKey:@"fullscreenScrollingEnabled"];
  [preferences registerBool:&_lockBars default:NO forKey:@"lockBars"];
  [preferences registerBool:&_disablePrivateMode default:NO forKey:@"disablePrivateMode"];
  [preferences registerBool:&_alwaysOpenNewTabEnabled default:NO forKey:@"alwaysOpenNewTabEnabled"];
  [preferences registerBool:&_suppressMailToDialog default:NO forKey:@"suppressMailToDialog"];

  [preferences registerBool:&_topBarNormalTintColorEnabled default:NO forKey:@"topBarNormalTintColorEnabled"];
  [preferences registerBool:&_topBarNormalBackgroundColorEnabled default:NO forKey:@"topBarNormalBackgroundColorEnabled"];
  [preferences registerBool:&_topBarNormalTabBarTitleColorEnabled default:NO forKey:@"topBarNormalTabBarTitleColorEnabled"];
  [preferences registerBool:&_topBarNormalURLFontColorEnabled default:NO forKey:@"topBarNormalURLFontColorEnabled"];
  [preferences registerBool:&_topBarNormalProgressBarColorEnabled default:NO forKey:@"topBarNormalProgressBarColorEnabled"];
  [preferences registerBool:&_topBarNormalLockIconColorEnabled default:NO forKey:@"topBarNormalLockIconColorEnabled"];
  [preferences registerBool:&_topBarNormalReloadButtonColorEnabled default:NO forKey:@"topBarNormalReloadButtonColorEnabled"];
  [preferences registerBool:&_bottomBarNormalTintColorEnabled default:NO forKey:@"bottomBarNormalTintColorEnabled"];
  [preferences registerBool:&_bottomBarNormalBackgroundColorEnabled default:NO forKey:@"bottomBarNormalBackgroundColorEnabled"];
  [preferences registerBool:&_tabTitleBarNormalTextColorEnabled default:NO forKey:@"tabTitleBarNormalTextColorEnabled"];
  [preferences registerBool:&_tabTitleBarNormalBackgroundColorEnabled default:NO forKey:@"tabTitleBarNormalBackgroundColorEnabled"];

  [preferences registerBool:&_topBarPrivateTintColorEnabled default:NO forKey:@"topBarPrivateTintColorEnabled"];
  [preferences registerBool:&_topBarPrivateBackgroundColorEnabled default:NO forKey:@"topBarPrivateBackgroundColorEnabled"];
  [preferences registerBool:&_topBarPrivateTabBarTitleColorEnabled default:NO forKey:@"topBarPrivateTabBarTitleColorEnabled"];
  [preferences registerBool:&_topBarPrivateURLFontColorEnabled default:NO forKey:@"topBarPrivateURLFontColorEnabled"];
  [preferences registerBool:&_topBarPrivateProgressBarColorEnabled default:NO forKey:@"topBarPrivateProgressBarColorEnabled"];
  [preferences registerBool:&_topBarPrivateLockIconColorEnabled default:NO forKey:@"topBarPrivateLockIconColorEnabled"];
  [preferences registerBool:&_topBarPrivateReloadButtonColorEnabled default:NO forKey:@"topBarPrivateReloadButtonColorEnabled"];
  [preferences registerBool:&_bottomBarPrivateTintColorEnabled default:NO forKey:@"bottomBarPrivateTintColorEnabled"];
  [preferences registerBool:&_bottomBarPrivateBackgroundColorEnabled default:NO forKey:@"bottomBarPrivateBackgroundColorEnabled"];
  [preferences registerBool:&_tabTitleBarPrivateTextColorEnabled default:NO forKey:@"tabTitleBarPrivateTextColorEnabled"];
  [preferences registerBool:&_tabTitleBarPrivateBackgroundColorEnabled default:NO forKey:@"tabTitleBarPrivateBackgroundColorEnabled"];

  [self reloadColors];
  [self reloadOtherPlist];

  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadColors, CFSTR("com.opa334.safaripluscolorprefs/ReloadPrefs"), NULL, CFNotificationSuspensionBehaviorCoalesce);
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadOtherPlist, CFSTR("com.opa334.safariplusprefs/ReloadOtherPlist"), NULL, CFNotificationSuspensionBehaviorCoalesce);

  #endif

  return self;
}

#if defined(SIMJECT)

- (void)reloadOtherPlist {}
- (void)reloadColors {}

- (NSArray*)forceHTTPSExceptions
{
  return nil;
}

- (NSArray*)pinnedLocationNames
{
  return @[@"Dummy Name"];
}

- (NSArray*)pinnedLocationPaths
{
  return @[@"dummy/path"];
}

- (UIColor*)topBarNormalTintColor { return [UIColor redColor]; }
- (UIColor*)topBarNormalBackgroundColor { return [UIColor redColor]; }
- (UIColor*)topBarNormalURLFontColor { return [UIColor redColor]; }
- (UIColor*)topBarNormalProgressBarColor { return [UIColor redColor]; }
- (UIColor*)topBarNormalLockIconColor { return [UIColor redColor]; }
- (UIColor*)topBarNormalReloadButtonColor { return [UIColor redColor]; }
- (UIColor*)topBarNormalTabBarTitleColor { return [UIColor redColor]; }
- (UIColor*)bottomBarNormalTintColor { return [UIColor redColor]; }
- (UIColor*)bottomBarNormalBackgroundColor { return [UIColor redColor]; }
- (UIColor*)tabTitleBarNormalTextColor { return [UIColor redColor]; }
- (UIColor*)tabTitleBarNormalBackgroundColor { return [UIColor redColor]; }


- (UIColor*)topBarPrivateTintColor { return [UIColor redColor]; }
- (UIColor*)topBarPrivateBackgroundColor { return [UIColor redColor]; }
- (UIColor*)topBarPrivateURLFontColor { return [UIColor redColor]; }
- (UIColor*)topBarPrivateProgressBarColor { return [UIColor redColor]; }
- (UIColor*)topBarPrivateLockIconColor { return [UIColor redColor]; }
- (UIColor*)topBarPrivateReloadButtonColor { return [UIColor redColor]; }
- (UIColor*)topBarPrivateTabBarTitleColor { return [UIColor redColor]; }
- (UIColor*)bottomBarPrivateTintColor { return [UIColor redColor]; }
- (UIColor*)bottomBarPrivateBackgroundColor { return [UIColor redColor]; }
- (UIColor*)tabTitleBarPrivateTextColor { return [UIColor redColor]; }
- (UIColor*)tabTitleBarPrivateBackgroundColor { return [UIColor redColor]; }

#else

- (void)reloadOtherPlist
{
  otherPlist = [[NSDictionary alloc] initWithContentsOfFile:otherPlistPath];
}

- (void)reloadColors
{
  colors = [[NSDictionary alloc] initWithContentsOfFile:colorPrefsPath];
}

- (NSArray*)forceHTTPSExceptions
{
  return [otherPlist objectForKey:@"ForceHTTPSExceptions"];
}

- (NSArray*)pinnedLocationNames
{
  return [otherPlist objectForKey:@"PinnedLocationNames"];
}

- (NSArray*)pinnedLocationPaths
{
  return [otherPlist objectForKey:@"PinnedLocationPaths"];
}

- (UIColor*)topBarNormalTintColor
{
  return LCPParseColorString([colors objectForKey:@"topBarNormalTintColor"], @"#FFFFFF");
}

- (UIColor*)topBarNormalBackgroundColor
{
  return LCPParseColorString([colors objectForKey:@"topBarNormalBackgroundColor"], @"#FFFFFF");
}

- (UIColor*)topBarNormalURLFontColor
{
  return LCPParseColorString([colors objectForKey:@"topBarNormalURLFontColor"], @"#FFFFFF");
}

- (UIColor*)topBarNormalProgressBarColor
{
  return LCPParseColorString([colors objectForKey:@"topBarNormalProgressBarColor"], @"#FFFFFF");
}

- (UIColor*)topBarNormalLockIconColor
{
  return LCPParseColorString([colors objectForKey:@"topBarNormalLockIconColor"], @"#FFFFFF");
}

- (UIColor*)topBarNormalReloadButtonColor
{
  return LCPParseColorString([colors objectForKey:@"topBarNormalReloadButtonColor"], @"#FFFFFF");
}

- (UIColor*)topBarNormalTabBarTitleColor
{
  return LCPParseColorString([colors objectForKey:@"topBarNormalTabBarTitleColor"], @"#FFFFFF");
}

- (UIColor*)bottomBarNormalTintColor
{
  return LCPParseColorString([colors objectForKey:@"bottomBarNormalTintColor"], @"#FFFFFF");
}

- (UIColor*)bottomBarNormalBackgroundColor
{
  return LCPParseColorString([colors objectForKey:@"bottomBarNormalBackgroundColor"], @"#FFFFFF");
}

- (UIColor*)tabTitleBarNormalTextColor
{
  return LCPParseColorString([colors objectForKey:@"tabTitleBarNormalTextColor"], @"#FFFFFF");
}

- (UIColor*)tabTitleBarNormalBackgroundColor
{
  return LCPParseColorString([colors objectForKey:@"tabTitleBarNormalBackgroundColor"], @"#FFFFFF");
}


- (UIColor*)topBarPrivateTintColor
{
  return LCPParseColorString([colors objectForKey:@"topBarPrivateTintColor"], @"#FFFFFF");
}

- (UIColor*)topBarPrivateBackgroundColor
{
  return LCPParseColorString([colors objectForKey:@"topBarPrivateBackgroundColor"], @"#FFFFFF");
}

- (UIColor*)topBarPrivateURLFontColor
{
  return LCPParseColorString([colors objectForKey:@"topBarPrivateURLFontColor"], @"#FFFFFF");
}

- (UIColor*)topBarPrivateProgressBarColor
{
  return LCPParseColorString([colors objectForKey:@"topBarPrivateProgressBarColor"], @"#FFFFFF");
}

- (UIColor*)topBarPrivateLockIconColor
{
  return LCPParseColorString([colors objectForKey:@"topBarPrivateLockIconColor"], @"#FFFFFF");
}

- (UIColor*)topBarPrivateReloadButtonColor
{
  return LCPParseColorString([colors objectForKey:@"topBarPrivateReloadButtonColor"], @"#FFFFFF");
}

- (UIColor*)topBarPrivateTabBarTitleColor
{
  return LCPParseColorString([colors objectForKey:@"topBarPrivateTabBarTitleColor"], @"#FFFFFF");
}

- (UIColor*)bottomBarPrivateTintColor
{
  return LCPParseColorString([colors objectForKey:@"bottomBarPrivateTintColor"], @"#FFFFFF");
}

- (UIColor*)bottomBarPrivateBackgroundColor
{
  return LCPParseColorString([colors objectForKey:@"bottomBarPrivateBackgroundColor"], @"#FFFFFF");
}

- (UIColor*)tabTitleBarPrivateTextColor
{
  return LCPParseColorString([colors objectForKey:@"tabTitleBarPrivateTextColor"], @"#FFFFFF");
}

- (UIColor*)tabTitleBarPrivateBackgroundColor
{
  return LCPParseColorString([colors objectForKey:@"tabTitleBarPrivateBackgroundColor"], @"#FFFFFF");
}

#endif

@end
