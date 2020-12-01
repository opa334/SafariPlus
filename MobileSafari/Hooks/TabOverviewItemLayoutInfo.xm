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

#import "../Util.h"
#import "../Classes/SPPreferenceManager.h"
#import "../Defines.h"
#import <libundirect.h>

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
			itemView.lockButton.selected = tabDocumentForItem(self.tabOverview.delegate, self.tabOverviewItem).locked;
		}
	}
}

%end

%end

void initTabOverviewItemLayoutInfo()
{
	%config(generator=MobileSubstrate_libundirect)

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0)
	{
		%init(iOS10Up);
	}
}
