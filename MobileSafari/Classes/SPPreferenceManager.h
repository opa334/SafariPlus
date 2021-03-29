// Copyright (c) 2017-2020 Lars Fröder

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

@class SPPreferenceManager, HBPreferences;

@interface SPPreferenceManager : NSObject
{
  #ifndef NO_CEPHEI
	HBPreferences* _preferences;
  #endif
  NSDictionary* _defaults;
}

+ (instancetype)sharedInstance;

- (void)reloadPreferences;
- (void)reloadPreferencesFromDictionary:(NSDictionary*)prefDict;

@property (nonatomic, readonly) BOOL tweakEnabled;

@property (nonatomic, readonly) BOOL forceHTTPSEnabled;
@property (nonatomic, readonly) NSArray* forceHTTPSExceptions;
- (BOOL)isURLOnHTTPSExceptionsList:(NSURL*)URL;
- (void)addURLToHTTPSExceptionsList:(NSURL*)URL;
- (void)removeURLFromHTTPSExceptionsList:(NSURL*)URL;
@property (nonatomic, readonly) BOOL lockedTabsEnabled;
@property (nonatomic, readonly) BOOL biometricProtectionEnabled;
@property (nonatomic, readonly) BOOL biometricProtectionSwitchModeEnabled;
@property (nonatomic, readonly) BOOL biometricProtectionSwitchModeAllowAutomaticActionsEnabled;
@property (nonatomic, readonly) BOOL biometricProtectionLockTabEnabled;
@property (nonatomic, readonly) BOOL biometricProtectionUnlockTabEnabled;
@property (nonatomic, readonly) BOOL biometricProtectionAccessLockedTabEnabled;
@property (nonatomic, readonly) BOOL biometricProtectionOpenDownloadsEnabled;

@property (nonatomic, readonly) BOOL uploadAnyFileOptionEnabled;
@property (nonatomic, readonly) BOOL downloadManagerEnabled;
@property (nonatomic, readonly) BOOL videoDownloadingEnabled;
@property (nonatomic, readonly) BOOL videoDownloadingUseTabTitleAsFilenameEnabled;
@property (nonatomic, readonly) BOOL downloadSiteToActionEnabled;
@property (nonatomic, readonly) BOOL downloadImageToActionEnabled;
@property (nonatomic, readonly) BOOL customDefaultPathEnabled;
@property (nonatomic, readonly, retain) NSString* customDefaultPath;
@property (nonatomic, readonly) BOOL pinnedLocationsEnabled;
@property (nonatomic, readonly) NSArray* pinnedLocations;
@property (nonatomic, readonly) BOOL previewDownloadProgressEnabled;
@property (nonatomic, readonly) NSInteger defaultDownloadSection;
@property (nonatomic, readonly) BOOL defaultDownloadSectionAutoSwitchEnabled;
@property (nonatomic, readonly) BOOL instantDownloadsEnabled;
@property (nonatomic, readonly) NSInteger instantDownloadsOption;
@property (nonatomic, readonly) BOOL onlyDownloadOnWifiEnabled;
@property (nonatomic, readonly) BOOL autosaveToMediaLibraryEnabled;
@property (nonatomic, readonly) BOOL privateModeDownloadHistoryDisabled;
@property (nonatomic, readonly) BOOL pushNotificationsEnabled;
@property (nonatomic, readonly) BOOL statusBarNotificationsEnabled;
@property (nonatomic, readonly) BOOL applicationBadgeEnabled;

@property (nonatomic, readonly) BOOL bothTabOpenActionsEnabled;
@property (nonatomic, readonly) BOOL openInOppositeModeOptionEnabled;
@property (nonatomic, readonly) BOOL desktopButtonEnabled;
@property (nonatomic, readonly) BOOL tabManagerEnabled;
@property (nonatomic, readonly) BOOL tabManagerScrollPositionFromTabSwitcherEnabled;
@property (nonatomic, readonly) BOOL disableTabLimit;
@property (nonatomic, readonly) BOOL customStartSiteEnabled;
@property (nonatomic, readonly) NSString* customStartSite;
@property (nonatomic, readonly) BOOL alwaysOpenNewTabEnabled;
@property (nonatomic, readonly) BOOL alwaysOpenNewTabInBackgroundEnabled;
@property (nonatomic, readonly) BOOL disableTabSwiping;
@property (nonatomic, readonly) BOOL disablePrivateMode;
@property (nonatomic, readonly) BOOL longPressSuggestionsEnabled;
@property (nonatomic, readonly) CGFloat longPressSuggestionsDuration;
@property (nonatomic, readonly) BOOL longPressSuggestionsFocusEnabled;
@property (nonatomic, readonly) BOOL suggestionInsertButtonEnabled;
@property (nonatomic, readonly) BOOL showTabCountEnabled;
@property (nonatomic, readonly) BOOL fullscreenScrollingEnabled;
@property (nonatomic, readonly) BOOL lockBars;
@property (nonatomic, readonly) BOOL showFullSiteURLEnabled;
@property (nonatomic, readonly) BOOL forceNativePlayerEnabled;
@property (nonatomic, readonly) BOOL suppressMailToDialog;

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
@property (nonatomic, readonly) BOOL toolbarLeftSwipeGestureEnabled;
@property (nonatomic, readonly) NSInteger toolbarLeftSwipeAction;
@property (nonatomic, readonly) BOOL toolbarRightSwipeGestureEnabled;
@property (nonatomic, readonly) NSInteger toolbarRightSwipeAction;
@property (nonatomic, readonly) BOOL toolbarUpDownSwipeGestureEnabled;
@property (nonatomic, readonly) NSInteger toolbarUpDownSwipeAction;
@property (nonatomic, readonly) BOOL gesturesInTabSwitcherEnabled;
@property (nonatomic, readonly) BOOL gestureActionsInBackgroundEnabled;

//IOS 12 AND DOWN

@property (nonatomic, readonly) BOOL topBarNormalTintColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalTintColor;
@property (nonatomic, readonly) BOOL topBarNormalBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalBackgroundColor;
@property (nonatomic, readonly) BOOL topBarNormalStatusBarStyleEnabled;
@property (nonatomic, readonly) UIStatusBarStyle topBarNormalStatusBarStyle;
@property (nonatomic, readonly) BOOL topBarNormalReaderButtonColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalReaderButtonColor;
@property (nonatomic, readonly) BOOL topBarNormalLockIconColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalLockIconColor;
@property (nonatomic, readonly) BOOL topBarNormalURLFontColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalURLFontColor;
@property (nonatomic, readonly) BOOL topBarNormalReloadButtonColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalReloadButtonColor;
@property (nonatomic, readonly) BOOL topBarNormalProgressBarColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalProgressBarColor;
@property (nonatomic, readonly) BOOL topBarNormalTabBarCloseButtonColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalTabBarCloseButtonColor;
@property (nonatomic, readonly) BOOL topBarNormalTabBarTitleColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalTabBarTitleColor;
@property (nonatomic, readonly) CGFloat topBarNormalTabBarInactiveTitleOpacity;
@property (nonatomic, readonly) BOOL bottomBarNormalTintColorEnabled;
@property (nonatomic, readonly) NSString* bottomBarNormalTintColor;
@property (nonatomic, readonly) BOOL bottomBarNormalBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* bottomBarNormalBackgroundColor;
@property (nonatomic, readonly) BOOL tabTitleBarNormalTextColorEnabled;
@property (nonatomic, readonly) NSString* tabTitleBarNormalTextColor;
@property (nonatomic, readonly) BOOL tabTitleBarNormalBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* tabTitleBarNormalBackgroundColor;
@property (nonatomic, readonly) BOOL tabSwitcherNormalToolbarBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* tabSwitcherNormalToolbarBackgroundColor;

@property (nonatomic, readonly) BOOL topBarPrivateTintColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateTintColor;
@property (nonatomic, readonly) BOOL topBarPrivateBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateBackgroundColor;
@property (nonatomic, readonly) BOOL topBarPrivateStatusBarStyleEnabled;
@property (nonatomic, readonly) UIStatusBarStyle topBarPrivateStatusBarStyle;
@property (nonatomic, readonly) BOOL topBarPrivateReaderButtonColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateReaderButtonColor;
@property (nonatomic, readonly) BOOL topBarPrivateLockIconColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateLockIconColor;
@property (nonatomic, readonly) BOOL topBarPrivateURLFontColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateURLFontColor;
@property (nonatomic, readonly) BOOL topBarPrivateReloadButtonColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateReloadButtonColor;
@property (nonatomic, readonly) BOOL topBarPrivateProgressBarColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateProgressBarColor;
@property (nonatomic, readonly) BOOL topBarPrivateTabBarCloseButtonColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateTabBarCloseButtonColor;
@property (nonatomic, readonly) BOOL topBarPrivateTabBarTitleColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateTabBarTitleColor;
@property (nonatomic, readonly) CGFloat topBarPrivateTabBarInactiveTitleOpacity;
@property (nonatomic, readonly) BOOL bottomBarPrivateTintColorEnabled;
@property (nonatomic, readonly) NSString* bottomBarPrivateTintColor;
@property (nonatomic, readonly) BOOL bottomBarPrivateBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* bottomBarPrivateBackgroundColor;
@property (nonatomic, readonly) BOOL tabTitleBarPrivateTextColorEnabled;
@property (nonatomic, readonly) NSString* tabTitleBarPrivateTextColor;
@property (nonatomic, readonly) BOOL tabTitleBarPrivateBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* tabTitleBarPrivateBackgroundColor;
@property (nonatomic, readonly) BOOL tabSwitcherPrivateToolbarBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* tabSwitcherPrivateToolbarBackgroundColor;

//IOS 13 AND UP

@property (nonatomic, readonly) BOOL topBarNormalLightTintColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalLightTintColor;
@property (nonatomic, readonly) BOOL topBarNormalLightBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalLightBackgroundColor;
@property (nonatomic, readonly) BOOL topBarNormalLightStatusBarStyleEnabled;
@property (nonatomic, readonly) UIStatusBarStyle topBarNormalLightStatusBarStyle;
@property (nonatomic, readonly) BOOL topBarNormalLightURLFontColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalLightURLFontColor;
@property (nonatomic, readonly) BOOL topBarNormalLightProgressBarColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalLightProgressBarColor;
@property (nonatomic, readonly) BOOL topBarNormalLightTabBarCloseButtonColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalLightTabBarCloseButtonColor;
@property (nonatomic, readonly) BOOL topBarNormalLightTabBarTitleColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalLightTabBarTitleColor;
@property (nonatomic, readonly) CGFloat topBarNormalLightTabBarInactiveTitleOpacity;
@property (nonatomic, readonly) BOOL bottomBarNormalLightTintColorEnabled;
@property (nonatomic, readonly) NSString* bottomBarNormalLightTintColor;
@property (nonatomic, readonly) BOOL bottomBarNormalLightBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* bottomBarNormalLightBackgroundColor;
@property (nonatomic, readonly) BOOL tabTitleBarNormalLightTextColorEnabled;
@property (nonatomic, readonly) NSString* tabTitleBarNormalLightTextColor;
@property (nonatomic, readonly) BOOL tabTitleBarNormalLightBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* tabTitleBarNormalLightBackgroundColor;
@property (nonatomic, readonly) BOOL tabSwitcherNormalLightToolbarBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* tabSwitcherNormalLightToolbarBackgroundColor;

@property (nonatomic, readonly) BOOL topBarNormalDarkTintColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalDarkTintColor;
@property (nonatomic, readonly) BOOL topBarNormalDarkBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalDarkBackgroundColor;
@property (nonatomic, readonly) BOOL topBarNormalDarkStatusBarStyleEnabled;
@property (nonatomic, readonly) UIStatusBarStyle topBarNormalDarkStatusBarStyle;
@property (nonatomic, readonly) BOOL topBarNormalDarkURLFontColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalDarkURLFontColor;
@property (nonatomic, readonly) BOOL topBarNormalDarkProgressBarColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalDarkProgressBarColor;
@property (nonatomic, readonly) BOOL topBarNormalDarkTabBarCloseButtonColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalDarkTabBarCloseButtonColor;
@property (nonatomic, readonly) BOOL topBarNormalDarkTabBarTitleColorEnabled;
@property (nonatomic, readonly) NSString* topBarNormalDarkTabBarTitleColor;
@property (nonatomic, readonly) CGFloat topBarNormalDarkTabBarInactiveTitleOpacity;
@property (nonatomic, readonly) BOOL bottomBarNormalDarkTintColorEnabled;
@property (nonatomic, readonly) NSString* bottomBarNormalDarkTintColor;
@property (nonatomic, readonly) BOOL bottomBarNormalDarkBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* bottomBarNormalDarkBackgroundColor;
@property (nonatomic, readonly) BOOL tabTitleBarNormalDarkTextColorEnabled;
@property (nonatomic, readonly) NSString* tabTitleBarNormalDarkTextColor;
@property (nonatomic, readonly) BOOL tabTitleBarNormalDarkBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* tabTitleBarNormalDarkBackgroundColor;
@property (nonatomic, readonly) BOOL tabSwitcherNormalDarkToolbarBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* tabSwitcherNormalDarkToolbarBackgroundColor;

@property (nonatomic, readonly) BOOL topBarPrivateLightTintColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateLightTintColor;
@property (nonatomic, readonly) BOOL topBarPrivateLightBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateLightBackgroundColor;
@property (nonatomic, readonly) BOOL topBarPrivateLightStatusBarStyleEnabled;
@property (nonatomic, readonly) UIStatusBarStyle topBarPrivateLightStatusBarStyle;
@property (nonatomic, readonly) BOOL topBarPrivateLightURLFontColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateLightURLFontColor;
@property (nonatomic, readonly) BOOL topBarPrivateLightProgressBarColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateLightProgressBarColor;
@property (nonatomic, readonly) BOOL topBarPrivateLightTabBarCloseButtonColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateLightTabBarCloseButtonColor;
@property (nonatomic, readonly) BOOL topBarPrivateLightTabBarTitleColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateLightTabBarTitleColor;
@property (nonatomic, readonly) CGFloat topBarPrivateLightTabBarInactiveTitleOpacity;
@property (nonatomic, readonly) BOOL bottomBarPrivateLightTintColorEnabled;
@property (nonatomic, readonly) NSString* bottomBarPrivateLightTintColor;
@property (nonatomic, readonly) BOOL bottomBarPrivateLightBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* bottomBarPrivateLightBackgroundColor;
@property (nonatomic, readonly) BOOL tabTitleBarPrivateLightTextColorEnabled;
@property (nonatomic, readonly) NSString* tabTitleBarPrivateLightTextColor;
@property (nonatomic, readonly) BOOL tabTitleBarPrivateLightBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* tabTitleBarPrivateLightBackgroundColor;
@property (nonatomic, readonly) BOOL tabSwitcherPrivateLightToolbarBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* tabSwitcherPrivateLightToolbarBackgroundColor;

@property (nonatomic, readonly) BOOL topBarPrivateDarkTintColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateDarkTintColor;
@property (nonatomic, readonly) BOOL topBarPrivateDarkBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateDarkBackgroundColor;
@property (nonatomic, readonly) BOOL topBarPrivateDarkStatusBarStyleEnabled;
@property (nonatomic, readonly) UIStatusBarStyle topBarPrivateDarkStatusBarStyle;
@property (nonatomic, readonly) BOOL topBarPrivateDarkURLFontColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateDarkURLFontColor;
@property (nonatomic, readonly) BOOL topBarPrivateDarkProgressBarColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateDarkProgressBarColor;
@property (nonatomic, readonly) BOOL topBarPrivateDarkTabBarCloseButtonColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateDarkTabBarCloseButtonColor;
@property (nonatomic, readonly) BOOL topBarPrivateDarkTabBarTitleColorEnabled;
@property (nonatomic, readonly) NSString* topBarPrivateDarkTabBarTitleColor;
@property (nonatomic, readonly) CGFloat topBarPrivateDarkTabBarInactiveTitleOpacity;
@property (nonatomic, readonly) BOOL bottomBarPrivateDarkTintColorEnabled;
@property (nonatomic, readonly) NSString* bottomBarPrivateDarkTintColor;
@property (nonatomic, readonly) BOOL bottomBarPrivateDarkBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* bottomBarPrivateDarkBackgroundColor;
@property (nonatomic, readonly) BOOL tabTitleBarPrivateDarkTextColorEnabled;
@property (nonatomic, readonly) NSString* tabTitleBarPrivateDarkTextColor;
@property (nonatomic, readonly) BOOL tabTitleBarPrivateDarkBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* tabTitleBarPrivateDarkBackgroundColor;
@property (nonatomic, readonly) BOOL tabSwitcherPrivateDarkToolbarBackgroundColorEnabled;
@property (nonatomic, readonly) NSString* tabSwitcherPrivateDarkToolbarBackgroundColor;

@property (nonatomic, readonly) BOOL topToolbarCustomOrderEnabled;
@property (nonatomic, readonly) NSArray<NSNumber*>* topToolbarCustomOrder;
@property (nonatomic, readonly) BOOL bottomToolbarCustomOrderEnabled;
@property (nonatomic, readonly) NSArray<NSNumber*>* bottomToolbarCustomOrder;
@property (nonatomic, readonly) BOOL customUserAgentEnabled;
@property (nonatomic, readonly) NSString* customUserAgent;
@property (nonatomic, readonly) BOOL customDesktopUserAgentEnabled;
@property (nonatomic, readonly) NSString* customDesktopUserAgent;
@property (nonatomic, readonly) BOOL customSearchEngineEnabled;
@property (nonatomic, readonly) NSString* customSearchEngineName;
@property (nonatomic, readonly) NSString* customSearchEngineURL;
@property (nonatomic, readonly) NSString* customSearchEngineSuggestionsURL;

@property (nonatomic, readonly) BOOL largeTitlesEnabled;
@property (nonatomic, readonly) BOOL sortDirectoriesAboveFiles;
@property (nonatomic, readonly) BOOL pullUpToRefreshDisabled;
@property (nonatomic, readonly) BOOL communicationErrorDisabled;

#ifndef NO_CEPHEI
- (HBPreferences*)preferences;
@property (nonatomic, readonly) BOOL preferencesAreValid;
- (void)fallbackToPlistDictionary;
#endif

@end
