// TabOverview.xm
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
#import "../Classes/SPLocalizationManager.h"
#import "../Classes/SPTabManagerTableViewController.h"
#import "../Util.h"
#import "../Defines.h"

%hook TabOverview

%property (nonatomic,retain) UIButton *desktopModeButton;
%property (nonatomic,retain) UIButton *tabManagerButton;

//Desktop mode button: Landscape

- (void)layoutSubviews
{
	%orig;

	if(preferenceManager.desktopButtonEnabled || preferenceManager.tabManagerEnabled)
	{
		UISearchBar* searchBar = MSHookIvar<UISearchBar*>(self, "_searchBar");
		UIView* superview = [self.privateBrowsingButton superview];

		BOOL desktopButtonAdded = NO;
		BOOL tabManagerButtonAdded = NO;

		if(preferenceManager.desktopButtonEnabled)
		{
			if(!self.desktopModeButton)
			{
				//desktopButton not created yet -> create and configure it
				self.desktopModeButton = [UIButton buttonWithType:UIButtonTypeSystem];
				UIImage* desktopButtonImage = [UIImage imageNamed:@"DesktopButton.png" inBundle:SPBundle compatibleWithTraitCollection:nil];
				[self.desktopModeButton setImage:desktopButtonImage forState:UIControlStateNormal];
				[self.desktopModeButton addTarget:self action:@selector(desktopModeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
				self.desktopModeButton.selected = self.delegate.desktopButtonSelected;
				self.desktopModeButton.tintColor = [UIColor whiteColor];
			}

			//Desktop button is not added to top bar yet -> Add it
			if(![self.desktopModeButton isDescendantOfView:superview])
			{
				desktopButtonAdded = YES;
				[superview addSubview:self.desktopModeButton];
			}
		}

		if(preferenceManager.tabManagerEnabled)
		{
			if(!self.tabManagerButton)
			{
				self.tabManagerButton = [UIButton buttonWithType:UIButtonTypeSystem];
				UIImage* shareImage;
				[UIBarButtonItem _getSystemItemStyle:nil title:nil image:&shareImage selectedImage:nil action:nil forBarStyle:0 landscape:NO alwaysBordered:NO usingSystemItem:9 usingItemStyle:0];
				[self.tabManagerButton setImage:shareImage forState:UIControlStateNormal];
				[self.tabManagerButton addTarget:self action:@selector(tabManagerButtonPressed) forControlEvents:UIControlEventTouchUpInside];
				self.tabManagerButton.tintColor = [UIColor whiteColor];
			}

			if(![self.tabManagerButton isDescendantOfView:superview])
			{
				tabManagerButtonAdded = YES;
				[superview addSubview:self.tabManagerButton];
			}
		}

		//Update position

		CGFloat gap = self.addTabButton.frame.origin.x - (self.privateBrowsingButton.frame.origin.x + self.privateBrowsingButton.frame.size.width);

		CGRect pos1 = CGRectMake(
			self.privateBrowsingButton.frame.origin.x - (gap + self.privateBrowsingButton.frame.size.height),
			self.privateBrowsingButton.frame.origin.y,
			self.privateBrowsingButton.frame.size.height,
			self.privateBrowsingButton.frame.size.height);

		CGRect pos2 = CGRectMake(
			self.privateBrowsingButton.frame.origin.x - ((gap + self.privateBrowsingButton.frame.size.height) * 2),
			self.privateBrowsingButton.frame.origin.y,
			self.privateBrowsingButton.frame.size.height,
			self.privateBrowsingButton.frame.size.height);

		if(preferenceManager.desktopButtonEnabled && preferenceManager.tabManagerEnabled)
		{
			self.desktopModeButton.frame = pos1;
			self.tabManagerButton.frame = pos2;
		}
		else
		{
			if(preferenceManager.desktopButtonEnabled)
			{
				self.desktopModeButton.frame = pos1;
			}
			else if(preferenceManager.tabManagerEnabled)
			{
				self.tabManagerButton.frame = pos1;
			}
		}

		if([searchBar isFirstResponder] || searchBar.text.length > 0)
		{
			if(preferenceManager.desktopButtonEnabled && self.desktopModeButton.enabled)
			{
				self.desktopModeButton.enabled = NO;

				[UIView animateWithDuration:0.35 delay:0 options:327682
				 animations:^
				{
					self.desktopModeButton.alpha = 0.0;
				} completion:nil];
			}
			if(preferenceManager.tabManagerEnabled && self.tabManagerButton.enabled)
			{
				self.tabManagerButton.enabled = NO;

				[UIView animateWithDuration:0.35 delay:0 options:327682
				 animations:^
				{
					self.tabManagerButton.alpha = 0.0;
				} completion:nil];
			}
		}
		else if(!desktopButtonAdded)
		{
			if(preferenceManager.desktopButtonEnabled && !self.desktopModeButton.enabled)
			{
				self.desktopModeButton.enabled = YES;

				[UIView animateWithDuration:0.35 delay:0 options:327682
				 animations:^
				{
					self.desktopModeButton.alpha = 1.0;
				} completion:nil];
			}
			if(preferenceManager.tabManagerEnabled && !self.tabManagerButton.enabled)
			{
				self.tabManagerButton.enabled = YES;

				[UIView animateWithDuration:0.35 delay:0 options:327682
				 animations:^
				{
					self.tabManagerButton.alpha = 1.0;
				} completion:nil];
			}
		}
	}
}

- (void)_updateScrollBoundsForKeyboardInfo:(id)arg1
{
	if(preferenceManager.tabManagerEnabled)
	{
		if(!self.delegate)
		{
			return; //please don't break anything, please (fix for weird crash)
		}
	}

	%orig;
}

%new
- (void)desktopModeButtonPressed
{
	self.delegate.desktopButtonSelected = !self.delegate.desktopButtonSelected;
	self.desktopModeButton.selected = self.delegate.desktopButtonSelected;

	//Reload tabs
	[self.delegate updateUserAgents];

	//Write button state to plist
	[self.delegate saveDesktopButtonState];
}

%new
- (void)tabManagerButtonPressed
{
	TabController* tabController = self.delegate;

	[tabController tiltedTabViewTabManagerButtonPressed];
}

%new
- (void)_lockButtonPressed:(UIButton*)button
{
	for(TabOverviewItem* item in self.items)
	{
		if([item respondsToSelector:@selector(_thumbnailView)])	//iOS 9 and below
		{
			if(item.thumbnailView.lockButton == button)
			{
				[self.delegate tabOverview:self toggleLockedStateForItem:item];
			}
		}
		else
		{
			if(item.layoutInfo.itemView.lockButton == button)
			{
				[self.delegate tabOverview:self toggleLockedStateForItem:item];
			}
		}
	}
}

- (void)_dismissWithItemAtCurrentDecelerationFactor:(TabOverviewItem*)item
{
	if(preferenceManager.lockedTabsEnabled && preferenceManager.biometricProtectionEnabled && preferenceManager.biometricProtectionAccessLockedTabEnabled)
	{
		if([self.delegate currentItemForTabOverview:self] != item)
		{
			TabDocument* tabDocument = [self.delegate _tabDocumentRepresentedByTabOverviewItem:item];

			if(tabDocument.locked)
			{
				requestAuthentication([localizationManager localizedSPStringForKey:@"ACCESS_LOCKED_TAB"], ^
				{
					tabDocument.accessAuthenticated = YES;
					%orig;
				});

				return;
			}
		}
	}

	%orig;
}

%group iOS9Down

- (void)removeViewsForItem:(TabOverviewItem*)item
{
	[item.thumbnailView.lockButton removeTarget:self action:@selector(_lockButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	item.thumbnailView.lockButton = nil;
	%orig;
}

- (void)_updateDisplayedItems
{
	%orig;

	NSArray* displayedItems = MSHookIvar<NSArray*>(self, "_displayedItems");

	for(TabOverviewItem* item in displayedItems)
	{
		if([item.thumbnailView.lockButton actionsForTarget:self forControlEvent:UIControlEventTouchUpInside].count == 0)
		{
			[item.thumbnailView.lockButton addTarget:self action:@selector(_lockButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
			item.thumbnailView.lockButton.selected = [self.delegate _tabDocumentRepresentedByTabOverviewItem:item].locked;
		}
	}
}

%end

%end

void initTabOverview()
{
	if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_10_0)
	{
		%init(iOS9Down);
	}

	%init();
}
