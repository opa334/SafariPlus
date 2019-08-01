// TabController.xm
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

#import "../Classes/SPPreferenceManager.h"
#import "../Classes/SPCacheManager.h"
#import "../Classes/SPLocalizationManager.h"
#import "../Classes/SPTabManagerTableViewController.h"
#import "../Classes/SPNavigationController.h"
#import "../Defines.h"
#import "../Util.h"

%hook TabController

//BOOL for desktop button selection
%property (nonatomic,assign) BOOL desktopButtonSelected;

//Property for desktop button in portrait
%property (nonatomic,retain) UIButton *tiltedTabViewDesktopModeButton;

//Property for tab manager button in portrait
%property (nonatomic,retain) UIBarButtonItem *tiltedTabViewTabManagerBarButton;

%property (nonatomic,retain) UINavigationController *presentedTabManager;

- (TabController*)initWithBrowserController:(BrowserController*)browserController
{
	id orig = %orig;

	if(preferenceManager.desktopButtonEnabled)
	{
		[self loadDesktopButtonState];
	}

	return orig;
}

%new
- (void)loadDesktopButtonState
{
	BrowserController* browserController = MSHookIvar<BrowserController*>(self, "_browserController");

	//Load state of desktop button
	if([browserController respondsToSelector:@selector(UUID)])
	{
		self.desktopButtonSelected = [cacheManager desktopButtonStateForUUID:browserController.UUID];
	}
	else
	{
		self.desktopButtonSelected = [cacheManager desktopButtonStateForUUID:nil];
	}
}

%new
- (void)saveDesktopButtonState
{
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0)
	{
		//Save state for browserController UUID
		BrowserController* browserController = MSHookIvar<BrowserController*>(self, "_browserController");
		[cacheManager setDesktopButtonState:self.desktopButtonSelected forUUID:browserController.UUID];
	}
	else
	{
		//Save global state (iOS 9 and below can't have multiple browserControllers)
		[cacheManager setDesktopButtonState:self.desktopButtonSelected forUUID:nil];
	}
}

//Set state of desktop button
- (void)tiltedTabViewDidPresent:(id)arg1
{
	%orig;
	if(preferenceManager.desktopButtonEnabled)
	{
		self.tiltedTabViewDesktopModeButton.selected = self.desktopButtonSelected;
	}
}

//Desktop mode button: Portrait
- (NSArray *)tiltedTabViewToolbarItems
{
	if(preferenceManager.desktopButtonEnabled || preferenceManager.tabManagerEnabled)
	{
		NSArray* old = %orig;

		UIBarButtonItem* desktopBarButton;

		if(preferenceManager.desktopButtonEnabled)
		{
			if(!self.tiltedTabViewDesktopModeButton)
			{
				//desktopButton not created yet -> create and configure it
				self.tiltedTabViewDesktopModeButton = [UIButton buttonWithType:UIButtonTypeSystem];

				UIImage* desktopButtonImage = [UIImage imageNamed:@"DesktopButton.png" inBundle:SPBundle compatibleWithTraitCollection:nil];

				[self.tiltedTabViewDesktopModeButton setImage:desktopButtonImage forState:UIControlStateNormal];

				self.tiltedTabViewDesktopModeButton.tintColor = [UIColor whiteColor];

				[self.tiltedTabViewDesktopModeButton addTarget:self
				 action:@selector(tiltedTabViewDesktopModeButtonPressed)
				 forControlEvents:UIControlEventTouchUpInside];

				[self.tiltedTabViewDesktopModeButton sizeToFit];

				self.tiltedTabViewDesktopModeButton.selected = self.desktopButtonSelected;
			}

			desktopBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.tiltedTabViewDesktopModeButton];
		}

		if(preferenceManager.tabManagerEnabled)
		{
			if(!self.tiltedTabViewTabManagerBarButton)
			{
				self.tiltedTabViewTabManagerBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(tiltedTabViewTabManagerButtonPressed)];
			}
		}

		UIBarButtonItem* fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
		[fixedSpace setWidth:17.5];

		UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

		NSMutableArray* newM = [old mutableCopy];

		if([old count] < 6)	//Fix for iOS 8 when private browsing is disabled
		{
			[newM insertObject:flexibleSpace atIndex:0];
		}

		[newM removeObjectAtIndex:3];
		[newM removeObjectAtIndex:1];

		[newM insertObject:flexibleSpace atIndex:2];

		if(preferenceManager.tabManagerEnabled)
		{
			[newM insertObject:self.tiltedTabViewTabManagerBarButton atIndex:2];
		}
		else
		{
			[newM insertObject:fixedSpace atIndex:2];
		}

		[newM insertObject:flexibleSpace atIndex:2];

		[newM insertObject:flexibleSpace atIndex:1];

		if(preferenceManager.desktopButtonEnabled)
		{
			[newM insertObject:desktopBarButton atIndex:1];
		}
		else
		{
			[newM insertObject:fixedSpace atIndex:1];
		}

		[newM insertObject:flexibleSpace atIndex:1];

		return [newM copy];
	}

	return %orig;
}

%new
- (void)tiltedTabViewDesktopModeButtonPressed
{
	self.desktopButtonSelected = !self.desktopButtonSelected;

	self.tiltedTabViewDesktopModeButton.selected = self.desktopButtonSelected;

	//Update user agents
	[self updateUserAgents];

	//Write button state to plist
	[self saveDesktopButtonState];
}

%new
- (void)tiltedTabViewTabManagerButtonPressed
{
	BrowserController* browserController = MSHookIvar<BrowserController*>(self, "_browserController");

	BrowserRootViewController* vc = rootViewControllerForBrowserController(browserController);
	SPTabManagerTableViewController* tabManagerTableViewController = [[SPTabManagerTableViewController alloc] initWithTabController:self];
	SPNavigationController* navigationController = [[SPNavigationController alloc] initWithRootViewController:tabManagerTableViewController];
	//navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;

	self.presentedTabManager = navigationController;

	[vc presentViewController:navigationController animated:YES completion:nil];
}

%new
- (void)tabManagerDidClose
{
	self.presentedTabManager = nil;
}

//Update user agent of all tabs
%new
- (void)updateUserAgents
{
	for(TabDocument* tabDocument in self.allTabDocuments)
	{
		if(tabDocument.webView)
		{
			[tabDocument.webView sp_updateCustomUserAgent];

			if(!tabDocument.isBlankDocument)
			{
				[tabDocument.webView sp_applyCustomUserAgent];
			}
		}
	}
}

- (void)tabDocumentDidUpdateUUID:(TabDocument*)tabDocument previousUUID:(NSUUID*)UUID
{
	%orig;

	if(tabDocument.locked)
	{
		[tabDocument writeLockStateToCache];
	}
	else
	{
		[tabDocument updateLockStateFromCache];
		[tabDocument updateLockButtons];
	}
}

- (void)tabDocumentDidUpdateUUID:(TabDocument*)tabDocument
{
	%orig;

	if(tabDocument.locked)
	{
		[tabDocument writeLockStateToCache];
	}
	else
	{
		[tabDocument updateLockStateFromCache];
		[tabDocument updateLockButtons];
	}
}

- (void)_restorePersistentDocumentState:(id)arg1 into:(id)arg2 withCurrentActiveDocument:(id)arg3 activeDocumentIsValid:(BOOL)arg4 restoredActiveDocumentIndex:(NSUInteger)arg5 shouldRestoreSessionData:(BOOL)arg6
{
	%orig;

	if(preferenceManager.showTabCountEnabled)
	{
		BrowserController* browserController = MSHookIvar<BrowserController*>(self, "_browserController");
		[activeToolbarForBrowserController(browserController) updateTabCount];
	}
}

- (void)_restorePersistentDocumentState:(id)arg1 into:(id)arg2 withCurrentActiveDocument:(id)arg3 activeDocumentIsValid:(BOOL)arg4 restoredActiveDocumentIndex:(NSUInteger)arg5
{
	%orig;

	if(preferenceManager.showTabCountEnabled)
	{
		BrowserController* browserController = MSHookIvar<BrowserController*>(self, "_browserController");
		[activeToolbarForBrowserController(browserController) updateTabCount];
	}
}

%group iOS12_1_4Down

- (void)_updateTiltedTabViewItemsWithTransition:(NSInteger)transition
{
	if(preferenceManager.lockedTabsEnabled)
	{
		NSMutableSet<TabDocument*>* tabDocumentsAboutToBeClosedInTiltedTabView = MSHookIvar<NSMutableSet<TabDocument*>*>(self, "_tabDocumentsAboutToBeClosedInTiltedTabView");

		NSMutableSet<TabDocument*>* tabDocumentsCopy = [tabDocumentsAboutToBeClosedInTiltedTabView copy];

		for(TabDocument* tabDocument in tabDocumentsCopy)
		{
			if(tabDocument.locked)
			{
				[tabDocumentsAboutToBeClosedInTiltedTabView removeObject:tabDocument];
			}
		}
	}

	%orig;
}

- (BOOL)tiltedTabView:(TiltedTabView*)tiltedTabView canCloseItem:(TiltedTabItem*)item
{
	if(preferenceManager.lockedTabsEnabled)
	{
		TabDocument* tabDocument = tabDocumentForItem(self, item);

		if(tabDocument.locked)
		{
			return NO;
		}
	}

	return %orig;
}

- (BOOL)tabOverview:(TabOverview*)tabOverview canCloseItem:(TabOverviewItem*)item
{
	if(preferenceManager.lockedTabsEnabled)
	{
		TabDocument* tabDocument = tabDocumentForItem(self, item);

		if(tabDocument.locked)
		{
			return NO;
		}
	}

	return %orig;
}

- (BOOL)tabBar:(TabBar*)tabBar canCloseItem:(TabBarItem*)item
{
	if(preferenceManager.lockedTabsEnabled)
	{
		TabDocument* tabDocument = tabDocumentForItem(self, item);

		if(tabDocument.locked)
		{
			return NO;
		}
	}

	return %orig;
}

%end

%group iOS12_2Up

- (BOOL)tabCollectionView:(id)collectionView canCloseItem:(id<TabCollectionItem>)item
{
	if(preferenceManager.lockedTabsEnabled)
	{
		TabDocument* tabDocument = tabDocumentForItem(self, item);

		if(tabDocument.locked)
		{
			return NO;
		}
	}

	return %orig;
}

%end

%new
- (void)toggleLockedStateForItem:(id<TabCollectionItem>)item
{
	[self toggleLockedStateForTabDocument:tabDocumentForItem(self, item)];
}

%new
- (void)toggleLockedStateForTabDocument:(TabDocument*)tabDocument
{
	void (^toggle)(void) = ^
	{
		tabDocument.locked = !tabDocument.locked;
	};

	if(preferenceManager.biometricProtectionEnabled && (preferenceManager.biometricProtectionLockTabEnabled || preferenceManager.biometricProtectionUnlockTabEnabled))
	{
		if(preferenceManager.biometricProtectionLockTabEnabled && !tabDocument.locked)
		{
			requestAuthentication([localizationManager localizedSPStringForKey:@"LOCK_TAB"], toggle);
			return;
		}
		else if(preferenceManager.biometricProtectionUnlockTabEnabled && tabDocument.locked)
		{
			requestAuthentication([localizationManager localizedSPStringForKey:@"UNLOCK_TAB"], toggle);
			return;
		}
	}

	toggle();
}

%group iOS9Down

- (NSUInteger)maximumTabDocumentCount
{
	if(preferenceManager.disableTabLimit)
	{
		return NSUIntegerMax;	//Should be more than enough ;)
	}

	return %orig;
}

%end

%group iOS10Up

- (void)closeAllOpenTabsAnimated:(BOOL)animated exitTabView:(BOOL)exitTabView temporarily:(BOOL)temporarily
{
	if(preferenceManager.lockedTabsEnabled)
	{
		NSMutableArray<TabDocument*>* lockedTabDocuments = [NSMutableArray new];

		for(TabDocument* document in self.currentTabDocuments)
		{
			if(document.locked)
			{
				[lockedTabDocuments addObject:document];
			}
		}

		if([lockedTabDocuments count] > 0)	//Don't close tabView if tabs are still open afterwards
		{
			exitTabView = NO;
		}

		%orig(animated, exitTabView, temporarily);

		return;
	}

	%orig;
}

%end

%group iOS11Up

- (void)_closeTabDocuments:(NSArray<TabDocument*>*)documents animated:(BOOL)arg2 temporarily:(BOOL)arg3 allowAddingToRecentlyClosedTabs:(BOOL)arg4 keepWebViewAlive:(BOOL)arg5
{
	if(preferenceManager.lockedTabsEnabled)
	{
		NSMutableArray* documentsM = [documents mutableCopy];

		for(TabDocument* document in [documentsM reverseObjectEnumerator])
		{
			if(document.locked)
			{
				[documentsM removeObject:document];
			}
		}

		return %orig([documentsM copy], arg2, arg3, arg4, arg5);
	}

	return %orig;
}

%end

%group iOS10Down

- (void)_closeTabDocument:(TabDocument*)document animated:(BOOL)arg2 temporarily:(BOOL)arg3 allowAddingToRecentlyClosedTabs:(BOOL)arg4 keepWebViewAlive:(BOOL)arg5
{
	if(preferenceManager.lockedTabsEnabled)
	{
		if(document.locked)
		{
			return;
		}
	}

	return %orig;
}

- (void)_closeTabDocument:(TabDocument*)document animated:(BOOL)arg2 allowAddingToRecentlyClosedTabs:(BOOL)arg3
{
	if(preferenceManager.lockedTabsEnabled)
	{
		if(document.locked)
		{
			return;
		}
	}

	return %orig;
}

- (void)closeTabDocument:(TabDocument*)document animated:(BOOL)arg2
{
	if(preferenceManager.lockedTabsEnabled)
	{
		if(document.locked)
		{
			return;
		}
	}

	return %orig;
}

%end

%group iOS9Up

- (void)setActiveTabDocument:(TabDocument*)document animated:(BOOL)arg2 deferActivation:(BOOL)arg3
{
	if(preferenceManager.lockedTabsEnabled)
	{
		if(self.activeTabDocument != document)
		{
			if(!document.accessAuthenticated && document.locked && preferenceManager.biometricProtectionEnabled && preferenceManager.biometricProtectionAccessLockedTabEnabled)
			{
				requestAuthentication([localizationManager localizedSPStringForKey:@"ACCESS_LOCKED_TAB"], ^
				{
					%orig;
				});

				return;
			}

			if(document.accessAuthenticated)
			{
				document.accessAuthenticated = NO;
			}
		}
	}

	%orig;
}

%end

%group iOS8

- (void)setActiveTabDocument:(TabDocument*)document animated:(BOOL)arg2
{
	if(preferenceManager.lockedTabsEnabled)
	{
		if(!document.accessAuthenticated && document.locked && preferenceManager.biometricProtectionEnabled && preferenceManager.biometricProtectionAccessLockedTabEnabled)
		{
			requestAuthentication([localizationManager localizedSPStringForKey:@"ACCESS_LOCKED_TAB"], ^
			{
				%orig;
			});

			return;
		}

		if(document.accessAuthenticated)
		{
			document.accessAuthenticated = NO;
		}
	}

	%orig;
}

%end

%end

void initTabController()
{
	if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_11_0)
	{
		%init(iOS10Down);
	}
	else
	{
		%init(iOS11Up);
	}

	if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_10_0)
	{
		%init(iOS9Down);
	}
	else
	{
		%init(iOS10Up);
	}

	if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_9_0)
	{
		%init(iOS8);
	}
	else
	{
		%init(iOS9Up);
	}

	if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_12_2)
	{
		%init(iOS12_1_4Down);
	}
	else
	{
		%init(iOS12_2Up);
	}

	%init();
}
