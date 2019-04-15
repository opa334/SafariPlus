// TabOverviewItemLayoutInfo.xm
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

#import "../Shared.h"
#import "../Classes/SPPreferenceManager.h"
#import "../Defines.h"

%hook TabOverviewItemLayoutInfo

%group iOS10Up

- (void)_clearViews
{
	if(preferenceManager.lockedTabsEnabled)
	{
		TabOverviewItemView* itemView = MSHookIvar<TabOverviewItemView*>(self, "_itemView");
		[itemView.lockButton removeTarget:self.tabOverview action:@selector(_lockButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	}

	%orig;
}

- (void)_ensureViews
{
	%orig;

	if(preferenceManager.lockedTabsEnabled)
	{
		if(self.visibleInTabOverview)
		{
			TabOverviewItemView* itemView = MSHookIvar<TabOverviewItemView*>(self, "_itemView");
			[itemView.lockButton addTarget:self.tabOverview action:@selector(_lockButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
			itemView.lockButton.selected = [self.tabOverview.delegate _tabDocumentRepresentedByTabOverviewItem:self.tabOverviewItem].locked;
		}
	}
}

%end

%end

void initTabOverviewItemLayoutInfo()
{
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0)
	{
		%init(iOS10Up);
	}
}
