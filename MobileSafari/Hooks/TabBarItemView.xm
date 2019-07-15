// TabBarItemView.xm
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
