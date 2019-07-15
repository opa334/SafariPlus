// TabBarItemLayoutInfo.xm
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
#import "../Classes/SPPreferenceManager.h"
#import "../Util.h"

%hook TabBarItemLayoutInfo

- (void)setCanClose:(BOOL)canClose
{
	%orig;

	if(preferenceManager.lockedTabsEnabled)
	{
		if([self respondsToSelector:@selector(rightView)])
		{
			[self.rightView _layoutTitleLabelUsingCachedTruncation];
		}

		if([self respondsToSelector:@selector(leftView)])
		{
			[self.leftView _layoutTitleLabelUsingCachedTruncation];
		}

		if([self respondsToSelector:@selector(trailingView)])
		{
			[self.trailingView _layoutTitleLabelUsingCachedTruncation];
		}

		if([self respondsToSelector:@selector(leadingView)])
		{
			[self.leadingView _layoutTitleLabelUsingCachedTruncation];
		}

		if([self respondsToSelector:@selector(tabBarItemView)])
		{
			[self.tabBarItemView _layoutTitleLabelUsingCachedTruncation];
		}
	}
}

- (void)clearView:(TabBarItemView*)_tabBarItemView
{
	%orig;

	if(preferenceManager.lockedTabsEnabled)
	{
		[_tabBarItemView.lockButton removeTarget:self action:@selector(lockButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	}
}

%group iOS9_to_11

- (TabBarItemView*)_reusableViewWithTitleAnchorEdge:(NSInteger)anchorEdge
{
	TabBarItemView* tabBarItemView = %orig;

	if(preferenceManager.lockedTabsEnabled)
	{
		[UIView performWithoutAnimation:^
		{
			[tabBarItemView.lockButton addTarget:self action:@selector(lockButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
			tabBarItemView.lockButton.selected = tabDocumentForItem(self.tabBar.delegate, self.tabBarItem).locked;
		}];
	}

	return tabBarItemView;
}

%end

%group iOS12Up

- (TabBarItemView*)_reusableView
{
	TabBarItemView* tabBarItemView = %orig;

	if(preferenceManager.lockedTabsEnabled)
	{
		[UIView performWithoutAnimation:^
		{
			[tabBarItemView.lockButton addTarget:self action:@selector(lockButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
			tabBarItemView.lockButton.selected = tabDocumentForItem(self.tabBar.delegate, self.tabBarItem).locked;
		}];
	}

	return tabBarItemView;
}

%end

%new
- (void)lockButtonTapped:(UIButton*)sender
{
	[self.tabBar.delegate toggleLockedStateForItem:self.tabBarItem];
}

%end

void initTabItemLayoutInfo()
{
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0)
	{
		if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_12_0)
		{
			%init(iOS12Up);
		}
		else
		{
			%init(iOS9_to_11);
		}

		%init();
	}
}
