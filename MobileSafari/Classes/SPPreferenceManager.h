// SPPreferenceManager.h
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

@class SPPreferenceManager, HBPreferences;

static NSString *const SarafiPlusPrefsDomain = @"com.opa334.safariplusprefs";

@interface SPPreferenceManager : NSObject
{
  #if !defined(SIMJECT) && !defined(ELECTRA)
  HBPreferences *preferences;
  #endif

  #ifdef ELECTRA
  NSDictionary *userDefaults;
  #endif
}

@property(nonatomic, readonly) BOOL forceHTTPSEnabled;
@property(nonatomic, readonly) BOOL openInOppositeModeOptionEnabled;
@property(nonatomic, readonly) BOOL openInNewTabOptionEnabled;
@property(nonatomic, readonly) BOOL uploadAnyFileOptionEnabled;
@property(nonatomic, readonly) BOOL desktopButtonEnabled;
@property(nonatomic, readonly) BOOL longPressSuggestionsEnabled;
@property(nonatomic, readonly) CGFloat longPressSuggestionsDuration;
@property(nonatomic, readonly) BOOL longPressSuggestionsFocusEnabled;

@property(nonatomic, readonly) BOOL enhancedDownloadsEnabled;
@property(nonatomic, readonly) BOOL videoDownloadingEnabled;
@property(nonatomic, readonly) BOOL instantDownloadsEnabled;
@property(nonatomic, readonly) NSInteger instantDownloadsOption;
@property(nonatomic, readonly) BOOL customDefaultPathEnabled;
@property(nonatomic, readonly, retain) NSString* customDefaultPath;
@property(nonatomic, readonly) BOOL pinnedLocationsEnabled;
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
@property(nonatomic, readonly) BOOL suppressMailToDialog;

@property(nonatomic, readonly) BOOL appTintColorNormalEnabled;
@property(nonatomic, readonly,retain) NSString* appTintColorNormal;
@property(nonatomic, readonly) BOOL topBarColorNormalEnabled;
@property(nonatomic, readonly,retain) NSString* topBarColorNormal;
@property(nonatomic, readonly) BOOL URLFontColorNormalEnabled;
@property(nonatomic, readonly,retain) NSString* URLFontColorNormal;
@property(nonatomic, readonly) BOOL progressBarColorNormalEnabled;
@property(nonatomic, readonly,retain) NSString* progressBarColorNormal;
@property(nonatomic, readonly) BOOL tabTitleColorNormalEnabled;
@property(nonatomic, readonly,retain) NSString* tabTitleColorNormal;
@property(nonatomic, readonly) BOOL reloadColorNormalEnabled;
@property(nonatomic, readonly,retain) NSString* reloadColorNormal;
@property(nonatomic, readonly) BOOL lockIconColorNormalEnabled;
@property(nonatomic, readonly,retain) NSString* lockIconColorNormal;
@property(nonatomic, readonly) BOOL bottomBarColorNormalEnabled;
@property(nonatomic, readonly,retain) NSString* bottomBarColorNormal;

@property(nonatomic, readonly) BOOL appTintColorPrivateEnabled;
@property(nonatomic, readonly,retain) NSString* appTintColorPrivate;
@property(nonatomic, readonly) BOOL topBarColorPrivateEnabled;
@property(nonatomic, readonly,retain) NSString* topBarColorPrivate;
@property(nonatomic, readonly) BOOL URLFontColorPrivateEnabled;
@property(nonatomic, readonly,retain) NSString* URLFontColorPrivate;
@property(nonatomic, readonly) BOOL progressBarColorPrivateEnabled;
@property(nonatomic, readonly,retain) NSString* progressBarColorPrivate;
@property(nonatomic, readonly) BOOL tabTitleColorPrivateEnabled;
@property(nonatomic, readonly,retain) NSString* tabTitleColorPrivate;
@property(nonatomic, readonly) BOOL reloadColorPrivateEnabled;
@property(nonatomic, readonly,retain) NSString* reloadColorPrivate;
@property(nonatomic, readonly) BOOL lockIconColorPrivateEnabled;
@property(nonatomic, readonly,retain) NSString* lockIconColorPrivate;
@property(nonatomic, readonly) BOOL bottomBarColorPrivateEnabled;
@property(nonatomic, readonly,retain) NSString* bottomBarColorPrivate;

+ (instancetype)sharedInstance;

@end

#ifdef ELECTRA

@interface NSUserDefaults (Private)

- (instancetype)_initWithSuiteName:(NSString *)suiteName container:(NSURL *)container;

@end

#endif
