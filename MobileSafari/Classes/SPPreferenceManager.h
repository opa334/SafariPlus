// SPPreferenceManager.h
// (c) 2019 opa334

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
  #ifndef NO_CEPHEI
	HBPreferences* preferences;
  #else
	NSDictionary* userDefaults;
  #endif

  #ifndef NO_LIBCOLORPICKER
	NSDictionary* colors;
  #endif

	NSDictionary* otherPlist;
}

+ (instancetype)sharedInstance;

@property (nonatomic, readonly) BOOL forceHTTPSEnabled;
- (NSArray*)forceHTTPSExceptions;
- (BOOL)isURLOnHTTPSExceptionsList:(NSURL*)URL;
@property (nonatomic, readonly) BOOL openInOppositeModeOptionEnabled;
@property (nonatomic, readonly) BOOL openInNewTabOptionEnabled;
@property (nonatomic, readonly) BOOL uploadAnyFileOptionEnabled;
@property (nonatomic, readonly) BOOL desktopButtonEnabled;
@property (nonatomic, readonly) BOOL longPressSuggestionsEnabled;
@property (nonatomic, readonly) CGFloat longPressSuggestionsDuration;
@property (nonatomic, readonly) BOOL longPressSuggestionsFocusEnabled;

@property (nonatomic, readonly) BOOL enhancedDownloadsEnabled;
@property (nonatomic, readonly) BOOL videoDownloadingEnabled;
@property (nonatomic, readonly) NSInteger defaultDownloadSection;
@property (nonatomic, readonly) BOOL defaultDownloadSectionAutoSwitchEnabled;
@property (nonatomic, readonly) BOOL downloadSiteToActionEnabled;
@property (nonatomic, readonly) BOOL downloadImageToActionEnabled;
@property (nonatomic, readonly) BOOL instantDownloadsEnabled;
@property (nonatomic, readonly) NSInteger instantDownloadsOption;
@property (nonatomic, readonly) BOOL customDefaultPathEnabled;
@property (nonatomic, readonly, retain) NSString* customDefaultPath;
@property (nonatomic, readonly) BOOL pinnedLocationsEnabled;
- (NSArray*)pinnedLocationNames;
- (NSArray*)pinnedLocationPaths;
@property (nonatomic, readonly) BOOL onlyDownloadOnWifiEnabled;
@property (nonatomic, readonly) BOOL disablePushNotificationsEnabled;
@property (nonatomic, readonly) BOOL disableBarNotificationsEnabled;

@property (nonatomic, readonly) BOOL forceModeOnStartEnabled;
@property (nonatomic, readonly) NSInteger forceModeOnStartFor;
@property (nonatomic, readonly) BOOL forceModeOnResumeEnabled;
@property (nonatomic, readonly) NSInteger forceModeOnResumeFor;
@property (nonatomic, readonly) BOOL forceModeOnExternalLinkEnabled;
@property (nonatomic, readonly) NSInteger forceModeOnExternalLinkFor;
@property (nonatomic, readonly) BOOL autoCloseTabsEnabled;
@property (nonatomic, readonly) NSInteger autoCloseTabsOn;
@property (nonatomic, readonly) NSInteger autoCloseTabsFor;
@property (nonatomic, readonly) BOOL autoDeleteDataEnabled;
@property (nonatomic, readonly) NSInteger autoDeleteDataOn;

@property (nonatomic, readonly) BOOL URLLeftSwipeGestureEnabled;
@property (nonatomic, readonly) NSInteger URLLeftSwipeAction;
@property (nonatomic, readonly) BOOL URLRightSwipeGestureEnabled;
@property (nonatomic, readonly) NSInteger URLRightSwipeAction;
@property (nonatomic, readonly) BOOL URLDownSwipeGestureEnabled;
@property (nonatomic, readonly) NSInteger URLDownSwipeAction;
@property (nonatomic, readonly) BOOL gestureBackground;

@property (nonatomic, readonly) BOOL fullscreenScrollingEnabled;
@property (nonatomic, readonly) BOOL removeTabLimit;
@property (nonatomic, readonly) BOOL lockBars;
@property (nonatomic, readonly) BOOL disablePrivateMode;
@property (nonatomic, readonly) BOOL alwaysOpenNewTabEnabled;
@property (nonatomic, readonly) BOOL alwaysOpenNewTabInBackgroundEnabled;
@property (nonatomic, readonly) BOOL suppressMailToDialog;
@property (nonatomic, readonly) BOOL communicationErrorDisabled;

@property (nonatomic, readonly) BOOL topBarNormalTintColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalTintColor;
@property (nonatomic, readonly) BOOL topBarNormalBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalBackgroundColor;
@property (nonatomic, readonly) BOOL topBarNormalStatusBarStyleEnabled;
@property (nonatomic, readonly) UIStatusBarStyle topBarNormalStatusBarStyle;
@property (nonatomic, readonly) BOOL topBarNormalTabBarTitleColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalTabBarTitleColor;
@property (nonatomic, readonly) CGFloat topBarNormalTabBarInactiveTitleOpacity;
@property (nonatomic, readonly) BOOL topBarNormalURLFontColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalURLFontColor;
@property (nonatomic, readonly) BOOL topBarNormalProgressBarColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalProgressBarColor;
@property (nonatomic, readonly) BOOL topBarNormalLockIconColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalLockIconColor;
@property (nonatomic, readonly) BOOL topBarNormalReloadButtonColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalReloadButtonColor;
@property (nonatomic, readonly) BOOL bottomBarNormalTintColorEnabled;
@property (nonatomic, readonly) NSString* bottomBarNormalTintColor;
@property (nonatomic, readonly) BOOL bottomBarNormalBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* bottomBarNormalBackgroundColor;
@property (nonatomic, readonly) BOOL tabTitleBarNormalTextColorEnabled;
@property (nonatomic, readonly) NSString* tabTitleBarNormalTextColor;
@property (nonatomic, readonly) BOOL tabTitleBarNormalBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* tabTitleBarNormalBackgroundColor;

@property (nonatomic, readonly) BOOL topBarPrivateTintColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateTintColor;
@property (nonatomic, readonly) BOOL topBarPrivateBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateBackgroundColor;
@property (nonatomic, readonly) BOOL topBarPrivateStatusBarStyleEnabled;
@property (nonatomic, readonly) UIStatusBarStyle topBarPrivateStatusBarStyle;
@property (nonatomic, readonly) BOOL topBarPrivateTabBarTitleColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateTabBarTitleColor;
@property (nonatomic, readonly) CGFloat topBarPrivateTabBarInactiveTitleOpacity;
@property (nonatomic, readonly) BOOL topBarPrivateURLFontColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateURLFontColor;
@property (nonatomic, readonly) BOOL topBarPrivateProgressBarColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateProgressBarColor;
@property (nonatomic, readonly) BOOL topBarPrivateLockIconColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateLockIconColor;
@property (nonatomic, readonly) BOOL topBarPrivateReloadButtonColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateReloadButtonColor;
@property (nonatomic, readonly) BOOL bottomBarPrivateTintColorEnabled;
@property (nonatomic, readonly) NSString* bottomBarPrivateTintColor;
@property (nonatomic, readonly) BOOL bottomBarPrivateBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* bottomBarPrivateBackgroundColor;
@property (nonatomic, readonly) BOOL tabTitleBarPrivateTextColorEnabled;
@property (nonatomic, readonly) NSString* tabTitleBarPrivateTextColor;
@property (nonatomic, readonly) BOOL tabTitleBarPrivateBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* tabTitleBarPrivateBackgroundColor;

- (void)reloadOtherPlist;
#ifdef NO_CEPHEI
- (void)reloadPrefs;
#endif

@end
