// SPPreferenceManager.h
// (c) 2018 opa334

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

@class SPPreferenceManager, HBPreferences;

static NSString *const SarafiPlusPrefsDomain = @"com.opa334.safariplusprefs";

@interface SPPreferenceManager : NSObject
{
  #if !defined(SIMJECT)
  HBPreferences* preferences;
  NSDictionary* colors;
  NSDictionary* otherPlist;
  NSMutableDictionary* miscPlist;
  #endif
}

+ (instancetype)sharedInstance;

@property(nonatomic, readonly) BOOL forceHTTPSEnabled;
- (NSArray*)forceHTTPSExceptions;
@property(nonatomic, readonly) BOOL openInOppositeModeOptionEnabled;
@property(nonatomic, readonly) BOOL openInNewTabOptionEnabled;
@property(nonatomic, readonly) BOOL uploadAnyFileOptionEnabled;
@property(nonatomic, readonly) BOOL desktopButtonEnabled;
@property(nonatomic, readonly) BOOL longPressSuggestionsEnabled;
@property(nonatomic, readonly) CGFloat longPressSuggestionsDuration;
@property(nonatomic, readonly) BOOL longPressSuggestionsFocusEnabled;

@property(nonatomic, readonly) BOOL enhancedDownloadsEnabled;
@property(nonatomic, readonly) BOOL videoDownloadingEnabled;
@property(nonatomic, readonly) BOOL downloadSiteToActionEnabled;
@property(nonatomic, readonly) BOOL downloadImageToActionEnabled;
@property(nonatomic, readonly) BOOL instantDownloadsEnabled;
@property(nonatomic, readonly) NSInteger instantDownloadsOption;
@property(nonatomic, readonly) BOOL customDefaultPathEnabled;
@property(nonatomic, readonly, retain) NSString* customDefaultPath;
@property(nonatomic, readonly) BOOL pinnedLocationsEnabled;
- (NSArray*)pinnedLocationNames;
- (NSArray*)pinnedLocationPaths;
@property(nonatomic, readonly) BOOL onlyDownloadOnWifiEnabled;
@property(nonatomic, readonly) BOOL disablePushNotificationsEnabled;
@property(nonatomic, readonly) BOOL disableBarNotificationsEnabled;

@property(nonatomic, readonly) BOOL forceModeOnStartEnabled;
@property(nonatomic, readonly) NSInteger forceModeOnStartFor;
@property(nonatomic, readonly) BOOL forceModeOnResumeEnabled;
@property(nonatomic, readonly) NSInteger forceModeOnResumeFor;
@property(nonatomic, readonly) BOOL forceModeOnExternalLinkEnabled;
@property(nonatomic, readonly) NSInteger forceModeOnExternalLinkFor;
@property(nonatomic, readonly) BOOL autoCloseTabsEnabled;
@property(nonatomic, readonly) NSInteger autoCloseTabsOn;
@property(nonatomic, readonly) NSInteger autoCloseTabsFor;
@property(nonatomic, readonly) BOOL autoDeleteDataEnabled;
@property(nonatomic, readonly) NSInteger autoDeleteDataOn;

@property(nonatomic, readonly) BOOL URLLeftSwipeGestureEnabled;
@property(nonatomic, readonly) NSInteger URLLeftSwipeAction;
@property(nonatomic, readonly) BOOL URLRightSwipeGestureEnabled;
@property(nonatomic, readonly) NSInteger URLRightSwipeAction;
@property(nonatomic, readonly) BOOL URLDownSwipeGestureEnabled;
@property(nonatomic, readonly) NSInteger URLDownSwipeAction;
@property(nonatomic, readonly) BOOL gestureBackground;

@property(nonatomic, readonly) BOOL fullscreenScrollingEnabled;
@property(nonatomic, readonly) BOOL lockBars;
@property(nonatomic, readonly) BOOL disablePrivateMode;
@property(nonatomic, readonly) BOOL alwaysOpenNewTabEnabled;
@property(nonatomic, readonly) BOOL alwaysOpenNewTabInBackgroundEnabled;
@property(nonatomic, readonly) BOOL suppressMailToDialog;

@property(nonatomic, readonly) BOOL topBarNormalTintColorEnabled;
- (UIColor*)topBarNormalTintColor;
@property(nonatomic, readonly) BOOL topBarNormalBackgroundColorEnabled;
- (UIColor*)topBarNormalBackgroundColor;
@property(nonatomic, readonly) BOOL topBarNormalTabBarTitleColorEnabled;
- (UIColor*)topBarNormalTabBarTitleColor;
@property(nonatomic, readonly) BOOL topBarNormalURLFontColorEnabled;
- (UIColor*)topBarNormalURLFontColor;
@property(nonatomic, readonly) BOOL topBarNormalProgressBarColorEnabled;
- (UIColor*)topBarNormalProgressBarColor;
@property(nonatomic, readonly) BOOL topBarNormalLockIconColorEnabled;
- (UIColor*)topBarNormalLockIconColor;
@property(nonatomic, readonly) BOOL topBarNormalReloadButtonColorEnabled;
- (UIColor*)topBarNormalReloadButtonColor;
@property(nonatomic, readonly) BOOL bottomBarNormalTintColorEnabled;
- (UIColor*)bottomBarNormalTintColor;
@property(nonatomic, readonly) BOOL bottomBarNormalBackgroundColorEnabled;
- (UIColor*)bottomBarNormalBackgroundColor;
@property(nonatomic, readonly) BOOL tabTitleBarNormalTextColorEnabled;
- (UIColor*)tabTitleBarNormalTextColor;
@property(nonatomic, readonly) BOOL tabTitleBarNormalBackgroundColorEnabled;
- (UIColor*)tabTitleBarNormalBackgroundColor;

@property(nonatomic, readonly) BOOL topBarPrivateTintColorEnabled;
- (UIColor*)topBarPrivateTintColor;
@property(nonatomic, readonly) BOOL topBarPrivateBackgroundColorEnabled;
- (UIColor*)topBarPrivateBackgroundColor;
@property(nonatomic, readonly) BOOL topBarPrivateTabBarTitleColorEnabled;
- (UIColor*)topBarPrivateTabBarTitleColor;
@property(nonatomic, readonly) BOOL topBarPrivateURLFontColorEnabled;
- (UIColor*)topBarPrivateURLFontColor;
@property(nonatomic, readonly) BOOL topBarPrivateProgressBarColorEnabled;
- (UIColor*)topBarPrivateProgressBarColor;
@property(nonatomic, readonly) BOOL topBarPrivateLockIconColorEnabled;
- (UIColor*)topBarPrivateLockIconColor;
@property(nonatomic, readonly) BOOL topBarPrivateReloadButtonColorEnabled;
- (UIColor*)topBarPrivateReloadButtonColor;
@property(nonatomic, readonly) BOOL bottomBarPrivateTintColorEnabled;
- (UIColor*)bottomBarPrivateTintColor;
@property(nonatomic, readonly) BOOL bottomBarPrivateBackgroundColorEnabled;
- (UIColor*)bottomBarPrivateBackgroundColor;
@property(nonatomic, readonly) BOOL tabTitleBarPrivateTextColorEnabled;
- (UIColor*)tabTitleBarPrivateTextColor;
@property(nonatomic, readonly) BOOL tabTitleBarPrivateBackgroundColorEnabled;
- (UIColor*)tabTitleBarPrivateBackgroundColor;

- (void)reloadColors;
- (void)reloadOtherPlist;

@end
