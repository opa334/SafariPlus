// TabThumbnailView.xm
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
		[self.lockButton setImage:[UIImage imageNamed:@"LockButtonOpen" inBundle:SPBundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
		[self.lockButton setImage:[UIImage imageNamed:@"LockButtonClosed" inBundle:SPBundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
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
