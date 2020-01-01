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
#import "../Defines.h"
#import "../Classes/SPPreferenceManager.h"
#import "../Util.h"

%hook TabBarItemView

%property (nonatomic, retain) UIButton* lockButton;

- (instancetype)initWithTabBar:(TabBar*)tabBar
{
	if(preferenceManager.lockedTabsEnabled)
	{
		self.lockButton = [UIButton buttonWithType:UIButtonTypeSystem];
	}

	self = %orig;

	if(preferenceManager.lockedTabsEnabled)
	{
		//Fix layout
		UILabel* titleLabel = MSHookIvar<UILabel*>(self, "_titleLabel");
		titleLabel.textAlignment = NSTextAlignmentCenter;
	}

	return self;
}

- (void)_layoutCloseButton
{
	%orig;

	if(preferenceManager.lockedTabsEnabled)
	{
		[self _layoutLockButton];
	}
}

%new
- (void)_layoutLockButton
{
	if(self.active)
	{
		BOOL isRTL = NO;

		//Only iOS 10 and above adapt to RTL here
		if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0 && [self respondsToSelector:@selector(_sf_usesLeftToRightLayout)])
		{
			isRTL = ![self _sf_usesLeftToRightLayout];
		}

		if(isRTL)
		{
			self.lockButton.frame = CGRectMake(0,0,self.closeButton.bounds.size.width, self.closeButton.bounds.size.height);
		}
		else
		{
			self.lockButton.frame = CGRectMake(self.bounds.size.width - (self.closeButton.frame.origin.x + self.closeButton.bounds.size.width), self.closeButton.frame.origin.y, self.closeButton.bounds.size.width, self.closeButton.bounds.size.height);
		}
	}
}

- (void)_layoutTitleLabelUsingCachedTruncation
{
	%orig;

	if(preferenceManager.lockedTabsEnabled)
	{
		if(self.active)
		{
			UILabel* titleLabel = MSHookIvar<UILabel*>(self, "_titleLabel");

			if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_12_2)
			{
				UIImageView* iconView = MSHookIvar<UIImageView*>(self, "_iconView");
				iconView.hidden = YES;
			}

			BOOL isRTL = NO;

			//Only iOS 10 and above adapt to RTL here
			if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0 && [self respondsToSelector:@selector(_sf_usesLeftToRightLayout)])
			{
				isRTL = ![self _sf_usesLeftToRightLayout];
			}

			if(isRTL)
			{
				CGFloat titleWidth;

				if(!self.closeButton.hidden)
				{
					titleWidth = self.bounds.size.width - (self.closeButton.bounds.size.width + 1 + self.lockButton.bounds.size.width + 1);
				}
				else
				{
					titleWidth = self.bounds.size.width - (self.lockButton.bounds.size.width + 1 + 10);
				}

				titleLabel.frame = CGRectMake(self.lockButton.frame.origin.x + self.lockButton.bounds.size.width + 1, titleLabel.frame.origin.y, titleWidth, titleLabel.frame.size.height);
			}
			else
			{
				CGFloat x;

				if(!self.closeButton.hidden)
				{
					x = self.closeButton.frame.origin.x + self.closeButton.bounds.size.width + 1;
				}
				else
				{
					x = 10;
				}

				CGFloat titleWidth = self.bounds.size.width - (x + (self.bounds.size.width - self.lockButton.frame.origin.x));

				titleLabel.frame = CGRectMake(x, titleLabel.frame.origin.y, titleWidth, titleLabel.frame.size.height);
			}
		}
	}
}

- (void)updateTabBarStyle
{
	%orig;

	TabBar* tabBar = MSHookIvar<TabBar*>(self, "_tabBar");

	self.lockButton.tintColor = tabBar.barStyle.itemTitleColor;

	UIImage* imageClosed = [UIImage imageNamed:@"LockButton_Closed" inBundle:SPBundle compatibleWithTraitCollection:nil];
	UIImage* imageOpen = [UIImage imageNamed:@"LockButton_Open" inBundle:SPBundle compatibleWithTraitCollection:nil];

	[self.lockButton setImage:imageOpen forState:UIControlStateNormal];
	[self.lockButton setImage:imageClosed forState:UIControlStateSelected];
}

- (void)setActive:(BOOL)active
{
	BOOL changed = self.active != active;

	%orig;

	if(preferenceManager.lockedTabsEnabled)
	{
		if(changed)
		{
			if(active)
			{
				[self addSubview:self.lockButton];
			}
			else
			{
				[self.lockButton removeFromSuperview];
			}

			[UIView performWithoutAnimation:^
			{
				[self _layoutLockButton];
			}];
		}
	}
}

%end

void initTabBarItemView()
{
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0)
	{
		%init();
	}
}
