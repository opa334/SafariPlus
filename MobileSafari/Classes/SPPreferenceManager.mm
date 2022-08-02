// Copyright (c) 2017-2022 Lars Fröder

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

#import "SPPreferenceManager.h"

#import "../Defines.h"
#import "../Util.h"
#import "../Enums.h"
#import "Simulator.h"
#import "../SafariPlus.h"
#import <libSandy.h>

#ifndef NO_LIBCSCOLORPICKER
#import <CSColorPicker/CSColorPicker.h>
#endif

#import <Cephei/HBPreferences.h>

void reloadPreferences()
{
	[preferenceManager reloadPreferences];
}

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

- (NSUserDefaults*)userDefaults
{
	return _userDefaults;
}

- (NSDictionary*)preferencesDictionary
{
#if defined SIMJECT
	return [NSDictionary dictionaryWithContentsOfFile:rPath(@"/var/mobile/Library/Preferences/com.opa334.safariplusprefs.plist")];
#endif
	return [_userDefaults dictionaryRepresentation];
}

- (void)reloadPreferences
{
	[self reloadPreferencesFromDictionary:[self preferencesDictionary]];
}

- (void)reloadPreferencesFromDictionary:(NSDictionary*)prefDict
{
	for(NSString* key in [prefDict allKeys])
	{
		id value = [prefDict objectForKey:key];
		NSString* ivarName = [@"_" stringByAppendingString:key];

		@try
		{
			[self setValue:value forKey:key];
		}
		@catch(NSException* e)
		{
			HBLogDebugWeak(@"exception while reloading preferences: %@", e);
		}
	}
}

- (id)init
{
	self = [super init];

	NSDictionary* defaults = @
	{
		@"tweakEnabled" : @YES,

		//@"forceHTTPSEnabled" : @NO,
		//@"lockedTabsEnabled" : @NO,
		//@"biometricProtectionEnabled" : @NO,
		//@"biometricProtectionSwitchModeEnabled" : @NO,
		//@"biometricProtectionSwitchModeAllowAutomaticActionsEnabled" : @NO,
		//@"biometricProtectionLockTabEnabled" : @NO,
		//@"biometricProtectionUnlockTabEnabled" : @NO,
		//@"biometricProtectionAccessLockedTabEnabled" : @NO,
		//@"biometricProtectionOpenDownloadsEnabled" : @NO,

		//@"uploadAnyFileOptionEnabled" : @NO,
		//@"downloadManagerEnabled" : @NO,
		//@"videoDownloadingEnabled" : @NO,
		@"videoDownloadingUseTabTitleAsFilenameEnabled" : @YES,
		@"downloadSiteToActionEnabled" : @YES,
		@"downloadImageToActionEnabled" : @YES,
		//@"customDefaultPathEnabled" : @NO,
		@"customDefaultPath" : DEFAULT_DOWNLOAD_PATH,
		//@"pinnedLocationsEnabled" : @NO,
		//@"pinnedLocations" : nil,
		@"previewDownloadProgressEnabled" : @YES,
		//@"defaultDownloadSection" : @0,
		//@"defaultDownloadSectionAutoSwitchEnabled" : @NO,
		//@"instantDownloadsEnabled" : @NO,
		//@"instantDownloadsOption" : @NO,
		//@"onlyDownloadOnWifiEnabled" : @NO,
		//@"autosaveToMediaLibraryEnabled" : @NO,
		//@"privateModeDownloadHistoryDisabled"NO,
		@"pushNotificationsEnabled" : @YES,
		@"statusBarNotificationsEnabled" : @YES,
		@"applicationBadgeEnabled" : @YES,

		//@"bothTabOpenActionsEnabled" : @NO,
		//@"openInOppositeModeOptionEnabled" : @NO,
		//@"desktopButtonEnabled" : @NO,
		//@"tabManagerEnabled" : @NO,
		//@"tabManagerScrollPositionFromTabSwitcherEnabled" : @NO,
		//@"disableTabLimit" : @NO,
		//@"alwaysOpenNewTabEnabled" : @NO,
		//@"alwaysOpenNewTabInBackgroundEnabled" : @NO,
		//@"disablePrivateMode" : @NO,
		//@"longPressSuggestionsEnabled" : @NO,
		@"longPressSuggestionsDuration" : @1,
		@"longPressSuggestionsFocusEnabled" : @YES,
		//@"suggestionInsertButtonEnabled" : @NO,
		//@"showTabCountEnabled" : @NO,
		//@"fullscreenScrollingEnabled" : @NO,
		//@"lockBars" : @NO,
		//@"showFullSiteURLEnabled" : @NO,
		//@"forceNativePlayerEnabled" : @NO,
		//@"suppressMailToDialog" : @NO,

		//@"forceModeOnStartEnabled" : @NO,
		//@"forceModeOnStartFor" : @0,
		//@"forceModeOnResumeEnabled" : @NO,
		//@"forceModeOnResumeFor" : @0,
		//@"forceModeOnExternalLinkEnabled" : @NO,
		//@"forceModeOnExternalLinkFor" : @0,
		//@"autoCloseTabsEnabled" : @NO,
		//@"autoCloseTabsOn" : @0,
		//@"autoCloseTabsFor" : @0,
		//@"autoDeleteDataEnabled" : @NO,
		//@"autoDeleteDataOn" : @0,

		//@"URLLeftSwipeGestureEnabled" : @NO,
		//@"URLLeftSwipeAction" : @0,
		//@"URLRightSwipeGestureEnabled" : @NO,
		//@"URLRightSwipeAction" : @0,
		//@"URLDownSwipeGestureEnabled" : @NO,
		//@"URLDownSwipeAction" : @0,
		//@"toolbarLeftSwipeGestureEnabled" : @NO,
		//@"toolbarLeftSwipeAction" : @0,
		//@"toolbarRightSwipeGestureEnabled" : @NO,
		//@"toolbarRightSwipeAction" : @0,
		//@"toolbarUpDownSwipeGestureEnabled" : @NO,
		//@"toolbarUpDownSwipeAction" : @0,
		//@"gesturesInTabSwitcherEnabled" : @NO,
		//@"gestureActionsInBackgroundEnabled" : @NO,

		//@"topBarNormalTintColorEnabled" : @NO,
		//@"topBarNormalTintColor" : nil,
		//@"topBarNormalBackgroundColorEnabled" : @NO,
		//@"topBarNormalBackgroundColor" : nil,
		@"topBarNormalStatusBarStyleEnabled" : @(UIStatusBarStyleDefault),
		//@"topBarNormalStatusBarStyle" : @NO,
		//@"topBarNormalReaderButtonColorEnabled" : @NO,
		//@"topBarNormalReaderButtonColor" : nil,
		//@"topBarNormalLockIconColorEnabled" : @NO,
		//@"topBarNormalLockIconColor" : nil,
		//@"topBarNormalURLFontColorEnabled" : @NO,
		//@"topBarNormalURLFontColor" : nil,
		//@"topBarNormalReloadButtonColorEnabled" : @NO,
		//@"topBarNormalReloadButtonColor" : nil,
		//@"topBarNormalProgressBarColorEnabled" : @NO,
		//@"topBarNormalProgressBarColor" : nil,
		//@"topBarNormalTabBarCloseButtonColorEnabled" : @NO,
		//@"topBarNormalTabBarCloseButtonColor" : nil,
		//@"topBarNormalTabBarTitleColorEnabled" : @NO,
		//@"topBarNormalTabBarTitleColor" : nil,
		@"topBarNormalTabBarInactiveTitleOpacity" : @0.4,
		//@"bottomBarNormalTintColorEnabled" : @NO,
		//@"bottomBarNormalTintColor" : nil,
		//@"bottomBarNormalBackgroundColorEnabled" : @NO,
		//@"bottomBarNormalBackgroundColor" : nil,
		//@"tabTitleBarNormalTextColorEnabled" : @NO,
		//@"tabTitleBarNormalTextColor" nil,
		//@"tabTitleBarNormalBackgroundColorEnabled" : @NO,
		//@"tabTitleBarNormalBackgroundColor" nil,
		//@"tabSwitcherNormalToolbarBackgroundColorEnabled" : @NO,
		//@"tabSwitcherNormalToolbarBackgroundColor" nil,

		//@"topBarPrivateTintColorEnabled" : @NO,
		//@"topBarPrivateTintColor" nil,
		//@"topBarPrivateBackgroundColorEnabled" : @NO,
		//@"topBarPrivateBackgroundColor" nil,
		@"topBarPrivateStatusBarStyleEnabled" : @(UIStatusBarStyleDefault),
		//@"topBarPrivateStatusBarStyle" : @NO,
		//@"topBarPrivateReaderButtonColorEnabled" : @NO,
		//@"topBarPrivateReaderButtonColor" nil,
		//@"topBarPrivateLockIconColorEnabled" : @NO,
		//@"topBarPrivateLockIconColor" nil,
		//@"topBarPrivateURLFontColorEnabled" : @NO,
		//@"topBarPrivateURLFontColor" : nil,
		//@"topBarPrivateReloadButtonColorEnabled" : @NO,
		//@"topBarPrivateReloadButtonColor" : nil,
		//@"topBarPrivateProgressBarColorEnabled" : @NO,
		//@"topBarPrivateProgressBarColor" : nil,
		//@"topBarPrivateTabBarCloseButtonColorEnabled" : @NO,
		//@"topBarPrivateTabBarCloseButtonColor" : nil,
		//@"topBarPrivateTabBarTitleColorEnabled" : @NO,
		//@"topBarPrivateTabBarTitleColor" : nil,
		@"topBarPrivateTabBarInactiveTitleOpacity" : @0.2,
		//@"bottomBarPrivateTintColorEnabled" : @NO,
		//@"bottomBarPrivateTintColor" : nil,
		//@"bottomBarPrivateBackgroundColorEnabled" : @NO,
		//@"bottomBarPrivateBackgroundColor" : nil,
		//@"tabTitleBarPrivateTextColorEnabled" : @NO,
		//@"tabTitleBarPrivateTextColor" : nil,
		//@"tabTitleBarPrivateBackgroundColorEnabled" : @NO,
		//@"tabTitleBarPrivateBackgroundColor" : nil,
		//@"tabSwitcherPrivateToolbarBackgroundColorEnabled" : @NO,
		//@"tabSwitcherPrivateToolbarBackgroundColor" : nil,

		@"topBarNormalLightTabBarInactiveTitleOpacity" : @0.4,
		@"topBarPrivateLightTabBarInactiveTitleOpacity" : @0.4,
		@"topBarNormalDarkTabBarInactiveTitleOpacity" : @0.2,
		@"topBarPrivateDarkTabBarInactiveTitleOpacity" : @0.2,

		//@"topToolbarCustomOrderEnabled" : @NO,
		@"topToolbarCustomOrder" : @[@(BrowserToolbarBackItem),@(BrowserToolbarForwardItem),@(BrowserToolbarBookmarksItem),@(BrowserToolbarSearchBarSpace),@(BrowserToolbarShareItem),@(BrowserToolbarAddTabItem),@(BrowserToolbarTabExposeItem)],
		//@"bottomToolbarCustomOrderEnabled" : @NO,
		@"bottomToolbarCustomOrder" : @[@(BrowserToolbarBackItem),@(BrowserToolbarForwardItem),@(BrowserToolbarShareItem),@(BrowserToolbarBookmarksItem),@(BrowserToolbarTabExposeItem)],

		//@"customStartSiteEnabled" : @NO,
		//@"customStartSite" : nil,
		//@"customSearchEngineEnabled" : @NO,
		@"customSearchEngineName" : @"",
		@"customSearchEngineURL" : @"",
		@"customSearchEngineSuggestionsURL" : @"",
		//@"customUserAgentEnabled" : @NO,
		@"customUserAgent" : @"",
		//@"customDesktopUserAgentEnabled" : @NO,
		@"customDesktopUserAgent" : @"",

		//@"largeTitlesEnabled" : @NO,
		//@"sortDirectoriesAboveFiles" : @NO,
		//@"pullUpToRefreshDisabled" : @NO,
	};

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0)
	{
		int ret = libSandy_applyProfile("SafariPlus_Preferences");
		if(ret == kLibSandyErrorXPCFailure)
		{
			libSandyWorks = NO;
		}

		//int denied = sandbox_check(getpid(), "user-preference-write", SANDBOX_FILTER_PATH | SANDBOX_CHECK_NO_REPORT, "com.opa334.safariplusprefs");
		//NSLog(@"libSandy user pref write: %d", denied);

		//_userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.opa334.safariplusprefs"];
		_userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"/var/mobile/Library/Preferences/com.opa334.safariplusprefs.plist"];
		[_userDefaults registerDefaults:defaults];
	}
	else
	{
		NSBundle* cepheiBundle = [NSBundle bundleWithPath:@"/Library/Frameworks/Cephei.framework"];
		[cepheiBundle load];

		// this works because HBPreferences method signatures are somewhat similar to the ones of NSUserDefaults
		_userDefaults = (NSUserDefaults*)[[NSClassFromString(@"HBPreferences") alloc] initWithIdentifier:PREFERENCE_DOMAIN_NAME];
		[self reloadPreferencesFromDictionary:defaults];
	}

	[self reloadPreferences];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadPreferences, CFSTR("com.opa334.safariplusprefs/ReloadPrefs"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

	return self;
}

- (BOOL)unsandboxSafariEnabled
{
	return ![[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/Preferences/com.opa334.safariplusprefs.force_sandbox"];
}

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

- (void)addURLToHTTPSExceptionsList:(NSURL*)URL
{
	if(!URL)
	{
		return;
	}

	if(!_forceHTTPSExceptions)
	{
		_forceHTTPSExceptions = [NSArray new];
	}

	NSMutableArray* forceHTTPSExceptionsM = [_forceHTTPSExceptions mutableCopy];

	NSString* host = [URL host];

	if([host hasPrefix:@"www."])
	{
		host = [host stringByReplacingCharactersInRange:NSMakeRange(0,4) withString:@""];
	}

	[forceHTTPSExceptionsM addObject:host];

	_forceHTTPSExceptions = [forceHTTPSExceptionsM copy];

	[_userDefaults setObject:_forceHTTPSExceptions forKey:@"forceHTTPSExceptions"];
}

- (void)removeURLFromHTTPSExceptionsList:(NSURL*)URL
{
	if(!URL || !self.forceHTTPSExceptions)
	{
		return;
	}

	NSMutableArray* forceHTTPSExceptionsM = [_forceHTTPSExceptions mutableCopy];

	for(NSString* exception in forceHTTPSExceptionsM)
	{
		if([[URL host] containsString:exception])
		{
			[forceHTTPSExceptionsM removeObject:exception];
			break;
		}
	}

	_forceHTTPSExceptions = [forceHTTPSExceptionsM copy];

	[_userDefaults setObject:_forceHTTPSExceptions forKey:@"forceHTTPSExceptions"];
}

@end
