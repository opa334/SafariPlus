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
		UIView* superview = [self.addTabButton superview];

		BOOL desktopButtonAdded = NO;
		BOOL tabManagerButtonAdded = NO;

		if(preferenceManager.desktopButtonEnabled)
		{
			if(!self.desktopModeButton)
			{
				//desktopButton not created yet -> create and configure it
				self.desktopModeButton = [UIButton buttonWithType:UIButtonTypeSystem];
				UIImage* desktopButtonImage;

				if([UIImage respondsToSelector:@selector(systemImageNamed:)])
				{
					desktopButtonImage = [UIImage systemImageNamed:@"desktopcomputer"];
				}
				else
				{
					desktopButtonImage = [UIImage imageNamed:@"DesktopButton" inBundle:SPBundle compatibleWithTraitCollection:nil];
				}

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

				if([UIImage respondsToSelector:@selector(systemImageNamed:)])
				{
					shareImage = [UIImage systemImageNamed:@"square.and.arrow.up"];
				}
				else
				{
					[UIBarButtonItem _getSystemItemStyle:nil title:nil image:&shareImage selectedImage:nil action:nil forBarStyle:0 landscape:NO alwaysBordered:NO usingSystemItem:9 usingItemStyle:0];
				}
				
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

		CGRect rightFrame;	//Fix for iOS 8 when private browsing is disabled
		CGRect righterFrame;
		BOOL set = NO;

		if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_9_0)
		{
			if(![MSHookIvar<BrowserController*>(self.delegate, "_browserController") isPrivateBrowsingAvailable])
			{
				rightFrame = self.addTabButton.frame;
				righterFrame = MSHookIvar<UIButton*>(self, "_doneButton").frame;
				set = YES;
			}
		}

		if(!set)
		{
			rightFrame = self.privateBrowsingButton.frame;
			righterFrame = self.addTabButton.frame;
		}

		CGFloat gap = righterFrame.origin.x - (rightFrame.origin.x + rightFrame.size.width);

		CGRect pos1 = CGRectMake(
			rightFrame.origin.x - (gap + rightFrame.size.height),
			rightFrame.origin.y,
			rightFrame.size.height,
			rightFrame.size.height);

		CGRect pos2 = CGRectMake(
			rightFrame.origin.x - ((gap + rightFrame.size.height) * 2),
			rightFrame.origin.y,
			rightFrame.size.height,
			rightFrame.size.height);

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
			HBLogDebug(@"prevented something?");
			return;	//please don't break anything, please (fix for weird crash)
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
				[self.delegate toggleLockedStateForItem:item];
			}
		}
		else
		{
			if(item.layoutInfo.itemView.lockButton == button)
			{
				[self.delegate toggleLockedStateForItem:item];
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
			TabDocument* tabDocument = tabDocumentForItem(self.delegate, item);

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
			item.thumbnailView.lockButton.selected = tabDocumentForItem(self.delegate, item).locked;
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
