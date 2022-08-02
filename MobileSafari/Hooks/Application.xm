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

#import "../SafariPlus.h"

#import "../Util.h"
#import "../Defines.h"
#import "../Classes/SPDownloadManager.h"
#import "../Classes/SPPreferenceManager.h"
#import "../Classes/SPLocalizationManager.h"
#import "../Classes/SPCacheManager.h"
#import "../Shared/SPPreferenceUpdater.h"
#import <libundirect/libundirect_dynamic.h>
#import "../Classes/SPFileManager.h"

#import <UserNotifications/UserNotifications.h>

%hook Application

%property (nonatomic,assign) BOOL sp_isSetUp;
%property (nonatomic,retain) NSDictionary* sp_storedLaunchOptions;

%new
- (void)sp_preAppLaunch
{
	#ifndef SIMJECT
	[SPPreferenceUpdater update];
	#endif
}

%new
- (void)sp_postAppLaunchWithOptions:(NSDictionary*)launchOptions
{
	self.sp_storedLaunchOptions = launchOptions;

	[self sp_setUpIfReady];
}

%new
- (void)sp_setUpIfReady
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^
	{
		self.sp_isSetUp = NO;
	});

	if(browserControllers().firstObject && !self.sp_isSetUp)
	{
		[fileManager populateApplicationDisplayNamesForPath];

		if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_13_0)
		{
			//Auto switch mode on launch
			if(preferenceManager.forceModeOnStartEnabled && !self.sp_storedLaunchOptions[UIApplicationLaunchOptionsURLKey])
			{
				for(BrowserController* controller in browserControllers())
				{
					//Switch mode to specified mode
					[controller modeSwitchAction:preferenceManager.forceModeOnStartFor];
				}
			}
		}

		if(preferenceManager.lockedTabsEnabled)
		{
			[cacheManager cleanUpTabStateAdditions];
		}

		[self sp_handleTwitterAlert];

		[self sp_handleLibSandyCheck];

		if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_14_0)
		{
			NSArray* failedSelectors = libundirect_failedSelectors();
			if(failedSelectors)
			{
				NSMutableString* selectorsString = [NSMutableString string];
				for(NSString* failedSelector in failedSelectors)
				{
					[selectorsString appendString:failedSelector];
					if(failedSelector != failedSelectors.lastObject)
					{
						[selectorsString appendString:@"\n"];
					}
				}

				#ifdef __arm64e__
				NSString* arch = @"arm64e";
				#else
				NSString* arch = @"arm64";
				#endif

				sendSimpleAlert([localizationManager localizedSPStringForKey:@"UNDIRECTOR_WARNING"], [NSString stringWithFormat:[localizationManager localizedSPStringForKey:@"UNDIRECTOR_WARNING_MESSAGE"], [[UIDevice currentDevice] systemVersion], arch, selectorsString]);
			}
		}

		if(preferenceManager.downloadManagerEnabled)
		{
			downloadManager = [SPDownloadManager sharedInstance];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"SPDownloadManagerDidInitNotification" object:nil];

			if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0)
			{
				UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
				UNAuthorizationOptions options = UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge;
				[center requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError* _Nullable error){}];
			}
			else
			{
				UIUserNotificationSettings* settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert) categories:nil];
				[self registerUserNotificationSettings:settings];
			}
		}

		if(!preferenceManager.applicationBadgeEnabled && self.applicationIconBadgeNumber > 0)
		{
			self.applicationIconBadgeNumber = 0;
		}

		self.sp_isSetUp = YES;
		self.sp_storedLaunchOptions = nil;
	}
	else
	{
		[[NSNotificationCenter defaultCenter] addObserver:self
							 selector:@selector(sp_setUpIfReady)
							     name:UISceneWillConnectNotification
							   object:nil];
	}
}

%new
- (void)sp_handleTwitterAlert
{
	if([cacheManager firstStart])
	{
		BrowserController* browserController = browserControllers().firstObject;

		UIAlertController* welcomeAlert = [UIAlertController alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"WELCOME_TITLE"]
										      message:[localizationManager localizedSPStringForKey:@"WELCOME_MESSAGE"]
									       preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction* closeAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CLOSE"]
								      style:UIAlertActionStyleDefault
								    handler:nil];

		UIAlertAction* openAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"OPEN_TWITTER"]
								     style:UIAlertActionStyleDefault
								   handler:^(UIAlertAction* action)
		{
			//Twitter is installed as an application
			if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]])
			{
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitter://user?screen_name=opa334dev"]];
			}
			//Twitter is not installed, open web page
			else
			{
				NSURL* twitterURL = [NSURL URLWithString:@"https://twitter.com/opa334dev"];

				if([browserController respondsToSelector:@selector(loadURLInNewTab:inBackground:animated:)])
				{
					[browserController loadURLInNewTab:twitterURL inBackground:NO animated:YES];
				}
				else
				{
					[browserController loadURLInNewWindow:twitterURL inBackground:NO animated:YES];
				}
			}
		}];

		[welcomeAlert addAction:closeAction];
		[welcomeAlert addAction:openAction];

		if([welcomeAlert respondsToSelector:@selector(preferredAction)])
		{
			welcomeAlert.preferredAction = openAction;
		}

		[cacheManager firstStartDidSucceed];

		dispatch_async(dispatch_get_main_queue(), ^
		{
			[rootViewControllerForBrowserController(browserController) presentViewController:welcomeAlert animated:YES completion:nil];
		});
	}
}

%new
- (void)sp_handleLibSandyCheck
{
	if(!libSandyWorks)
	{
		sendSimpleAlert([localizationManager localizedSPStringForKey:@"UNSANDBOX_ERROR"], [localizationManager localizedSPStringForKey:@"UNSANDBOX_ERROR_DESCRIPTION"]);
	}
}

%new
- (void)application:(UIApplication*)application handleEventsForBackgroundURLSession:(NSString*)identifier completionHandler:(void (^)())completionHandler
{
	downloadManager.applicationBackgroundSessionCompletionHandler = completionHandler;
}

%new
- (void)sp_applicationWillEnterForeground
{
	if(preferenceManager.forceModeOnResumeEnabled)
	{
		for(BrowserController* controller in browserControllers())
		{
			//Switch mode to specified mode
			[controller modeSwitchAction:preferenceManager.forceModeOnResumeFor];
		}
	}
}

//Auto switch mode on app resume
- (void)applicationWillEnterForeground:(id)arg1	//iOS 12 and down
{
	%orig;
	[self sp_applicationWillEnterForeground];
}

- (void)_applicationWillEnterForeground:(id)arg1 //iOS 13 and up
{
	%orig;
	[self sp_applicationWillEnterForeground];
}

//Auto close tabs when Safari gets closed
- (void)applicationWillTerminate
{
	if(preferenceManager.autoCloseTabsEnabled &&
	   preferenceManager.autoCloseTabsOn == 1 /*Safari closed*/)
	{
		for(BrowserController* controller in browserControllers())
		{
			//Close all tabs for specified modes
			[controller autoCloseAction];
		}
	}

	if(preferenceManager.autoDeleteDataEnabled &&
	   preferenceManager.autoDeleteDataOn == 1 /*Safari closed*/)
	{
		for(BrowserController* controller in browserControllers())
		{
			//Clear browser data
			[controller clearData];
		}
	}

	%orig;
}

%new
- (void)sp_applicationDidEnterBackground
{
	if(preferenceManager.autoCloseTabsEnabled &&
	   preferenceManager.autoCloseTabsOn == 2 /*Safari minimized*/)
	{
		for(BrowserController* controller in browserControllers())
		{
			//Close all tabs for specified modes
			[controller autoCloseAction];
		}
	}

	if(preferenceManager.autoDeleteDataEnabled &&
	   preferenceManager.autoDeleteDataOn == 2 /*Safari closed*/)
	{
		for(BrowserController* controller in browserControllers())
		{
			//Clear browser data
			[controller clearData];
		}
	}
}

//Auto close tabs when Safari gets minimized
- (void)applicationDidEnterBackground:(id)arg1	//iOS 12 and down
{
	[self sp_applicationDidEnterBackground];

	%orig;
}

- (void)_applicationDidEnterBackground:(id)arg1	//iOS 13 and up
{
	[self sp_applicationDidEnterBackground];

	%orig;
}

%group iOS10Up

- (BOOL)canAddNewTabForPrivateBrowsing:(BOOL)privateBrowsing
{
	if(preferenceManager.disableTabLimit)
	{
		return YES;
	}

	return %orig;
}

%end

%group iOS9Up

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
	[self sp_preAppLaunch];

	BOOL orig = %orig;

	[self sp_postAppLaunchWithOptions:launchOptions];

	return orig;
}

%end

%group iOS8

- (void)applicationOpenURL:(NSURL*)URL
{
	if(preferenceManager.forceModeOnExternalLinkEnabled && URL)
	{
		//Switch mode to specified mode
		[browserControllers().firstObject modeSwitchAction:preferenceManager.forceModeOnExternalLinkFor];
	}

	%orig;
}

- (void)applicationDidFinishLaunching:(UIApplication*)application
{
	[self sp_preAppLaunch];

	%orig;

	[self sp_postAppLaunchWithOptions:nil];
}

%end

%end

void initApplication()
{
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0)
	{
		%init(iOS10Up);
	}

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0)
	{
		%init(iOS9Up);
	}
	else
	{
		%init(iOS8);
	}

	%init();
}
