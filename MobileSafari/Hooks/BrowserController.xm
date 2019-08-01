// BrowserController.xm
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

#import "../SafariPlus.h"

#import "../Defines.h"
#import "../Enums.h"
#import "../Util.h"
#import "../Classes/SPLocalizationManager.h"
#import "../Classes/SPPreferenceManager.h"
#import "../Classes/SPDownloadNavigationController.h"
#import "../Classes/SPTabManagerTableViewController.h"

%hook BrowserController

//Properties for gesture recognizers
%property (nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeLeftGestureRecognizer;
%property (nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeRightGestureRecognizer;
%property (nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeDownGestureRecognizer;

%property (nonatomic, assign) BOOL browsingModeSet;

//Present downloads view
%new
- (void)downloadsFromButtonBar
{
	dispatch_async(dispatch_get_main_queue(), ^
	{
		//Create SPDownloadNavigationController
		SPDownloadNavigationController* downloadsController = [[SPDownloadNavigationController alloc] init];

		//Present SPDownloadNavigationController
		[rootViewControllerForBrowserController(self) presentViewController:downloadsController animated:YES completion:nil];
	});
}

//URL Swipe actions
%new
- (void)handleGesture:(NSInteger)swipeAction
{
	//Some actions need a clean up after being ran
	__block BOOL shouldClean = NO;

	switch(swipeAction)
	{
	case GestureActionCloseActiveTab:
	{
		[self.tabController.activeTabDocument _closeTabDocumentAnimated:NO];
		shouldClean = YES;
		break;
	}

	case GestureActionOpenNewTab:
	{
		if([self.tabController respondsToSelector:@selector(newTab)])
		{
			[self.tabController newTab];
		}
		else	//iOS 8
		{
			[self newTabKeyPressed];
		}
		break;
	}

	case GestureActionDuplicateActiveTab:
	{
		if([self respondsToSelector:@selector(loadURLInNewTab:inBackground:animated:)])
		{
			[self loadURLInNewTab:[self.tabController.activeTabDocument URL]
			 inBackground:preferenceManager.gestureActionsInBackgroundEnabled animated:YES];
		}
		else
		{
			[self loadURLInNewWindow:[self.tabController.activeTabDocument URL]
			 inBackground:preferenceManager.gestureActionsInBackgroundEnabled animated:YES];
		}
		break;
	}

	case GestureActionCloseAllTabs:
	{
		if([self.tabController respondsToSelector:@selector(closeAllOpenTabsAnimated:)])
		{
			[self.tabController closeAllOpenTabsAnimated:NO];
		}
		else
		{
			[self.tabController closeAllOpenTabsAnimated:NO exitTabView:YES];
		}

		shouldClean = YES;
		break;
	}

	case GestureActionSwitchMode:
	{
		if([self isPrivateBrowsingAvailable] || privateBrowsingEnabled(self))
		{
			togglePrivateBrowsing(self);
			shouldClean = YES;
		}
		break;
	}

	case GestureActionSwitchTabBackwards:
	{
		NSArray* activeTabs;

		if(privateBrowsingEnabled(self))
		{
			//Private mode enabled -> set currentTabs to tabs of private mode
			activeTabs = self.tabController.privateTabDocuments;
		}
		else
		{
			//Private mode disabled -> set currentTabs to tabs of normal mode
			activeTabs = self.tabController.tabDocuments;
		}

		//Get index of previous tab
		NSInteger tabIndex = [activeTabs indexOfObject:
				      self.tabController.activeTabDocument] - 1;

		if(tabIndex >= 0)
		{
			//tabIndex is greater than 0 -> switch to previous tab
			[self.tabController setActiveTabDocument:activeTabs[tabIndex] animated:NO];
		}
		break;
	}

	case GestureActionSwitchTabForwards:
	{
		NSArray* activeTabs;

		if(privateBrowsingEnabled(self))
		{
			//Private mode enabled -> set currentTabs to tabs of private mode
			activeTabs = self.tabController.privateTabDocuments;
		}
		else
		{
			//Private mode disabled -> set currentTabs to tabs of normal mode
			activeTabs = self.tabController.tabDocuments;
		}

		//Get index of next tab
		NSInteger tabIndex = [activeTabs indexOfObject:
				      self.tabController.activeTabDocument] + 1;

		if(tabIndex < [activeTabs count])
		{
			//tabIndex is not bigger than array -> switch to next tab
			[self.tabController setActiveTabDocument:activeTabs[tabIndex] animated:NO];
		}
		break;
	}

	case GestureActionReloadActiveTab:
	{
		if(!self.tabController.activeTabDocument.isBlankDocument)
		{
			[self.tabController.activeTabDocument reload];
		}
		break;
	}

	case GestureActionRequestDesktopSite:
	{
		if(!self.tabController.activeTabDocument.isBlankDocument)
		{
			if([self.tabController.activeTabDocument respondsToSelector:@selector(reloadOptionsController)])
			{
				[self.tabController.activeTabDocument.reloadOptionsController requestDesktopSite];
			}
			else
			{
				[self.tabController.activeTabDocument requestDesktopSite];
			}
		}

		break;
	}

	//Not available on iOS 8
	case GestureActionOpenFindOnPage:
	{
		if([self.tabController.activeTabDocument respondsToSelector:@selector(findOnPageView)])
		{
			[self.tabController.activeTabDocument.findOnPageView setShouldFocusTextField:YES];
			[self.tabController.activeTabDocument.findOnPageView showFindOnPage];
		}
		else if([self respondsToSelector:@selector(shouldFocusFindOnPageTextField)])
		{
			self.shouldFocusFindOnPageTextField = YES;
			[self showFindOnPage];
		}
		break;
	}

	default:
		break;
	}

	if(shouldClean && privateBrowsingEnabled(self))
	{
		//Remove private mode message
		if([self.tabController.tiltedTabView respondsToSelector:@selector(setShowsPrivateBrowsingExplanationView:animated:)])
		{
			[self.tabController.tiltedTabView setShowsPrivateBrowsingExplanationView:NO animated:NO];
		}
		else
		{
			[self.tabController.tiltedTabView setShowsExplanationView:NO animated:NO];
		}
	}
}

%new
- (void)clearData
{
	//Clear history
	[self clearHistoryMessageReceived];

	if([self respondsToSelector:@selector(clearAutoFillMessageReceived)])
	{
		//Clear autoFill stuff
		[self clearAutoFillMessageReceived];
	}
}

//Used to close tabs based on the setting
%new
- (void)autoCloseAction
{
	switch(preferenceManager.autoCloseTabsFor)
	{
	case CloseTabActionFromActiveMode:
	{
		closeTabDocuments(self.tabController, self.tabController.currentTabDocuments, NO);
		break;
	}
	case CloseTabActionFromNormalMode:
	{
		closeTabDocuments(self.tabController, self.tabController.tabDocuments, NO);
		break;
	}
	case CloseTabActionFromPrivateMode:
	{
		closeTabDocuments(self.tabController, self.tabController.privateTabDocuments, NO);
		break;
	}
	case CloseTabActionFromBothModes:	//Both modes
	{
		closeTabDocuments(self.tabController, self.tabController.allTabDocuments, NO);
		break;
	}
	}
}

//Used to switch mode based on the setting
%new
- (void)modeSwitchAction:(int)switchToMode
{
	if(preferenceManager.biometricProtectionEnabled && preferenceManager.biometricProtectionSwitchModeEnabled && preferenceManager.biometricProtectionSwitchModeAllowAutomaticActionsEnabled)
	{
		skipBiometricProtectionOnce = YES;
	}

	if(switchToMode == ModeSwitchActionNormalMode)
	{
		//Switch to normal browsing mode
		setPrivateBrowsing(self, NO, nil);
	}
	else if(switchToMode == ModeSwitchActionPrivateMode && [self isPrivateBrowsingAvailable])
	{
		//Switch to private browsing mode
		setPrivateBrowsing(self, YES, nil);

		//Hide private mode notice
		if([self.tabController.tiltedTabView respondsToSelector:@selector(setShowsPrivateBrowsingExplanationView:animated:)])
		{
			[self.tabController.tiltedTabView setShowsPrivateBrowsingExplanationView:NO animated:NO];
		}
		else
		{
			[self.tabController.tiltedTabView setShowsExplanationView:NO animated:NO];
		}
	}

	skipBiometricProtectionOnce = NO;
}

//Full screen scrolling
- (BOOL)_isVerticallyConstrained
{
	return (preferenceManager.fullscreenScrollingEnabled) ? YES : %orig;
}

//Fully disable private mode
- (BOOL)isPrivateBrowsingAvailable
{
	return (preferenceManager.disablePrivateMode) ? NO : %orig;
}


- (BOOL)dynamicBarAnimator:(id)arg1 canHideBarsByDraggingWithOffset:(CGFloat)arg2
{
	return (preferenceManager.lockBars) ? NO : %orig;
}

- (void)tabControllerDocumentCountDidChange:(TabController*)tabController
{
	%orig;

	if(preferenceManager.showTabCountEnabled)
	{
		[activeToolbarForBrowserController(self) updateTabCount];
	}

	if(preferenceManager.tabManagerEnabled && tabController.presentedTabManager)
	{
		[(SPTabManagerTableViewController*) tabController.presentedTabManager.viewControllers.firstObject reloadAnimated:YES];
	}
}

- (void)_initSubviews
{
	%orig;
	if(preferenceManager.URLLeftSwipeGestureEnabled || preferenceManager.URLRightSwipeGestureEnabled
	   || preferenceManager.URLDownSwipeGestureEnabled)
	{
		_SFNavigationBarURLButton* URLButton = MSHookIvar<_SFNavigationBarURLButton*>(navigationBarForBrowserController(self), "_URLOutline");

		if(preferenceManager.URLLeftSwipeGestureEnabled && !self.URLBarSwipeLeftGestureRecognizer)
		{
			//Create gesture recognizer
			self.URLBarSwipeLeftGestureRecognizer = [[UISwipeGestureRecognizer alloc]
								 initWithTarget:self action:@selector(navigationBarURLWasSwiped:)];

			//Set swipe direction to left
			self.URLBarSwipeLeftGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;

			//Add gestureRecognizer
			[URLButton addGestureRecognizer:self.URLBarSwipeLeftGestureRecognizer];
		}

		if(preferenceManager.URLRightSwipeGestureEnabled && !self.URLBarSwipeRightGestureRecognizer)
		{
			//Create gesture recognizer
			self.URLBarSwipeRightGestureRecognizer = [[UISwipeGestureRecognizer alloc]
								  initWithTarget:self action:@selector(navigationBarURLWasSwiped:)];

			//Set swipe direction to right
			self.URLBarSwipeRightGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;

			//Add gestureRecognizer
			[URLButton addGestureRecognizer:self.URLBarSwipeRightGestureRecognizer];
		}

		if(preferenceManager.URLDownSwipeGestureEnabled && !self.URLBarSwipeDownGestureRecognizer)
		{
			//Create gesture recognizer
			self.URLBarSwipeDownGestureRecognizer = [[UISwipeGestureRecognizer alloc]
								 initWithTarget:self action:@selector(navigationBarURLWasSwiped:)];

			//Set swipe direction to down
			self.URLBarSwipeDownGestureRecognizer.direction = UISwipeGestureRecognizerDirectionDown;

			//Add gestureRecognizer
			[URLButton addGestureRecognizer:self.URLBarSwipeDownGestureRecognizer];
		}
	}
}

//Call method based on the direction of the url bar swipe
%new
- (void)navigationBarURLWasSwiped:(UISwipeGestureRecognizer*)swipe
{
	switch(swipe.direction)
	{
	case UISwipeGestureRecognizerDirectionLeft:
	{
		//Bar swiped left -> handle swipe
		[self handleGesture:preferenceManager.URLLeftSwipeAction];
		break;
	}

	case UISwipeGestureRecognizerDirectionRight:
	{
		//Bar swiped right -> handle swipe
		[self handleGesture:preferenceManager.URLRightSwipeAction];
		break;
	}

	case UISwipeGestureRecognizerDirectionDown:
	{
		//Bar swiped down -> handle swipe
		[self handleGesture:preferenceManager.URLDownSwipeAction];
		break;
	}
	}
}

- (void)setFavoritesState:(NSInteger)arg1 animated:(BOOL)arg2
{
	if(preferenceManager.customStartSiteEnabled && preferenceManager.customStartSite)
	{
		TabDocument* activeTabDocument = self.tabController.activeTabDocument;

		if(arg1 == 4)
		{
			%orig(0,arg2);
			[activeTabDocument loadURL:[NSURL URLWithString:preferenceManager.customStartSite] userDriven:NO];
			return;
		}
	}

	%orig;
}

%group iOS9Up

//Auto switch mode on external URL opened
- (NSURL*)handleExternalURL:(NSURL*)URL
{
	if(URL && preferenceManager.forceModeOnExternalLinkEnabled)
	{
		[self modeSwitchAction:preferenceManager.forceModeOnExternalLinkFor];
	}

	return %orig;
}

%end

%group iOS11_3to12_1_4

- (void)_updateTabExposeAlertController
{
	%orig;

	if(preferenceManager.lockedTabsEnabled)
	{
		updateTabExposeActionsForLockedTabs(self, MSHookIvar<UIAlertController*>(self, "_tabExposeAlertController"));
	}
}

%end

%group iOS11Up

- (void)_setPrivateBrowsingEnabled:(BOOL)arg1 showModalAuthentication:(BOOL)arg2 completion:(id)arg3
{
	if(preferenceManager.biometricProtectionEnabled && preferenceManager.biometricProtectionSwitchModeEnabled)
	{
		if(!self.browsingModeSet)
		{
			%orig;
			self.browsingModeSet = YES;
			return;
		}

		BOOL previous = privateBrowsingEnabled(self);

		if(previous != arg1)
		{
			requestAuthentication([localizationManager localizedSPStringForKey:@"SWITCH_BROWSING_MODE"],^
			{
				%orig;

				if(preferenceManager.showTabCountEnabled)
				{
					[activeToolbarForBrowserController(self) updateTabCount];
				}
			});

			return;
		}
	}

	%orig;

	if(preferenceManager.showTabCountEnabled)
	{
		[activeToolbarForBrowserController(self) updateTabCount];
	}
}

%end

%group iOS10to11_2_6

- (void)updateTabExposePopoverActions
{
	%orig;

	if(preferenceManager.lockedTabsEnabled)
	{
		updateTabExposeActionsForLockedTabs(self, MSHookIvar<UIAlertController*>(self, "_tabExposeAlertController"));
	}
}

%end

%group iOS10Down

- (void)togglePrivateBrowsingEnabled
{
	if(preferenceManager.biometricProtectionEnabled && preferenceManager.biometricProtectionSwitchModeEnabled)
	{
		requestAuthentication([localizationManager localizedSPStringForKey:@"SWITCH_BROWSING_MODE"],^
		{
			%orig;

			if(preferenceManager.showTabCountEnabled)
			{
				[activeToolbarForBrowserController(self) updateTabCount];
			}
		});

		return;
	}

	%orig;

	if(preferenceManager.showTabCountEnabled)
	{
		[activeToolbarForBrowserController(self) updateTabCount];
	}
}

- (void)togglePrivateBrowsing
{
	if(preferenceManager.biometricProtectionEnabled && preferenceManager.biometricProtectionSwitchModeEnabled)
	{
		requestAuthentication([localizationManager localizedSPStringForKey:@"SWITCH_BROWSING_MODE"],^
		{
			%orig;

			if(preferenceManager.showTabCountEnabled)
			{
				[activeToolbarForBrowserController(self) updateTabCount];
			}
		});

		return;
	}

	%orig;

	if(preferenceManager.showTabCountEnabled)
	{
		[activeToolbarForBrowserController(self) updateTabCount];
	}
}

%end

%group iOS11_3_to_12

- (void)updateButtons
{
	%orig;

	if(self.topToolbar)
	{
		BOOL enabled;

		if(self.favoritesFieldFocused)
		{
			enabled = NO;
		}
		else
		{
			enabled = MSHookIvar<BOOL>(self, "_shouldDisableToolbarForCatalogViewControllerPopover") == NO;
		}

		[self.topToolbar setDownloadsEnabled:enabled];
	}
}

%end

%group iOS12Up

- (void)_updateButtonsAnimatingTabBar:(BOOL)arg1
{
	%orig;

	BrowserToolbar* toolbar;

	if([self respondsToSelector:@selector(topToolbar)])
	{
		toolbar = self.topToolbar;
	}
	else if([self.rootViewController.navigationBar respondsToSelector:@selector(sp_toolbar)])
	{
		toolbar = self.rootViewController.navigationBar.sp_toolbar;
	}

	if(toolbar)
	{
		BOOL enabled;

		if(self.favoritesFieldFocused)
		{
			enabled = NO;
		}
		else
		{
			enabled = MSHookIvar<BOOL>(self, "_shouldDisableToolbarForCatalogViewControllerPopover") == NO;
		}

		[toolbar setDownloadsEnabled:enabled];
	}
}

%end

%end

void initBrowserController()
{
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0)
	{
		%init(iOS9Up);
	}

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_3)
	{
		if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_12_0)
		{
			%init(iOS12Up);
		}
		else
		{
			%init(iOS11_3_to_12);
		}
	}

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0 && kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_11_3)
	{
		%init(iOS10to11_2_6);
	}

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0)
	{
		%init(iOS11Up);

		if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_3 && kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_12_2)
		{
			%init(iOS11_3to12_1_4);
		}
	}
	else
	{
		%init(iOS10Down)
	}

	%init();
}
