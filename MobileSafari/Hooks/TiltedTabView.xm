// TiltedTabView.xm
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

#import "../Defines.h"
#import "../Shared.h"

%hook TiltedTabView

%new
- (void)_lockButtonPressed:(UIButton*)button
{
	for(TiltedTabItem* item in self.items)
	{
		if([item respondsToSelector:@selector(contentView)])
		{
			if(item.contentView.lockButton == button)
			{
				[self.delegate tiltedTabView:self toggleLockedStateForItem:item];
			}
		}
		else
		{
			if(item.layoutInfo.contentView.lockButton == button)
			{
				[self.delegate tiltedTabView:self toggleLockedStateForItem:item];
			}
		}
	}
}

- (void)_tabSelectionRecognized:(UITapGestureRecognizer*)recognizer
{
	if(preferenceManager.lockedTabsEnabled && preferenceManager.biometricProtectionEnabled && preferenceManager.biometricProtectionAccessLockedTabEnabled)
	{
		if(MSHookIvar<NSInteger>(self, "_currentTabPreviewState") != 2)
		{
			TiltedTabItem* tappedItem = [self _tiltedTabItemForLocation:[recognizer locationInView:MSHookIvar<UIView*>(self, "_scrollView")]];

			if([self.delegate currentItemForTiltedTabView:self] != tappedItem)
			{
				TabDocument* tabDocument = [self.delegate _tabDocumentRepresentedByTiltedTabItem:tappedItem];

				if(tabDocument.locked)
				{
					requestAuthentication([localizationManager localizedSPStringForKey:@"ACCESS_LOCKED_TAB"], ^
					{
						tabDocument.accessAuthenticated = YES;
						[self.delegate tiltedTabView:self didSelectItem:tappedItem];
						[self setPresented:NO animated:YES];
					});

					return;
				}
			}
		}
	}

	%orig;
}

%group iOS9Down

- (void)_updateItemsInvolvedInAnimation
{
	NSArray* itemsInvolvedInAnimation = MSHookIvar<NSArray*>(self, "_itemsInvolvedInAnimation");

	for(TiltedTabItem* item in itemsInvolvedInAnimation)
	{
		[item.contentView.lockButton removeTarget:self action:@selector(_lockButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	}

	%orig;

	itemsInvolvedInAnimation = MSHookIvar<NSArray*>(self, "_itemsInvolvedInAnimation");

	for(TiltedTabItem* item in itemsInvolvedInAnimation)
	{
		[item.contentView.lockButton addTarget:self action:@selector(_lockButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		item.contentView.lockButton.selected = [self.delegate _tabDocumentRepresentedByTiltedTabItem:item].locked;
	}
}

%end

%end

void initTiltedTabView()
{
	%init();

	if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_10_0)
	{
		%init(iOS9Down);
	}
}
