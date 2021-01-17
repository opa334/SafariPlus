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

#import "../SafariPlus.h"

#import "../libundirect_dynamic.h"
#import <libundirect_hookoverwrite.h>

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

%property (nonatomic, assign) BOOL isSetUp;

//Present downloads view
%new
- (void)downloadsFromButtonBar
{
	void (^openDownloads)(void) = ^
	{
		//Create SPDownloadNavigationController
		SPDownloadNavigationController* downloadsController = [[SPDownloadNavigationController alloc] init];

		//Present SPDownloadNavigationController
		[rootViewControllerForBrowserController(self) presentViewController:downloadsController animated:YES completion:nil];
	}; 

	if(preferenceManager.biometricProtectionEnabled && preferenceManager.biometricProtectionOpenDownloadsEnabled)
	{
		requestAuthentication([localizationManager localizedSPStringForKey:@"OPEN_DOWNLOADS"], openDownloads);
	}
	else
	{
		openDownloads();
	}
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
		else	//iOS 8 and 13 up?
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
		if(!isTabDocumentBlank(self.tabController.activeTabDocument))
		{
			[self.tabController.activeTabDocument reload];
		}
		break;
	}

	case GestureActionRequestDesktopSite:
	{
		if(!isTabDocumentBlank(self.tabController.activeTabDocument))
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
	if(preferenceManager.biometricProtectionEnabled && preferenceManager.biometricProtectionSwitchModeEnabled && preferenceManager.biometricProtectionSwitchModeAllowAutomaticActionsEnabled)
	{
		skipBiometricProtection = YES;
	}

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

	skipBiometricProtection = NO;
}

//Used to switch mode based on the setting
%new
- (void)modeSwitchAction:(int)switchToMode
{
	if(preferenceManager.biometricProtectionEnabled && preferenceManager.biometricProtectionSwitchModeEnabled && preferenceManager.biometricProtectionSwitchModeAllowAutomaticActionsEnabled)
	{
		skipBiometricProtection = YES;
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

	skipBiometricProtection = NO;
}

//Full screen scrolling

//iOS 9-10.2 (method doesn't exist on 8)
- (BOOL)_isVerticallyConstrained
{
	if(preferenceManager.fullscreenScrollingEnabled)
	{
		if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_10_3)
		{
			return YES;
		}
	}

	return %orig;
}

%group iOS11Down

//Fully disable private mode
- (BOOL)isPrivateBrowsingAvailable //iOS <=11.4.1
{
	return (preferenceManager.disablePrivateMode) ? NO : %orig;
}

%end

%group iOS13Down

//iOS 8,10.3-13.7 (causes status bar flickering on iOS <=10.2, on iOS 8 we use it anyways cause it's the only thing that works on there)
- (BOOL)fullScreenInPortrait //DIRECT IN IOS 14 (ivar still exists)
{
	if(preferenceManager.fullscreenScrollingEnabled)
	{
		if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_9_0 || kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_3)
		{
			return YES;
		}
	}

	return %orig;
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

%end

//iOS 14

%group iOS14Up

- (void)handleNavigationIntent:(_SFNavigationIntent*)intent completion:(id)arg2
{
	if(intent.type == 7 && preferenceManager.forceModeOnExternalLinkEnabled)
	{
		[self modeSwitchAction:preferenceManager.forceModeOnExternalLinkFor];
	}

	return %orig;
}

- (void)_updateDisableBarHiding
{
	%orig;

	if(preferenceManager.fullscreenScrollingEnabled)
	{
		[self setValue:@YES forKey:@"_fullScreenInPortrait"];
	}
}

- (void)setFavoritesState:(NSInteger)arg1 animated:(BOOL)arg2 catalogVC:(id)arg3
{
	if(preferenceManager.customStartSiteEnabled && preferenceManager.customStartSite)
	{
		TabDocument* activeTabDocument = self.tabController.activeTabDocument;

		if(arg1 == 4)
		{
			%orig(0,arg2,arg3);
			[activeTabDocument loadURL:[NSURL URLWithString:preferenceManager.customStartSite] userDriven:NO];
			return;
		}
	}

	%orig;
}

%new
- (BOOL)isPrivateBrowsingAvailable
{
	return [[%c(FeatureManager) sharedFeatureManager] isPrivateBrowsingAvailable];
}

%end


//iOS >=13
- (BOOL)dynamicBarAnimator:(id)arg1 canTransitionToState:(NSInteger)state byDraggingWithOffset:(CGFloat)arg3
{
	if(preferenceManager.lockBars && state == 0)
	{
		return NO;
	}

	return %orig;
}

//iOS <=12
- (BOOL)dynamicBarAnimator:(id)arg1 canHideBarsByDraggingWithOffset:(CGFloat)arg2
{
	return (preferenceManager.lockBars) ? NO : %orig;
}

- (void)tabControllerDocumentCountDidChange:(TabController*)tabController //DIRECT IN IOS 14
{
	%orig;

	if(preferenceManager.showTabCountEnabled)
	{
		[activeToolbarOrToolbarForBarItemForBrowserController(self, StockBarItemTabExpose) updateTabCount];
	}

	if(preferenceManager.tabManagerEnabled && tabController.presentedTabManager)
	{
		[(SPTabManagerTableViewController*) tabController.presentedTabManager.viewControllers.firstObject reloadAnimated:YES];
	}
}

- (void)_initSubviews
{
	%orig;
	if(preferenceManager.URLLeftSwipeGestureEnabled || preferenceManager.URLRightSwipeGestureEnabled || preferenceManager.URLDownSwipeGestureEnabled)
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

%group iOS9_to_12_4_9

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

%group iOS9Up

- (void)setUpWithURL:(id)arg1 launchOptions:(id)arg2
{
	self.isSetUp = NO;
	%orig;
	self.isSetUp = YES;

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0)
	{
		if(preferenceManager.forceModeOnStartEnabled && preferenceManager.forceModeOnStartFor)
		{
			[self modeSwitchAction:preferenceManager.forceModeOnStartFor];
		}
	}	
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

%group iOS13Up

- (void)handleNavigationIntent:(_SFNavigationIntent*)intent
{
	if(intent.type == 6 && preferenceManager.forceModeOnExternalLinkEnabled)
	{
		[self modeSwitchAction:preferenceManager.forceModeOnExternalLinkFor];
	}

	return %orig;
}

- (void)setPrivateBrowsingEnabled:(BOOL)arg1
{
	void (^origBlock)() = ^
	{
		%orig;

		if(preferenceManager.showTabCountEnabled)
		{
			[activeToolbarOrToolbarForBarItemForBrowserController(self, StockBarItemTabExpose) updateTabCount];
		};
	};

	if(preferenceManager.biometricProtectionEnabled && preferenceManager.biometricProtectionSwitchModeEnabled)
	{
		if(!self.isSetUp)
		{
			origBlock();
			return;
		}

		BOOL previous = privateBrowsingEnabled(self);

		if(previous != arg1)
		{
			requestAuthentication([localizationManager localizedSPStringForKey:@"SWITCH_BROWSING_MODE"],^
			{
				origBlock();
			});

			return;
		}
	}

	origBlock();
}

%end

%group iOS11to12_4_3

- (void)_setPrivateBrowsingEnabled:(BOOL)arg1 showModalAuthentication:(BOOL)arg2 completion:(id)arg3
{
	void (^origBlock)() = ^
	{
		%orig;

		if(preferenceManager.showTabCountEnabled)
		{
			[activeToolbarOrToolbarForBarItemForBrowserController(self, StockBarItemTabExpose) updateTabCount];
		};
	};

	if(preferenceManager.biometricProtectionEnabled && preferenceManager.biometricProtectionSwitchModeEnabled)
	{
		if(!self.isSetUp)
		{
			origBlock();
			return;
		}

		BOOL previous = privateBrowsingEnabled(self);

		if(previous != arg1)
		{
			requestAuthentication([localizationManager localizedSPStringForKey:@"SWITCH_BROWSING_MODE"],^
			{
				origBlock();
			});

			return;
		}
	}

	origBlock();
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

- (void)togglePrivateBrowsing
{
	void (^origBlock)() = ^
	{
		%orig;

		if(preferenceManager.showTabCountEnabled)
		{
			[activeToolbarOrToolbarForBarItemForBrowserController(self, StockBarItemTabExpose) updateTabCount];
		};
	};

	if(preferenceManager.biometricProtectionEnabled && preferenceManager.biometricProtectionSwitchModeEnabled)
	{
		requestAuthentication([localizationManager localizedSPStringForKey:@"SWITCH_BROWSING_MODE"],^
		{
			origBlock();
		});

		return;
	}

	origBlock();
}

- (void)setPrivateBrowsingEnabled:(BOOL)enabled
{
	if([self respondsToSelector:@selector(togglePrivateBrowsing)])
	{
		%orig;
		return;
	}

	void (^origBlock)() = ^
	{
		%orig;

		if(preferenceManager.showTabCountEnabled)
		{
			[activeToolbarOrToolbarForBarItemForBrowserController(self, StockBarItemTabExpose) updateTabCount];
		};
	};

	if(preferenceManager.biometricProtectionEnabled && preferenceManager.biometricProtectionSwitchModeEnabled)
	{
		if(!self.isSetUp)
		{
			origBlock();
			return;
		}

		BOOL previous = privateBrowsingEnabled(self);

		if(previous != enabled)
		{
			requestAuthentication([localizationManager localizedSPStringForKey:@"SWITCH_BROWSING_MODE"],^
			{
				origBlock();
			});

			return;
		}
	}

	origBlock();
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

		if(self.favoritesFieldFocused) //TODO: Find alternative on iOS 14, no longer exists
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
		if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_13_0)
		{
			%init(iOS9_to_12_4_9);
		}

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
		if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_13_0)
		{
			%init(iOS11to12_4_3);
		}
		else
		{
			%init(iOS13Up);
		}		

		if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_3 && kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_12_2)
		{
			%init(iOS11_3to12_1_4);
		}
	}
	else
	{
		%init(iOS10Down)
	}

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_14_0)
	{
		%init(iOS14Up);
	}
	else
	{
		%init(iOS13Down);
	}

	if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_12_0)
	{
		%init(iOS11Down);
	}

	%init();
}
