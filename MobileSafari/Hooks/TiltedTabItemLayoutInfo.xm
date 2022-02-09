// Copyright (c) 2017-2022 Lars Fröder

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

#import <libundirect/libundirect_dynamic.h>
#import <libundirect/libundirect_hookoverwrite.h>

#import "../Util.h"
#import "../Classes/SPPreferenceManager.h"
#import "../Defines.h"

%hook TiltedTabItemLayoutInfo

%group iOS10Up

- (void)tearDownThumbnailView
{
	if(preferenceManager.lockedTabsEnabled)
	{
		if(self.contentView)
		{
			[self.contentView.lockButton removeTarget:self.tiltedTabView action:@selector(_lockButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		}
	}

	%orig;
}

- (void)setUpThumbnailView
{
	%orig;

	if(preferenceManager.lockedTabsEnabled)
	{
		[self.contentView.lockButton addTarget:self.tiltedTabView action:@selector(_lockButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		self.contentView.lockButton.selected = tabDocumentForItem(self.tiltedTabView.delegate, self.item).locked;
	}
}

%end

%end

void initTiltedTabItemLayoutInfo()
{
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0)
	{
		%init(iOS10Up);
	}
}
