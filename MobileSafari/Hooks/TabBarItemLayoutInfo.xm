// Copyright (c) 2017-2019 Lars Fröder

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
