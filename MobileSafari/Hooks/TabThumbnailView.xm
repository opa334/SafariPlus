// Copyright (c) 2017-2021 Lars Fröder

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

%hook TabThumbnailView

%property (nonatomic, retain) _SFDimmingButton *lockButton;

- (TabThumbnailView*)initWithFrame:(CGRect)frame
{
	TabThumbnailView* orig = %orig;

	if(orig && preferenceManager.lockedTabsEnabled)
	{
		UIView* headerView = MSHookIvar<UIView*>(self, "_headerView");

		Class buttonClass = NSClassFromString(@"_SFDimmingButton");

		if(!buttonClass)
		{
			buttonClass = NSClassFromString(@"DimmingButton");
		}

		self.lockButton = [buttonClass buttonWithType:UIButtonTypeSystem];
		[self.lockButton setImage:[UIImage imageNamed:@"LockButton_Open" inBundle:SPBundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
		[self.lockButton setImage:[UIImage imageNamed:@"LockButton_Closed" inBundle:SPBundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
		self.lockButton.normalImageAlpha = 1.0;
		self.lockButton.highlightedImageAlpha = 0.2;
		[headerView addSubview:self.lockButton];
	}

	return orig;
}

- (void)layoutSubviews
{
	%orig;

	if(preferenceManager.lockedTabsEnabled)
	{
		UIView* headerView = MSHookIvar<UIView*>(self, "_headerView");
		UIView* titleView;

		if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_12_0)
		{
			titleView = MSHookIvar<UIView*>(self, "_titleLabel");
		}
		else
		{
			titleView = MSHookIvar<UIView*>(self, "_iconAndTitleView");
		}

		self.lockButton.tintColor = self.titleColor;

		CGFloat size = self.closeButton.frame.size.width;

		BOOL isRTL = NO;

		if([self respondsToSelector:@selector(_sf_usesLeftToRightLayout)])
		{
			isRTL = ![self _sf_usesLeftToRightLayout];
		}

		CGFloat spacing;

		if(isRTL)
		{
			self.lockButton.frame = CGRectMake(0, 0, size, size);
			spacing = headerView.frame.size.width - titleView.frame.origin.x - titleView.frame.size.width - size;
		}
		else
		{
			self.lockButton.frame = CGRectMake(headerView.frame.size.width - size, 0, size, size);
			spacing = titleView.frame.origin.x - size;
		}

		CGFloat maxTitleViewWidth = headerView.frame.size.width - ((size + spacing) * 2);

		if(titleView.frame.size.width > maxTitleViewWidth)
		{
			if(isRTL)
			{
				titleView.frame = CGRectMake(size + spacing, titleView.frame.origin.y, maxTitleViewWidth, titleView.frame.size.height);
			}
			else
			{
				titleView.frame = CGRectMake(titleView.frame.origin.x, titleView.frame.origin.y, maxTitleViewWidth, titleView.frame.size.height);
			}
		}
	}
}

%end

void initTabThumbnailView()
{
	%init();
}
