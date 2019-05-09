// SPPreferenceManager.mm
// (c) 2017 - 2019 opa334

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
#import "../Util.h"
#import "../Enums.h"
#import "Simulator.h"

#ifndef NO_CEPHEI
#import <Cephei/HBPreferences.h>
#endif
#ifndef NO_LIBCSCOLORPICKER
#import <CSColorPicker/CSColorPicker.h>
#endif

#ifdef NO_CEPHEI

void reloadPrefs()
{
	[preferenceManager reloadPrefs];
}

#endif

@implementation SPPreferenceManager

+ (instancetype)sharedInstance
{
	static SPPreferenceManager *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^
	{
		sharedInstance = [[SPPreferenceManager alloc] init];
	});
	return sharedInstance;
}

- (id)init
{
	self = [super init];

  #if defined(NO_CEPHEI)

	[self reloadPrefs];

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadPrefs, CFSTR("com.opa334.safariplusprefs/ReloadPrefs"), NULL, CFNotificationSuspensionBehaviorCoalesce);

	#else

	_preferences = [[HBPreferences alloc] initWithIdentifier:SPPrefsDomain];

	[_preferences registerBool:&_tweakEnabled default:YES forKey:@"tweakEnabled"];

	[_preferences registerBool:&_forceHTTPSEnabled default:NO forKey:@"forceHTTPSEnabled"];
	[_preferences registerObject:&_forceHTTPSExceptions default:nil forKey:@"forceHTTPSExceptions"];
	[_preferences registerBool:&_lockedTabsEnabled default:NO forKey:@"lockedTabsEnabled"];
	[_preferences registerBool:&_biometricProtectionEnabled default:NO forKey:@"biometricProtectionEnabled"];
	[_preferences registerBool:&_biometricProtectionSwitchModeEnabled default:NO forKey:@"biometricProtectionSwitchModeEnabled"];
	[_preferences registerBool:&_biometricProtectionOpenTabEnabled default:NO forKey:@"biometricProtectionOpenTabEnabled"];
	[_preferences registerBool:&_biometricProtectionCloseTabEnabled default:NO forKey:@"biometricProtectionCloseTabEnabled"];
	[_preferences registerBool:&_biometricProtectionLockTabEnabled default:NO forKey:@"biometricProtectionLockTabEnabled"];
	[_preferences registerBool:&_biometricProtectionUnlockTabEnabled default:NO forKey:@"biometricProtectionUnlockTabEnabled"];
	[_preferences registerBool:&_biometricProtectionAccessLockedTabEnabled default:NO forKey:@"biometricProtectionAccessLockedTabEnabled"];

	[_preferences registerBool:&_uploadAnyFileOptionEnabled default:NO forKey:@"uploadAnyFileOptionEnabled"];
	[_preferences registerBool:&_enhancedDownloadsEnabled default:NO forKey:@"enhancedDownloadsEnabled"];
	[_preferences registerBool:&_videoDownloadingEnabled default:NO forKey:@"videoDownloadingEnabled"];
	[_preferences registerInteger:&_defaultDownloadSection default:0 forKey:@"defaultDownloadSection"];
	[_preferences registerBool:&_defaultDownloadSectionAutoSwitchEnabled default:NO forKey:@"defaultDownloadSectionAutoSwitchEnabled"];
	[_preferences registerBool:&_downloadSiteToActionEnabled default:YES forKey:@"downloadSiteToActionEnabled"];
	[_preferences registerBool:&_downloadImageToActionEnabled default:YES forKey:@"downloadImageToActionEnabled"];
	[_preferences registerBool:&_instantDownloadsEnabled default:NO forKey:@"instantDownloadsEnabled"];
	[_preferences registerInteger:&_instantDownloadsOption default:NO forKey:@"instantDownloadsOption"];
	[_preferences registerBool:&_customDefaultPathEnabled default:NO forKey:@"customDefaultPathEnabled"];
	[_preferences registerObject:&_customDefaultPath default:defaultDownloadPath forKey:@"customDefaultPath"];
	[_preferences registerBool:&_pinnedLocationsEnabled default:NO forKey:@"pinnedLocationsEnabled"];
	[_preferences registerObject:&_pinnedLocations default:nil forKey:@"pinnedLocations"];
	[_preferences registerBool:&_onlyDownloadOnWifiEnabled default:NO forKey:@"onlyDownloadOnWifiEnabled"];
	[_preferences registerBool:&_disablePushNotificationsEnabled default:NO forKey:@"disablePushNotificationsEnabled"];
	[_preferences registerBool:&_disableBarNotificationsEnabled default:NO forKey:@"disableBarNotificationsEnabled"];

	[_preferences registerBool:&_bothTabOpenActionsEnabled default:NO forKey:@"bothTabOpenActionsEnabled"];
	[_preferences registerBool:&_openInOppositeModeOptionEnabled default:NO forKey:@"openInOppositeModeOptionEnabled"];
	[_preferences registerBool:&_desktopButtonEnabled default:NO forKey:@"desktopButtonEnabled"];
	[_preferences registerBool:&_disableTabLimit default:NO forKey:@"disableTabLimit"];
	[_preferences registerBool:&_tabManagerEnabled default:NO forKey:@"tabManagerEnabled"];
	[_preferences registerBool:&_customStartSiteEnabled default:NO forKey:@"customStartSiteEnabled"];
	[_preferences registerObject:&_customStartSite default:nil forKey:@"customStartSite"];
	[_preferences registerBool:&_longPressSuggestionsEnabled default:NO forKey:@"longPressSuggestionsEnabled"];
	[_preferences registerFloat:&_longPressSuggestionsDuration default:1 forKey:@"longPressSuggestionsDuration"];
	[_preferences registerBool:&_longPressSuggestionsFocusEnabled default:YES forKey:@"longPressSuggestionsFocusEnabled"];
	[_preferences registerBool:&_suggestionInsertButtonEnabled default:NO forKey:@"suggestionInsertButtonEnabled"];
	[_preferences registerBool:&_showTabCountEnabled default:NO forKey:@"showTabCountEnabled"];
	[_preferences registerBool:&_fullscreenScrollingEnabled default:NO forKey:@"fullscreenScrollingEnabled"];
	[_preferences registerBool:&_lockBars default:NO forKey:@"lockBars"];

	[_preferences registerBool:&_forceModeOnStartEnabled default:NO forKey:@"forceModeOnStartEnabled"];
	[_preferences registerInteger:&_forceModeOnStartFor default:0 forKey:@"forceModeOnStartFor"];
	[_preferences registerBool:&_forceModeOnResumeEnabled default:NO forKey:@"forceModeOnResumeEnabled"];
	[_preferences registerInteger:&_forceModeOnResumeFor default:0 forKey:@"forceModeOnResumeFor"];
	[_preferences registerBool:&_forceModeOnExternalLinkEnabled default:NO forKey:@"forceModeOnExternalLinkEnabled"];
	[_preferences registerInteger:&_forceModeOnExternalLinkFor default:0 forKey:@"forceModeOnExternalLinkFor"];
	[_preferences registerBool:&_autoCloseTabsEnabled default:NO forKey:@"autoCloseTabsEnabled"];
	[_preferences registerInteger:&_autoCloseTabsOn default:0 forKey:@"autoCloseTabsOn"];
	[_preferences registerInteger:&_autoCloseTabsFor default:0 forKey:@"autoCloseTabsFor"];
	[_preferences registerBool:&_autoDeleteDataEnabled default:NO forKey:@"autoDeleteDataEnabled"];
	[_preferences registerInteger:&_autoDeleteDataOn default:0 forKey:@"autoDeleteDataOn"];

	[_preferences registerBool:&_URLLeftSwipeGestureEnabled default:NO forKey:@"URLLeftSwipeGestureEnabled"];
	[_preferences registerInteger:&_URLLeftSwipeAction default:0 forKey:@"URLLeftSwipeAction"];
	[_preferences registerBool:&_URLRightSwipeGestureEnabled default:NO forKey:@"URLRightSwipeGestureEnabled"];
	[_preferences registerInteger:&_URLRightSwipeAction default:0 forKey:@"URLRightSwipeAction"];
	[_preferences registerBool:&_URLDownSwipeGestureEnabled default:NO forKey:@"URLDownSwipeGestureEnabled"];
	[_preferences registerInteger:&_URLDownSwipeAction default:0 forKey:@"URLDownSwipeAction"];
	[_preferences registerBool:&_gestureBackground default:NO forKey:@"gestureBackground"];
	[_preferences registerBool:&_alwaysOpenNewTabEnabled default:NO forKey:@"alwaysOpenNewTabEnabled"];
	[_preferences registerBool:&_alwaysOpenNewTabInBackgroundEnabled default:NO forKey:@"alwaysOpenNewTabInBackgroundEnabled"];
	[_preferences registerBool:&_disablePrivateMode default:NO forKey:@"disablePrivateMode"];
	[_preferences registerBool:&_suppressMailToDialog default:NO forKey:@"suppressMailToDialog"];
	[_preferences registerBool:&_communicationErrorDisabled default:NO forKey:@"communicationErrorDisabled"];

	#if !defined(NO_LIBCSCOLORPICKER)

	[_preferences registerBool:&_topBarNormalTintColorEnabled default:NO forKey:@"topBarNormalTintColorEnabled"];
	[_preferences registerObject:&_topBarNormalTintColor default:nil forKey:@"topBarNormalTintColor"];
	[_preferences registerBool:&_topBarNormalBackgroundColorEnabled default:NO forKey:@"topBarNormalBackgroundColorEnabled"];
	[_preferences registerObject:&_topBarNormalBackgroundColor default:nil forKey:@"topBarNormalBackgroundColor"];
	[_preferences registerBool:&_topBarNormalStatusBarStyleEnabled default:UIStatusBarStyleDefault forKey:@"topBarNormalStatusBarStyleEnabled"];
	[_preferences registerInteger:(NSInteger*)&_topBarNormalStatusBarStyle default:NO forKey:@"topBarNormalStatusBarStyle"];
	[_preferences registerBool:&_topBarNormalReaderButtonColorEnabled default:NO forKey:@"topBarNormalReaderButtonColorEnabled"];
	[_preferences registerObject:&_topBarNormalReaderButtonColor default:nil forKey:@"topBarNormalReaderButtonColor"];
	[_preferences registerBool:&_topBarNormalLockIconColorEnabled default:NO forKey:@"topBarNormalLockIconColorEnabled"];
	[_preferences registerObject:&_topBarNormalLockIconColor default:nil forKey:@"topBarNormalLockIconColor"];
	[_preferences registerBool:&_topBarNormalURLFontColorEnabled default:NO forKey:@"topBarNormalURLFontColorEnabled"];
	[_preferences registerObject:&_topBarNormalURLFontColor default:nil forKey:@"topBarNormalURLFontColor"];
	[_preferences registerBool:&_topBarNormalReloadButtonColorEnabled default:NO forKey:@"topBarNormalReloadButtonColorEnabled"];
	[_preferences registerObject:&_topBarNormalReloadButtonColor default:nil forKey:@"topBarNormalReloadButtonColor"];
	[_preferences registerBool:&_topBarNormalProgressBarColorEnabled default:NO forKey:@"topBarNormalProgressBarColorEnabled"];
	[_preferences registerObject:&_topBarNormalProgressBarColor default:nil forKey:@"topBarNormalProgressBarColor"];
	[_preferences registerBool:&_topBarNormalTabBarCloseButtonColorEnabled default:NO forKey:@"topBarNormalTabBarCloseButtonColorEnabled"];
	[_preferences registerObject:&_topBarNormalTabBarCloseButtonColor default:nil forKey:@"topBarNormalTabBarCloseButtonColor"];
	[_preferences registerBool:&_topBarNormalTabBarTitleColorEnabled default:NO forKey:@"topBarNormalTabBarTitleColorEnabled"];
	[_preferences registerObject:&_topBarNormalTabBarTitleColor default:nil forKey:@"topBarNormalTabBarTitleColor"];
	[_preferences registerFloat:&_topBarNormalTabBarInactiveTitleOpacity default:0.4 forKey:@"topBarNormalTabBarInactiveTitleOpacity"];
	[_preferences registerBool:&_bottomBarNormalTintColorEnabled default:NO forKey:@"bottomBarNormalTintColorEnabled"];
	[_preferences registerObject:&_bottomBarNormalTintColor default:nil forKey:@"bottomBarNormalTintColor"];
	[_preferences registerBool:&_bottomBarNormalBackgroundColorEnabled default:NO forKey:@"bottomBarNormalBackgroundColorEnabled"];
	[_preferences registerObject:&_bottomBarNormalBackgroundColor default:nil forKey:@"bottomBarNormalBackgroundColor"];
	[_preferences registerBool:&_tabTitleBarNormalTextColorEnabled default:NO forKey:@"tabTitleBarNormalTextColorEnabled"];
	[_preferences registerObject:&_tabTitleBarNormalTextColor default:nil forKey:@"tabTitleBarNormalTextColor"];
	[_preferences registerBool:&_tabTitleBarNormalBackgroundColorEnabled default:NO forKey:@"tabTitleBarNormalBackgroundColorEnabled"];
	[_preferences registerObject:&_tabTitleBarNormalBackgroundColor default:nil forKey:@"tabTitleBarNormalBackgroundColor"];
	[_preferences registerBool:&_tabSwitcherNormalToolbarBackgroundColorEnabled default:NO forKey:@"tabSwitcherNormalToolbarBackgroundColorEnabled"];
	[_preferences registerObject:&_tabSwitcherNormalToolbarBackgroundColor default:nil forKey:@"tabSwitcherNormalToolbarBackgroundColor"];

	[_preferences registerBool:&_topBarPrivateTintColorEnabled default:NO forKey:@"topBarPrivateTintColorEnabled"];
	[_preferences registerObject:&_topBarPrivateTintColor default:nil forKey:@"topBarPrivateTintColor"];
	[_preferences registerBool:&_topBarPrivateBackgroundColorEnabled default:NO forKey:@"topBarPrivateBackgroundColorEnabled"];
	[_preferences registerObject:&_topBarPrivateBackgroundColor default:nil forKey:@"topBarPrivateBackgroundColor"];
	[_preferences registerBool:&_topBarPrivateStatusBarStyleEnabled default:UIStatusBarStyleDefault forKey:@"topBarPrivateStatusBarStyleEnabled"];
	[_preferences registerInteger:(NSInteger*)&_topBarPrivateStatusBarStyle default:NO forKey:@"topBarPrivateStatusBarStyle"];
	[_preferences registerBool:&_topBarPrivateReaderButtonColorEnabled default:NO forKey:@"topBarPrivateReaderButtonColorEnabled"];
	[_preferences registerObject:&_topBarPrivateReaderButtonColor default:nil forKey:@"topBarPrivateReaderButtonColor"];
	[_preferences registerBool:&_topBarPrivateLockIconColorEnabled default:NO forKey:@"topBarPrivateLockIconColorEnabled"];
	[_preferences registerObject:&_topBarPrivateLockIconColor default:nil forKey:@"topBarPrivateLockIconColor"];
	[_preferences registerBool:&_topBarPrivateURLFontColorEnabled default:NO forKey:@"topBarPrivateURLFontColorEnabled"];
	[_preferences registerObject:&_topBarPrivateURLFontColor default:nil forKey:@"topBarPrivateURLFontColor"];
	[_preferences registerBool:&_topBarPrivateReloadButtonColorEnabled default:NO forKey:@"topBarPrivateReloadButtonColorEnabled"];
	[_preferences registerObject:&_topBarPrivateReloadButtonColor default:nil forKey:@"topBarPrivateReloadButtonColor"];
	[_preferences registerBool:&_topBarPrivateProgressBarColorEnabled default:NO forKey:@"topBarPrivateProgressBarColorEnabled"];
	[_preferences registerObject:&_topBarPrivateProgressBarColor default:nil forKey:@"topBarPrivateProgressBarColor"];
	[_preferences registerBool:&_topBarPrivateTabBarCloseButtonColorEnabled default:NO forKey:@"topBarPrivateTabBarCloseButtonColorEnabled"];
	[_preferences registerObject:&_topBarPrivateTabBarCloseButtonColor default:nil forKey:@"topBarPrivateTabBarCloseButtonColor"];
	[_preferences registerBool:&_topBarPrivateTabBarTitleColorEnabled default:NO forKey:@"topBarPrivateTabBarTitleColorEnabled"];
	[_preferences registerObject:&_topBarPrivateTabBarTitleColor default:nil forKey:@"topBarPrivateTabBarTitleColor"];
	[_preferences registerFloat:&_topBarPrivateTabBarInactiveTitleOpacity default:0.2 forKey:@"topBarPrivateTabBarInactiveTitleOpacity"];
	[_preferences registerBool:&_bottomBarPrivateTintColorEnabled default:NO forKey:@"bottomBarPrivateTintColorEnabled"];
	[_preferences registerObject:&_bottomBarPrivateTintColor default:nil forKey:@"bottomBarPrivateTintColor"];
	[_preferences registerBool:&_bottomBarPrivateBackgroundColorEnabled default:NO forKey:@"bottomBarPrivateBackgroundColorEnabled"];
	[_preferences registerObject:&_bottomBarPrivateBackgroundColor default:nil forKey:@"bottomBarPrivateBackgroundColor"];
	[_preferences registerBool:&_tabTitleBarPrivateTextColorEnabled default:NO forKey:@"tabTitleBarPrivateTextColorEnabled"];
	[_preferences registerObject:&_tabTitleBarPrivateTextColor default:nil forKey:@"tabTitleBarPrivateTextColor"];
	[_preferences registerBool:&_tabTitleBarPrivateBackgroundColorEnabled default:NO forKey:@"tabTitleBarPrivateBackgroundColorEnabled"];
	[_preferences registerObject:&_tabTitleBarPrivateBackgroundColor default:nil forKey:@"tabTitleBarPrivateBackgroundColor"];
	[_preferences registerBool:&_tabSwitcherPrivateToolbarBackgroundColorEnabled default:NO forKey:@"tabSwitcherPrivateToolbarBackgroundColorEnabled"];
	[_preferences registerObject:&_tabSwitcherPrivateToolbarBackgroundColor default:nil forKey:@"tabSwitcherPrivateToolbarBackgroundColor"];

	#endif

	[_preferences registerBool:&_topToolbarCustomOrderEnabled default:NO forKey:@"topToolbarCustomOrderEnabled"];
	[_preferences registerObject:&_topToolbarCustomOrder default:@[@(BrowserToolbarBackItem),@(BrowserToolbarForwardItem),@(BrowserToolbarBookmarksItem),@(BrowserToolbarSearchBarSpace),@(BrowserToolbarShareItem),@(BrowserToolbarAddTabItem),@(BrowserToolbarTabExposeItem)] forKey:@"topToolbarCustomOrder"];
	[_preferences registerBool:&_bottomToolbarCustomOrderEnabled default:NO forKey:@"bottomToolbarCustomOrderEnabled"];
	[_preferences registerObject:&_bottomToolbarCustomOrder default:@[@(BrowserToolbarBackItem),@(BrowserToolbarForwardItem),@(BrowserToolbarShareItem),@(BrowserToolbarBookmarksItem),@(BrowserToolbarTabExposeItem)] forKey:@"bottomToolbarCustomOrder"];

  #endif

	return self;
}

#if defined NO_CEPHEI

#if defined SIMJECT

- (void)reloadPrefs
{
	CFStringRef appID = (__bridge CFStringRef)SPPrefsDomain;

	CFPreferencesAppSynchronize(appID);

	// *INDENT-OFF*

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0)
	{
		NSNumber* tweakEnabled = (__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("tweakEnabled"), appID);
		_tweakEnabled = tweakEnabled ? [tweakEnabled boolValue] : YES;

		_forceHTTPSEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("forceHTTPSEnabled"), appID) boolValue];
		_forceHTTPSExceptions = (__bridge NSArray*)CFPreferencesCopyAppValue(CFSTR("forceHTTPSExceptions"), appID);
		_lockedTabsEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("lockedTabsEnabled"), appID) boolValue];
		_biometricProtectionEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("biometricProtectionEnabled"), appID) boolValue];
		_biometricProtectionSwitchModeEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("biometricProtectionSwitchModeEnabled"), appID) boolValue];
		_biometricProtectionLockTabEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("biometricProtectionLockTabEnabled"), appID) boolValue];
		_biometricProtectionUnlockTabEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("biometricProtectionUnlockTabEnabled"), appID) boolValue];
		_biometricProtectionAccessLockedTabEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("biometricProtectionAccessLockedTabEnabled"), appID) boolValue];

		_uploadAnyFileOptionEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("uploadAnyFileOptionEnabled"), appID) boolValue];
		_enhancedDownloadsEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("enhancedDownloadsEnabled"), appID) boolValue];
		_videoDownloadingEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("videoDownloadingEnabled"), appID) boolValue];
		NSNumber* defaultDownloadSection = (__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("defaultDownloadSection"), appID);
		_defaultDownloadSection = defaultDownloadSection ? [defaultDownloadSection intValue] : 1;
		_defaultDownloadSectionAutoSwitchEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("defaultDownloadSectionAutoSwitchEnabled"), appID) boolValue];
		NSNumber* downloadSiteToActionEnabled = (__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("downloadSiteToActionEnabled"), appID);
		_downloadSiteToActionEnabled = downloadSiteToActionEnabled ? [downloadSiteToActionEnabled boolValue] : YES;
		NSNumber* downloadImageToActionEnabled = (__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("downloadImageToActionEnabled"), appID);
		_downloadImageToActionEnabled = downloadImageToActionEnabled ? [downloadImageToActionEnabled boolValue] : YES;
		_instantDownloadsEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("instantDownloadsEnabled"), appID) boolValue];
		_instantDownloadsOption = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("instantDownloadsOption"), appID) intValue];
		_customDefaultPathEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("customDefaultPathEnabled"), appID) boolValue];
		_customDefaultPath = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("customDefaultPath"), appID);
		_pinnedLocationsEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("pinnedLocationsEnabled"), appID) boolValue];
		_pinnedLocations = (__bridge NSArray*)CFPreferencesCopyAppValue(CFSTR("pinnedLocations"), appID);
		_onlyDownloadOnWifiEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("onlyDownloadOnWifiEnabled"), appID) boolValue];
		_disablePushNotificationsEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("disablePushNotificationsEnabled"), appID) boolValue];
		_disableBarNotificationsEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("disableBarNotificationsEnabled"), appID) boolValue];

		_bothTabOpenActionsEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("bothTabOpenActionsEnabled"), appID) boolValue];
		_openInOppositeModeOptionEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("openInOppositeModeOptionEnabled"), appID) boolValue];
		_desktopButtonEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("desktopButtonEnabled"), appID) boolValue];
		_disableTabLimit = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("disableTabLimit"), appID) boolValue];
		_tabManagerEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("tabManagerEnabled"), appID) boolValue];
		_customStartSiteEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("customStartSiteEnabled"), appID) boolValue];
		_customStartSite = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("customStartSite"), appID);
		_longPressSuggestionsEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("longPressSuggestionsEnabled"), appID) boolValue];
		NSNumber* longPressSuggestionsDuration = (__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("longPressSuggestionsDuration"), appID);
		_longPressSuggestionsDuration = longPressSuggestionsDuration ? [longPressSuggestionsDuration floatValue] : 0.5;
		_longPressSuggestionsFocusEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("longPressSuggestionsFocusEnabled"), appID) boolValue];
		_suggestionInsertButtonEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("suggestionInsertButtonEnabled"), appID) boolValue];
		_showTabCountEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("showTabCountEnabled"), appID) boolValue];
		_fullscreenScrollingEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("fullscreenScrollingEnabled"), appID) boolValue];
		_lockBars = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("lockBars"), appID) boolValue];

		_forceModeOnStartEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("forceModeOnStartEnabled"), appID) boolValue];
		_forceModeOnStartFor = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("forceModeOnStartFor"), appID) intValue];
		_forceModeOnResumeEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("forceModeOnResumeEnabled"), appID) boolValue];
		_forceModeOnResumeFor = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("forceModeOnResumeFor"), appID) intValue];
		_forceModeOnExternalLinkEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("forceModeOnExternalLinkEnabled"), appID) boolValue];
		_forceModeOnExternalLinkFor = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("forceModeOnExternalLinkFor"), appID) boolValue];
		_autoCloseTabsEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("autoCloseTabsEnabled"), appID) boolValue];
		_autoCloseTabsOn = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("autoCloseTabsOn"), appID) intValue];
		_autoCloseTabsFor = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("autoCloseTabsFor"), appID) intValue];
		_autoDeleteDataEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("autoDeleteDataEnabled"), appID) boolValue];
		_autoDeleteDataOn = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("autoDeleteDataOn"), appID) intValue];

		_URLLeftSwipeGestureEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("URLLeftSwipeGestureEnabled"), appID) boolValue];
		_URLLeftSwipeAction = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("URLLeftSwipeAction"), appID) intValue];
		_URLRightSwipeGestureEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("URLRightSwipeGestureEnabled"), appID) boolValue];
		_URLRightSwipeAction = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("URLRightSwipeAction"), appID) intValue];
		_URLDownSwipeGestureEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("URLDownSwipeGestureEnabled"), appID) boolValue];
		_URLDownSwipeAction = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("URLDownSwipeAction"), appID) intValue];
		_gestureBackground = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("gestureBackground"), appID) boolValue];
		_alwaysOpenNewTabEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("alwaysOpenNewTabEnabled"), appID) boolValue];
		_alwaysOpenNewTabInBackgroundEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("alwaysOpenNewTabInBackgroundEnabled"), appID) boolValue];
		_disablePrivateMode = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("disablePrivateMode"), appID) boolValue];
		_suppressMailToDialog = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("suppressMailToDialog"), appID) boolValue];

		 #if !defined(NO_LIBCSCOLORPICKER)

		_topBarNormalTintColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("topBarNormalTintColorEnabled"), appID) boolValue];
		_topBarNormalTintColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("topBarNormalTintColor"), appID);
		_topBarNormalBackgroundColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("topBarNormalBackgroundColorEnabled"), appID) boolValue];
		_topBarNormalBackgroundColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("topBarNormalBackgroundColor"), appID);
		_topBarNormalStatusBarStyleEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("topBarNormalStatusBarStyleEnabled"), appID) boolValue];
		_topBarNormalStatusBarStyle = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("topBarNormalStatusBarStyle"), appID) intValue];
		_topBarNormalReaderButtonColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("topBarNormalReaderButtonColorEnabled"), appID) boolValue];
		_topBarNormalReaderButtonColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("topBarNormalReaderButtonColor"), appID);
		_topBarNormalLockIconColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("topBarNormalLockIconColorEnabled"), appID) boolValue];
		_topBarNormalLockIconColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("topBarNormalLockIconColor"), appID);
		_topBarNormalURLFontColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("topBarNormalURLFontColorEnabled"), appID) boolValue];
		_topBarNormalURLFontColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("topBarNormalURLFontColor"), appID);
		_topBarNormalReloadButtonColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("topBarNormalReloadButtonColorEnabled"), appID) boolValue];
		_topBarNormalReloadButtonColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("topBarNormalReloadButtonColor"), appID);
		_topBarNormalProgressBarColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("topBarNormalProgressBarColorEnabled"), appID) boolValue];
		_topBarNormalProgressBarColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("topBarNormalProgressBarColor"), appID);
		_topBarNormalTabBarCloseButtonColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("topBarNormalTabBarCloseButtonColorEnabled"), appID) boolValue];
		_topBarNormalTabBarCloseButtonColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("topBarNormalTabBarCloseButtonColor"), appID);
		_topBarNormalTabBarTitleColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("topBarNormalTabBarTitleColorEnabled"), appID) boolValue];
		_topBarNormalTabBarTitleColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("topBarNormalTabBarTitleColor"), appID);
		_topBarNormalTabBarInactiveTitleOpacity = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("topBarNormalTabBarInactiveTitleOpacity"), appID) floatValue];
		_bottomBarNormalTintColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("bottomBarNormalTintColorEnabled"), appID) boolValue];
		_bottomBarNormalTintColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("bottomBarNormalTintColor"), appID);
		_bottomBarNormalBackgroundColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("bottomBarNormalBackgroundColorEnabled"), appID) boolValue];
		_bottomBarNormalBackgroundColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("bottomBarNormalBackgroundColor"), appID);
		_tabTitleBarNormalTextColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("tabTitleBarNormalTextColorEnabled"), appID) boolValue];
		_tabTitleBarNormalTextColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("tabTitleBarNormalTextColor"), appID);
		_tabTitleBarNormalBackgroundColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("tabTitleBarNormalBackgroundColorEnabled"), appID) boolValue];
		_tabTitleBarNormalBackgroundColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("tabTitleBarNormalBackgroundColor"), appID);
		_tabSwitcherNormalToolbarBackgroundColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("tabSwitcherNormalToolbarBackgroundColorEnabled"), appID) boolValue];
		_tabSwitcherNormalToolbarBackgroundColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("tabSwitcherNormalToolbarBackgroundColor"), appID);

		_topBarPrivateTintColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("topBarPrivateTintColorEnabled"), appID) boolValue];
		_topBarPrivateTintColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("topBarPrivateTintColor"), appID);
		_topBarPrivateBackgroundColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("topBarPrivateBackgroundColorEnabled"), appID) boolValue];
		_topBarPrivateBackgroundColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("topBarPrivateBackgroundColor"), appID);
		_topBarPrivateStatusBarStyleEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("topBarPrivateStatusBarStyleEnabled"), appID) boolValue];
		_topBarPrivateStatusBarStyle = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("topBarPrivateStatusBarStyle"), appID) intValue];
		_topBarPrivateReaderButtonColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("topBarPrivateReaderButtonColorEnabled"), appID) boolValue];
		_topBarPrivateReaderButtonColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("topBarPrivateReaderButtonColor"), appID);
		_topBarPrivateLockIconColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("topBarPrivateLockIconColorEnabled"), appID) boolValue];
		_topBarPrivateLockIconColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("topBarPrivateLockIconColor"), appID);
		_topBarPrivateURLFontColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("topBarPrivateURLFontColorEnabled"), appID) boolValue];
		_topBarPrivateURLFontColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("topBarPrivateURLFontColor"), appID);
		_topBarPrivateReloadButtonColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("topBarPrivateReloadButtonColorEnabled"), appID) boolValue];
		_topBarPrivateReloadButtonColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("topBarPrivateReloadButtonColor"), appID);
		_topBarPrivateProgressBarColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("topBarPrivateProgressBarColorEnabled"), appID) boolValue];
		_topBarPrivateProgressBarColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("topBarPrivateProgressBarColor"), appID);
		_topBarPrivateTabBarCloseButtonColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("topBarPrivateTabBarCloseButtonColorEnabled"), appID) boolValue];
		_topBarPrivateTabBarCloseButtonColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("topBarPrivateTabBarCloseButtonColor"), appID);
		_topBarPrivateTabBarTitleColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("topBarPrivateTabBarTitleColorEnabled"), appID) boolValue];
		_topBarPrivateTabBarTitleColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("topBarPrivateTabBarTitleColor"), appID);
		_topBarPrivateTabBarInactiveTitleOpacity = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("topBarPrivateTabBarInactiveTitleOpacity"), appID) floatValue];
		_bottomBarPrivateTintColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("bottomBarPrivateTintColorEnabled"), appID) boolValue];
		_bottomBarPrivateTintColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("bottomBarPrivateTintColor"), appID);
		_bottomBarPrivateBackgroundColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("bottomBarPrivateBackgroundColorEnabled"), appID) boolValue];
		_bottomBarPrivateBackgroundColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("bottomBarPrivateBackgroundColor"), appID);
		_tabTitleBarPrivateTextColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("tabTitleBarPrivateTextColorEnabled"), appID) boolValue];
		_tabTitleBarPrivateTextColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("tabTitleBarPrivateTextColor"), appID);
		_tabTitleBarPrivateBackgroundColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("tabTitleBarPrivateBackgroundColorEnabled"), appID) boolValue];
		_tabTitleBarPrivateBackgroundColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("tabTitleBarPrivateBackgroundColor"), appID);
		_tabSwitcherPrivateToolbarBackgroundColorEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("tabSwitcherPrivateToolbarBackgroundColorEnabled"), appID) boolValue];
		_tabSwitcherPrivateToolbarBackgroundColor = (__bridge NSString*)CFPreferencesCopyAppValue(CFSTR("tabSwitcherPrivateToolbarBackgroundColor"), appID);

		 #endif

		 _topToolbarCustomOrderEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("topToolbarCustomOrderEnabled"), appID) boolValue];
		 _topToolbarCustomOrder = (__bridge NSArray*)CFPreferencesCopyAppValue(CFSTR("topToolbarCustomOrder"), appID);
		 _bottomToolbarCustomOrderEnabled = [(__bridge NSNumber*)CFPreferencesCopyAppValue(CFSTR("bottomToolbarCustomOrderEnabled"), appID) boolValue];
		 _bottomToolbarCustomOrder = (__bridge NSArray*)CFPreferencesCopyAppValue(CFSTR("bottomToolbarCustomOrder"), appID);
	}
	else
	{
		NSDictionary* prefDict = [NSDictionary dictionaryWithContentsOfFile:rPath(@"/var/mobile/Library/Preferences/com.opa334.safariplusprefs.plist")];

		NSNumber* tweakEnabled = [prefDict objectForKey:@"tweakEnabled"];
		_tweakEnabled = tweakEnabled ? [tweakEnabled boolValue] : YES;

		_forceHTTPSEnabled = [[prefDict objectForKey:@"forceHTTPSEnabled"] boolValue];
		_forceHTTPSExceptions = [prefDict objectForKey:@"forceHTTPSExceptions"];
		_lockedTabsEnabled = [[prefDict objectForKey:@"lockedTabsEnabled"] boolValue];

		_uploadAnyFileOptionEnabled = [[prefDict objectForKey:@"uploadAnyFileOptionEnabled"] boolValue];
		_enhancedDownloadsEnabled = [[prefDict objectForKey:@"enhancedDownloadsEnabled"] boolValue];
		_videoDownloadingEnabled = [[prefDict objectForKey:@"videoDownloadingEnabled"] boolValue];
		NSNumber* defaultDownloadSection = [prefDict objectForKey:@"defaultDownloadSection"];
		_defaultDownloadSection = defaultDownloadSection ? [defaultDownloadSection intValue] : 1;
		_defaultDownloadSectionAutoSwitchEnabled = [[prefDict objectForKey:@"defaultDownloadSectionAutoSwitchEnabled"] boolValue];
		NSNumber* downloadSiteToActionEnabled = [prefDict objectForKey:@"downloadSiteToActionEnabled"];
		_downloadSiteToActionEnabled = downloadSiteToActionEnabled ? [downloadSiteToActionEnabled boolValue] : YES;
		NSNumber* downloadImageToActionEnabled = [prefDict objectForKey:@"downloadImageToActionEnabled"];
		_downloadImageToActionEnabled = downloadImageToActionEnabled ? [downloadImageToActionEnabled boolValue] : YES;
		_instantDownloadsEnabled = [[prefDict objectForKey:@"instantDownloadsEnabled"] boolValue];
		_instantDownloadsOption = [[prefDict objectForKey:@"instantDownloadsOption"] intValue];
		_customDefaultPathEnabled = [[prefDict objectForKey:@"customDefaultPathEnabled"] boolValue];
		_customDefaultPath = [prefDict objectForKey:@"customDefaultPath"];
		_pinnedLocationsEnabled = [[prefDict objectForKey:@"pinnedLocationsEnabled"] boolValue];
		_pinnedLocations = [prefDict objectForKey:@"pinnedLocations"];
		_onlyDownloadOnWifiEnabled = [[prefDict objectForKey:@"onlyDownloadOnWifiEnabled"] boolValue];
		_disablePushNotificationsEnabled = [[prefDict objectForKey:@"disablePushNotificationsEnabled"] boolValue];
		_disableBarNotificationsEnabled = [[prefDict objectForKey:@"disableBarNotificationsEnabled"] boolValue];

		_bothTabOpenActionsEnabled = [[prefDict objectForKey:@"bothTabOpenActionsEnabled"] boolValue];
		_openInOppositeModeOptionEnabled = [[prefDict objectForKey:@"openInOppositeModeOptionEnabled"] boolValue];
		_desktopButtonEnabled = [[prefDict objectForKey:@"desktopButtonEnabled"] boolValue];
		_disableTabLimit = [[prefDict objectForKey:@"disableTabLimit"] boolValue];
		_tabManagerEnabled = [[prefDict objectForKey:@"tabManagerEnabled"] boolValue];
		_customStartSiteEnabled = [[prefDict objectForKey:@"customStartSiteEnabled"] boolValue];
		_customStartSite = [prefDict objectForKey:@"customStartSite"];
		_longPressSuggestionsEnabled = [[prefDict objectForKey:@"longPressSuggestionsEnabled"] boolValue];
		NSNumber* longPressSuggestionsDuration = [prefDict objectForKey:@"longPressSuggestionsDuration"];
		_longPressSuggestionsDuration = longPressSuggestionsDuration ? [longPressSuggestionsDuration floatValue] : 0.5;
		_longPressSuggestionsFocusEnabled = [[prefDict objectForKey:@"longPressSuggestionsFocusEnabled"] boolValue];
		_suggestionInsertButtonEnabled = [[prefDict objectForKey:@"suggestionInsertButtonEnabled"] boolValue];
		_showTabCountEnabled = [[prefDict objectForKey:@"showTabCountEnabled"] boolValue];
		_fullscreenScrollingEnabled = [[prefDict objectForKey:@"fullscreenScrollingEnabled"] boolValue];
		_lockBars = [[prefDict objectForKey:@"lockBars"] boolValue];

		_forceModeOnStartEnabled = [[prefDict objectForKey:@"forceModeOnStartEnabled"] boolValue];
		_forceModeOnStartFor = [[prefDict objectForKey:@"forceModeOnStartFor"] intValue];
		_forceModeOnResumeEnabled = [[prefDict objectForKey:@"forceModeOnResumeEnabled"] boolValue];
		_forceModeOnResumeFor = [[prefDict objectForKey:@"forceModeOnResumeFor"] intValue];
		_forceModeOnExternalLinkEnabled = [[prefDict objectForKey:@"forceModeOnExternalLinkEnabled"] boolValue];
		_forceModeOnExternalLinkFor = [[prefDict objectForKey:@"forceModeOnExternalLinkFor"] boolValue];
		_autoCloseTabsEnabled = [[prefDict objectForKey:@"autoCloseTabsEnabled"] boolValue];
		_autoCloseTabsOn = [[prefDict objectForKey:@"autoCloseTabsOn"] intValue];
		_autoCloseTabsFor = [[prefDict objectForKey:@"autoCloseTabsFor"] intValue];
		_autoDeleteDataEnabled = [[prefDict objectForKey:@"autoDeleteDataEnabled"] boolValue];
		_autoDeleteDataOn = [[prefDict objectForKey:@"autoDeleteDataOn"] intValue];

		_URLLeftSwipeGestureEnabled = [[prefDict objectForKey:@"URLLeftSwipeGestureEnabled"] boolValue];
		_URLLeftSwipeAction = [[prefDict objectForKey:@"URLLeftSwipeAction"] intValue];
		_URLRightSwipeGestureEnabled = [[prefDict objectForKey:@"URLRightSwipeGestureEnabled"] boolValue];
		_URLRightSwipeAction = [[prefDict objectForKey:@"URLRightSwipeAction"] intValue];
		_URLDownSwipeGestureEnabled = [[prefDict objectForKey:@"URLDownSwipeGestureEnabled"] boolValue];
		_URLDownSwipeAction = [[prefDict objectForKey:@"URLDownSwipeAction"] intValue];
		_gestureBackground = [[prefDict objectForKey:@"gestureBackground"] boolValue];
		_alwaysOpenNewTabEnabled = [[prefDict objectForKey:@"alwaysOpenNewTabEnabled"] boolValue];
		_alwaysOpenNewTabInBackgroundEnabled = [[prefDict objectForKey:@"alwaysOpenNewTabInBackgroundEnabled"] boolValue];
		_disablePrivateMode = [[prefDict objectForKey:@"disablePrivateMode"] boolValue];
		_suppressMailToDialog = [[prefDict objectForKey:@"suppressMailToDialog"] boolValue];

		 #if !defined(NO_LIBCSCOLORPICKER)

		_topBarNormalTintColorEnabled = [[prefDict objectForKey:@"topBarNormalTintColorEnabled"] boolValue];
		_topBarNormalTintColor = [prefDict objectForKey:@"topBarNormalTintColor"];
		_topBarNormalBackgroundColorEnabled = [[prefDict objectForKey:@"topBarNormalBackgroundColorEnabled"] boolValue];
		_topBarNormalBackgroundColor = [prefDict objectForKey:@"topBarNormalBackgroundColor"];
		_topBarNormalStatusBarStyleEnabled = [[prefDict objectForKey:@"topBarNormalStatusBarStyleEnabled"] boolValue];
		_topBarNormalStatusBarStyle = [[prefDict objectForKey:@"topBarNormalStatusBarStyle"] intValue];
		_topBarNormalReaderButtonColorEnabled = [[prefDict objectForKey:@"topBarNormalReaderButtonColorEnabled"] boolValue];
		_topBarNormalReaderButtonColor = [prefDict objectForKey:@"topBarNormalReaderButtonColor"];
		_topBarNormalLockIconColorEnabled = [[prefDict objectForKey:@"topBarNormalLockIconColorEnabled"] boolValue];
		_topBarNormalLockIconColor = [prefDict objectForKey:@"topBarNormalLockIconColor"];
		_topBarNormalURLFontColorEnabled = [[prefDict objectForKey:@"topBarNormalURLFontColorEnabled"] boolValue];
		_topBarNormalURLFontColor = [prefDict objectForKey:@"topBarNormalURLFontColor"];
		_topBarNormalReloadButtonColorEnabled = [[prefDict objectForKey:@"topBarNormalReloadButtonColorEnabled"] boolValue];
		_topBarNormalReloadButtonColor = [prefDict objectForKey:@"topBarNormalReloadButtonColor"];
		_topBarNormalProgressBarColorEnabled = [[prefDict objectForKey:@"topBarNormalProgressBarColorEnabled"] boolValue];
		_topBarNormalProgressBarColor = [prefDict objectForKey:@"topBarNormalProgressBarColor"];
		_topBarNormalTabBarCloseButtonColorEnabled = [[prefDict objectForKey:@"topBarNormalTabBarCloseButtonColorEnabled"] boolValue];
		_topBarNormalTabBarCloseButtonColor = [prefDict objectForKey:@"topBarNormalTabBarCloseButtonColor"];
		_topBarNormalTabBarTitleColorEnabled = [[prefDict objectForKey:@"topBarNormalTabBarTitleColorEnabled"] boolValue];
		_topBarNormalTabBarTitleColor = [prefDict objectForKey:@"topBarNormalTabBarTitleColor"];
		_topBarNormalTabBarInactiveTitleOpacity = [[prefDict objectForKey:@"topBarNormalTabBarInactiveTitleOpacity"] floatValue];
		_bottomBarNormalTintColorEnabled = [[prefDict objectForKey:@"bottomBarNormalTintColorEnabled"] boolValue];
		_bottomBarNormalTintColor = [prefDict objectForKey:@"bottomBarNormalTintColor"];
		_bottomBarNormalBackgroundColorEnabled = [[prefDict objectForKey:@"bottomBarNormalBackgroundColorEnabled"] boolValue];
		_bottomBarNormalBackgroundColor = [prefDict objectForKey:@"bottomBarNormalBackgroundColor"];
		_tabTitleBarNormalTextColorEnabled = [[prefDict objectForKey:@"tabTitleBarNormalTextColorEnabled"] boolValue];
		_tabTitleBarNormalTextColor = [prefDict objectForKey:@"tabTitleBarNormalTextColor"];
		_tabTitleBarNormalBackgroundColorEnabled = [[prefDict objectForKey:@"tabTitleBarNormalBackgroundColorEnabled"] boolValue];
		_tabTitleBarNormalBackgroundColor = [prefDict objectForKey:@"tabTitleBarNormalBackgroundColor"];

		_topBarPrivateTintColorEnabled = [[prefDict objectForKey:@"topBarPrivateTintColorEnabled"] boolValue];
		_topBarPrivateTintColor = [prefDict objectForKey:@"topBarPrivateTintColor"];
		_topBarPrivateBackgroundColorEnabled = [[prefDict objectForKey:@"topBarPrivateBackgroundColorEnabled"] boolValue];
		_topBarPrivateBackgroundColor = [prefDict objectForKey:@"topBarPrivateBackgroundColor"];
		_topBarPrivateStatusBarStyleEnabled = [[prefDict objectForKey:@"topBarPrivateStatusBarStyleEnabled"] boolValue];
		_topBarPrivateStatusBarStyle = [[prefDict objectForKey:@"topBarPrivateStatusBarStyle"] intValue];
		_topBarPrivateReaderButtonColorEnabled = [[prefDict objectForKey:@"topBarPrivateReaderButtonColorEnabled"] boolValue];
		_topBarPrivateReaderButtonColor = [prefDict objectForKey:@"topBarPrivateReaderButtonColor"];
		_topBarPrivateLockIconColorEnabled = [[prefDict objectForKey:@"topBarPrivateLockIconColorEnabled"] boolValue];
		_topBarPrivateLockIconColor = [prefDict objectForKey:@"topBarPrivateLockIconColor"];
		_topBarPrivateURLFontColorEnabled = [[prefDict objectForKey:@"topBarPrivateURLFontColorEnabled"] boolValue];
		_topBarPrivateURLFontColor = [prefDict objectForKey:@"topBarPrivateURLFontColor"];
		_topBarPrivateReloadButtonColorEnabled = [[prefDict objectForKey:@"topBarPrivateReloadButtonColorEnabled"] boolValue];
		_topBarPrivateReloadButtonColor = [prefDict objectForKey:@"topBarPrivateReloadButtonColor"];
		_topBarPrivateProgressBarColorEnabled = [[prefDict objectForKey:@"topBarPrivateProgressBarColorEnabled"] boolValue];
		_topBarPrivateProgressBarColor = [prefDict objectForKey:@"topBarPrivateProgressBarColor"];
		_topBarPrivateTabBarCloseButtonColorEnabled = [[prefDict objectForKey:@"topBarPrivateTabBarCloseButtonColorEnabled"] boolValue];
		_topBarPrivateTabBarCloseButtonColor = [prefDict objectForKey:@"topBarPrivateTabBarCloseButtonColor"];
		_topBarPrivateTabBarTitleColorEnabled = [[prefDict objectForKey:@"topBarPrivateTabBarTitleColorEnabled"] boolValue];
		_topBarPrivateTabBarTitleColor = [prefDict objectForKey:@"topBarPrivateTabBarTitleColor"];
		_topBarPrivateTabBarInactiveTitleOpacity = [[prefDict objectForKey:@"topBarPrivateTabBarInactiveTitleOpacity"] floatValue];
		_bottomBarPrivateTintColorEnabled = [[prefDict objectForKey:@"bottomBarPrivateTintColorEnabled"] boolValue];
		_bottomBarPrivateTintColor = [prefDict objectForKey:@"bottomBarPrivateTintColor"];
		_bottomBarPrivateBackgroundColorEnabled = [[prefDict objectForKey:@"bottomBarPrivateBackgroundColorEnabled"] boolValue];
		_bottomBarPrivateBackgroundColor = [prefDict objectForKey:@"bottomBarPrivateBackgroundColor"];
		_tabTitleBarPrivateTextColorEnabled = [[prefDict objectForKey:@"tabTitleBarPrivateTextColorEnabled"] boolValue];
		_tabTitleBarPrivateTextColor = [prefDict objectForKey:@"tabTitleBarPrivateTextColor"];
		_tabTitleBarPrivateBackgroundColorEnabled = [[prefDict objectForKey:@"tabTitleBarPrivateBackgroundColorEnabled"] boolValue];
		_tabTitleBarPrivateBackgroundColor = [prefDict objectForKey:@"tabTitleBarPrivateBackgroundColor"];
		_tabSwitcherPrivateToolbarBackgroundColorEnabled = [[prefDict objectForKey:@"tabSwitcherPrivateToolbarBackgroundColorEnabled"] boolValue];
		_tabSwitcherPrivateToolbarBackgroundColor = [prefDict objectForKey:@"tabSwitcherPrivateToolbarBackgroundColor"];

		#endif
	}


	// *INDENT-ON*
}

#else

- (void)reloadPrefs
{
	_preferences = [[NSDictionary alloc] initWithContentsOfFile:rPath(prefPlistPath)];
}

- (BOOL)forceHTTPSEnabled { return [[_preferences objectForKey:@"forceHTTPSEnabled"] boolValue]; }
- (NSArray*)forceHTTPSExceptions { return [_preferences objectForKey:@"forceHTTPSExceptions"]; }
- (BOOL)openInOppositeModeOptionEnabled { return [[_preferences objectForKey:@"openInOppositeModeOptionEnabled"] boolValue]; }
- (BOOL)bothTabOpenActionsEnabled { return [[_preferences objectForKey:@"bothTabOpenActionsEnabled"] boolValue]; }
- (BOOL)uploadAnyFileOptionEnabled { return [[_preferences objectForKey:@"uploadAnyFileOptionEnabled"] boolValue]; }
- (BOOL)desktopButtonEnabled { return [[_preferences objectForKey:@"desktopButtonEnabled"] boolValue]; }
- (BOOL)longPressSuggestionsEnabled { return [[_preferences objectForKey:@"longPressSuggestionsEnabled"] boolValue]; }
- (CGFloat)longPressSuggestionsDuration { return [_preferences objectForKey:@"longPressSuggestionsDuration"] ? [[_preferences objectForKey:@"longPressSuggestionsDuration"] floatValue] : 0.5; }
- (BOOL)longPressSuggestionsFocusEnabled { return [[_preferences objectForKey:@"longPressSuggestionsFocusEnabled"] boolValue]; }

- (BOOL)enhancedDownloadsEnabled { return [[_preferences objectForKey:@"enhancedDownloadsEnabled"] boolValue]; }
- (BOOL)videoDownloadingEnabled { return [[_preferences objectForKey:@"videoDownloadingEnabled"] boolValue]; }
- (NSInteger)defaultDownloadSection { return [_preferences objectForKey:@"defaultDownloadSection"] ? [[_preferences objectForKey:@"defaultDownloadSection"] integerValue] : 1; }
- (BOOL)defaultDownloadSectionAutoSwitchEnabled { return [[_preferences objectForKey:@"defaultDownloadSectionAutoSwitchEnabled"] boolValue]; }
- (BOOL)downloadSiteToActionEnabled { return [_preferences objectForKey:@"downloadSiteToActionEnabled"] ? [[_preferences objectForKey:@"downloadSiteToActionEnabled"] boolValue] : YES; }
- (BOOL)downloadImageToActionEnabled { return [_preferences objectForKey:@"downloadImageToActionEnabled"] ? [[_preferences objectForKey:@"downloadImageToActionEnabled"] boolValue] : YES; }
- (BOOL)instantDownloadsEnabled { return [[_preferences objectForKey:@"instantDownloadsEnabled"] boolValue]; }
- (NSInteger)instantDownloadsOption { return [[_preferences objectForKey:@"instantDownloadsOption"] integerValue]; }
- (BOOL)customDefaultPathEnabled { return [[_preferences objectForKey:@"customDefaultPathEnabled"] boolValue]; }
- (NSString*)customDefaultPath { return [_preferences objectForKey:@"customDefaultPath"]; }
- (BOOL)pinnedLocationsEnabled { return [[_preferences objectForKey:@"pinnedLocationsEnabled"] boolValue]; }
- (NSArray*)pinnedLocations { return [_preferences objectForKey:@"pinnedLocations"]; }
- (BOOL)onlyDownloadOnWifiEnabled { return [[_preferences objectForKey:@"onlyDownloadOnWifiEnabled"] boolValue]; }
- (BOOL)disablePushNotificationsEnabled { return [[_preferences objectForKey:@"disablePushNotificationsEnabled"] boolValue]; }
- (BOOL)disableBarNotificationsEnabled { return [[_preferences objectForKey:@"disableBarNotificationsEnabled"] boolValue]; }

- (BOOL)forceModeOnStartEnabled { return [[_preferences objectForKey:@"forceModeOnStartEnabled"] boolValue]; }
- (NSInteger)forceModeOnStartFor { return [[_preferences objectForKey:@"forceModeOnStartFor"] integerValue]; }
- (BOOL)forceModeOnResumeEnabled { return [[_preferences objectForKey:@"forceModeOnResumeEnabled"] boolValue]; }
- (NSInteger)forceModeOnResumeFor { return [[_preferences objectForKey:@"forceModeOnResumeFor"] integerValue]; }
- (BOOL)forceModeOnExternalLinkEnabled { return [[_preferences objectForKey:@"forceModeOnExternalLinkEnabled"] boolValue]; }
- (NSInteger)forceModeOnExternalLinkFor { return [[_preferences objectForKey:@"forceModeOnExternalLinkFor"] integerValue]; }
- (BOOL)autoCloseTabsEnabled { return [[_preferences objectForKey:@"autoCloseTabsEnabled"] boolValue]; }
- (NSInteger)autoCloseTabsOn { return [[_preferences objectForKey:@"autoCloseTabsOn"] integerValue]; }
- (NSInteger)autoCloseTabsFor { return [[_preferences objectForKey:@"autoCloseTabsFor"] integerValue]; }
- (BOOL)autoDeleteDataEnabled { return [[_preferences objectForKey:@"autoDeleteDataEnabled"] boolValue]; }
- (NSInteger)autoDeleteDataOn { return [[_preferences objectForKey:@"autoDeleteDataOn"] integerValue]; }

- (BOOL)URLLeftSwipeGestureEnabled { return [[_preferences objectForKey:@"URLLeftSwipeGestureEnabled"] boolValue]; }
- (NSInteger)URLLeftSwipeAction { return [[_preferences objectForKey:@"URLLeftSwipeAction"] integerValue]; }
- (BOOL)URLRightSwipeGestureEnabled { return [[_preferences objectForKey:@"URLRightSwipeGestureEnabled"] boolValue]; }
- (NSInteger)URLRightSwipeAction { return [[_preferences objectForKey:@"URLRightSwipeAction"] integerValue]; }
- (BOOL)URLDownSwipeGestureEnabled { return [[_preferences objectForKey:@"URLDownSwipeGestureEnabled"] boolValue]; }
- (NSInteger)URLDownSwipeAction { return [[_preferences objectForKey:@"URLDownSwipeAction"] integerValue]; }
- (BOOL)gestureBackground { return [[_preferences objectForKey:@"gestureBackground"] boolValue]; }

- (BOOL)fullscreenScrollingEnabled { return [[_preferences objectForKey:@"fullscreenScrollingEnabled"] boolValue]; }
- (BOOL)disableTabLimit { return [[_preferences objectForKey:@"disableTabLimit"] boolValue]; }
- (BOOL)lockBars { return [[_preferences objectForKey:@"lockBars"] boolValue]; }
- (BOOL)disablePrivateMode { return [[_preferences objectForKey:@"disablePrivateMode"] boolValue]; }
- (BOOL)alwaysOpenNewTabEnabled { return [[_preferences objectForKey:@"alwaysOpenNewTabEnabled"] boolValue]; }
- (BOOL)alwaysOpenNewTabInBackgroundEnabled { return [[_preferences objectForKey:@"alwaysOpenNewTabInBackgroundEnabled"] boolValue]; }
- (BOOL)suppressMailToDialog { return [[_preferences objectForKey:@"suppressMailToDialog"] boolValue]; }

#if !defined(NO_LIBCSCOLORPICKER)

- (BOOL)topBarNormalTintColorEnabled { return [[_preferences objectForKey:@"topBarNormalTintColorEnabled"] boolValue]; }
- (BOOL)topBarNormalBackgroundColorEnabled { return [[_preferences objectForKey:@"topBarNormalBackgroundColorEnabled"] boolValue]; }
- (BOOL)topBarNormalStatusBarStyleEnabled { return [[_preferences objectForKey:@"topBarNormalStatusBarStyleEnabled"] boolValue]; }
- (UIStatusBarStyle)topBarNormalStatusBarStyle { return [[_preferences objectForKey:@"topBarNormalStatusBarStyle"] intValue]; }
- (BOOL)topBarNormalTabBarTitleColorEnabled { return [[_preferences objectForKey:@"topBarNormalTabBarTitleColorEnabled"] boolValue]; }
- (CGFloat)topBarNormalTabBarInactiveTitleOpacity { return [[_preferences objectForKey:@"topBarNormalTabBarInactiveTitleOpacity"] floatValue]; }
- (BOOL)topBarNormalURLFontColorEnabled { return [[_preferences objectForKey:@"topBarNormalURLFontColorEnabled"] boolValue]; }
- (BOOL)topBarNormalProgressBarColorEnabled { return [[_preferences objectForKey:@"topBarNormalProgressBarColorEnabled"] boolValue]; }
- (BOOL)topBarNormalLockIconColorEnabled { return [[_preferences objectForKey:@"topBarNormalLockIconColorEnabled"] boolValue]; }
- (BOOL)topBarNormalReloadButtonColorEnabled { return [[_preferences objectForKey:@"topBarNormalReloadButtonColorEnabled"] boolValue]; }
- (BOOL)bottomBarNormalTintColorEnabled { return [[_preferences objectForKey:@"bottomBarNormalTintColorEnabled"] boolValue]; }
- (BOOL)bottomBarNormalBackgroundColorEnabled { return [[_preferences objectForKey:@"bottomBarNormalBackgroundColorEnabled"] boolValue]; }
- (BOOL)tabTitleBarNormalTextColorEnabled { return [[_preferences objectForKey:@"tabTitleBarNormalTextColorEnabled"] boolValue]; }
- (BOOL)tabTitleBarNormalBackgroundColorEnabled { return [[_preferences objectForKey:@"tabTitleBarNormalBackgroundColorEnabled"] boolValue]; }

- (BOOL)topBarPrivateTintColorEnabled { return [[_preferences objectForKey:@"topBarPrivateTintColorEnabled"] boolValue]; }
- (BOOL)topBarPrivateBackgroundColorEnabled { return [[_preferences objectForKey:@"topBarPrivateBackgroundColorEnabled"] boolValue]; }
- (BOOL)topBarPrivateStatusBarStyleEnabled { return [[_preferences objectForKey:@"topBarPrivateStatusBarStyleEnabled"] boolValue]; }
- (UIStatusBarStyle)topBarPrivateStatusBarStyle { return [[_preferences objectForKey:@"topBarPrivateStatusBarStyle"] intValue]; }
- (BOOL)topBarPrivateTabBarTitleColorEnabled { return [[_preferences objectForKey:@"topBarPrivateTabBarTitleColorEnabled"] boolValue]; }
- (CGFloat)topBarPrivateTabBarInactiveTitleOpacity { return [[_preferences objectForKey:@"topBarPrivateTabBarInactiveTitleOpacity"] floatValue]; }
- (BOOL)topBarPrivateURLFontColorEnabled { return [[_preferences objectForKey:@"topBarPrivateURLFontColorEnabled"] boolValue]; }
- (BOOL)topBarPrivateProgressBarColorEnabled { return [[_preferences objectForKey:@"topBarPrivateProgressBarColorEnabled"] boolValue]; }
- (BOOL)topBarPrivateLockIconColorEnabled { return [[_preferences objectForKey:@"topBarPrivateLockIconColorEnabled"] boolValue]; }
- (BOOL)topBarPrivateReloadButtonColorEnabled { return [[_preferences objectForKey:@"topBarPrivateReloadButtonColorEnabled"] boolValue]; }
- (BOOL)bottomBarPrivateTintColorEnabled { return [[_preferences objectForKey:@"bottomBarPrivateTintColorEnabled"] boolValue]; }
- (BOOL)bottomBarPrivateBackgroundColorEnabled { return [[_preferences objectForKey:@"bottomBarPrivateBackgroundColorEnabled"] boolValue]; }
- (BOOL)tabTitleBarPrivateTextColorEnabled { return [[_preferences objectForKey:@"tabTitleBarPrivateTextColorEnabled"] boolValue]; }
- (BOOL)tabTitleBarPrivateBackgroundColorEnabled { return [[_preferences objectForKey:@"tabTitleBarPrivateBackgroundColorEnabled"] boolValue]; }

#endif

#endif

#endif

- (BOOL)isURLOnHTTPSExceptionsList:(NSURL*)URL
{
	if(!URL || !self.forceHTTPSExceptions)
	{
		return NO;
	}

	for(NSString* exception in self.forceHTTPSExceptions)
	{
		if([[URL host] containsString:exception])
		{
			//Exception list contains host -> return true
			return YES;
		}
	}

	return NO;
}

#if !defined(NO_CEPHEI) || defined(SIMJECT)

- (void)addURLToHTTPSExceptionsList:(NSURL*)URL
{
	if(!URL || !self.forceHTTPSExceptions)
	{
		return;
	}

	NSMutableArray* forceHTTPSExceptionsM = [self.forceHTTPSExceptions mutableCopy];

	NSString* host = [URL host];

	if([host hasPrefix:@"www."])
	{
		host = [host stringByReplacingCharactersInRange:NSMakeRange(0,4) withString:@""];
	}

	[forceHTTPSExceptionsM addObject:host];

	#ifndef SIMJECT
	[_preferences setObject:[forceHTTPSExceptionsM copy] forKey:@"forceHTTPSExceptions"];
	#else
	_forceHTTPSExceptions = [forceHTTPSExceptionsM copy];
	#endif
}

- (void)removeURLFromHTTPSExceptionsList:(NSURL*)URL
{
	if(!URL || !self.forceHTTPSExceptions)
	{
		return;
	}

	NSMutableArray* forceHTTPSExceptionsM = [self.forceHTTPSExceptions mutableCopy];

	for(NSString* exception in forceHTTPSExceptionsM)
	{
		if([[URL host] containsString:exception])
		{
			[forceHTTPSExceptionsM removeObject:exception];
			break;
		}
	}

	#ifndef SIMJECT
	[_preferences setObject:[forceHTTPSExceptionsM copy] forKey:@"forceHTTPSExceptions"];
	#else
	_forceHTTPSExceptions = [forceHTTPSExceptionsM copy];
	#endif
}

#else

- (void)addURLToHTTPSExceptionsList:(NSURL*)URL { }

- (void)removeURLFromHTTPSExceptionsList:(NSURL*)URL { }

#endif

#if defined(NO_LIBCSCOLORPICKER)

- (BOOL)topBarNormalTintColorEnabled { return NO; }
- (UIColor*)topBarNormalTintColor { return nil; }
- (BOOL)topBarNormalBackgroundColorEnabled { return NO; }
- (UIColor*)topBarNormalBackgroundColor { return nil; }
- (BOOL)topBarNormalURLFontColorEnabled { return NO; }
- (UIColor*)topBarNormalURLFontColor { return nil; }
- (BOOL)topBarNormalProgressBarColorEnabled { return NO; }
- (UIColor*)topBarNormalProgressBarColor { return nil; }
- (BOOL)topBarNormalLockIconColorEnabled { return NO; }
- (UIColor*)topBarNormalLockIconColor { return nil; }
- (BOOL)topBarNormalReloadButtonColorEnabled { return NO; }
- (UIColor*)topBarNormalReloadButtonColor { return nil; }
- (BOOL)topBarNormalTabBarTitleColorEnabled { return NO; }
- (UIColor*)topBarNormalTabBarTitleColor { return nil; }
- (BOOL)bottomBarNormalTintColorEnabled { return NO; }
- (UIColor*)bottomBarNormalTintColor {  return nil;}
- (BOOL)bottomBarNormalBackgroundColorEnabled { return NO; }
- (UIColor*)bottomBarNormalBackgroundColor { return nil; }
- (BOOL)tabTitleBarNormalTextColorEnabled { return NO; }
- (UIColor*)tabTitleBarNormalTextColor { return nil; }
- (BOOL)tabTitleBarNormalBackgroundColorEnabled { return NO; }
- (UIColor*)tabTitleBarNormalBackgroundColor { return nil; }

- (BOOL)topBarPrivateTintColorEnabled { return NO; }
- (UIColor*)topBarPrivateTintColor { return nil; }
- (BOOL)topBarPrivateBackgroundColorEnabled { return NO; }
- (UIColor*)topBarPrivateBackgroundColor { return nil; }
- (BOOL)topBarPrivateURLFontColorEnabled { return NO; }
- (UIColor*)topBarPrivateURLFontColor { return nil; }
- (BOOL)topBarPrivateProgressBarColorEnabled { return NO; }
- (UIColor*)topBarPrivateProgressBarColor { return nil; }
- (BOOL)topBarPrivateLockIconColorEnabled { return NO; }
- (UIColor*)topBarPrivateLockIconColor { return nil; }
- (BOOL)topBarPrivateReloadButtonColorEnabled { return NO; }
- (UIColor*)topBarPrivateReloadButtonColor { return nil; }
- (BOOL)topBarPrivateTabBarTitleColorEnabled { return NO; }
- (UIColor*)topBarPrivateTabBarTitleColor { return nil; }
- (BOOL)bottomBarPrivateTintColorEnabled { return NO; }
- (UIColor*)bottomBarPrivateTintColor {  return nil;}
- (BOOL)bottomBarPrivateBackgroundColorEnabled { return NO; }
- (UIColor*)bottomBarPrivateBackgroundColor { return nil; }
- (BOOL)tabTitleBarPrivateTextColorEnabled { return NO; }
- (UIColor*)tabTitleBarPrivateTextColor { return nil; }
- (BOOL)tabTitleBarPrivateBackgroundColorEnabled { return NO; }
- (UIColor*)tabTitleBarPrivateBackgroundColor { return nil; }

#endif

@end
