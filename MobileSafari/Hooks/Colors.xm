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
#import "../Defines.h"
#import "../Util.h"
#import "../Classes/SPPreferenceManager.h"
#ifndef NO_LIBCSCOLORPICKER
#import <CSColorPicker/CSColorPicker.h>
#else
@implementation UIColor (noLibCSColorPicker)

+ (UIColor*)cscp_colorFromHexString:(NSString*)hexString
{
	return [UIColor redColor];
}

@end
#endif

%group iOS8

%hook NavigationBarItem

//Fixes text color being overwritten by green on some sites
- (BOOL)textHasEVCertificateTint
{
	if(preferenceManager.topBarNormalURLFontColorEnabled || preferenceManager.topBarPrivateURLFontColorEnabled)
	{
		NavigationBar* navigationBar = MSHookIvar<NavigationBar*>(self, "_navigationBar");

		if(preferenceManager.topBarNormalURLFontColorEnabled && !navigationBar.usingLightControls)
		{
			return NO;
		}
		else if(preferenceManager.topBarPrivateURLFontColorEnabled && navigationBar.usingLightControls)
		{
			return NO;
		}
	}

	return %orig;
}

%end

%end

%group iOS9Up

%hook _SFNavigationBarItem

//Fixes text color being overwritten by green on some sites
- (BOOL)textHasEVCertificateTint
{
	if(preferenceManager.topBarNormalURLFontColorEnabled || preferenceManager.topBarPrivateURLFontColorEnabled)
	{
		_SFNavigationBar* navigationBar = MSHookIvar<_SFNavigationBar*>(self, "_navigationBar");

		if(preferenceManager.topBarNormalURLFontColorEnabled && !navigationBar.usingLightControls)
		{
			return NO;
		}
		else if(preferenceManager.topBarPrivateURLFontColorEnabled && navigationBar.usingLightControls)
		{
			return NO;
		}
	}

	return %orig;
}

%end

%end

%hook NavigationBar

//Top Bar Background Color
- (void)_updateBackdropStyle
{
	if(preferenceManager.topBarNormalBackgroundColorEnabled || preferenceManager.topBarPrivateBackgroundColorEnabled)
	{
		BOOL privateBrowsing = privateBrowsingEnabled(self.delegate);
		UIColor* colorToSet;

		if(preferenceManager.topBarNormalBackgroundColorEnabled && preferenceManager.topBarNormalBackgroundColor && !privateBrowsing)
		{
			colorToSet = [UIColor cscp_colorFromHexString:preferenceManager.topBarNormalBackgroundColor];
		}
		else if(preferenceManager.topBarPrivateBackgroundColorEnabled && preferenceManager.topBarPrivateBackgroundColor && privateBrowsing)
		{
			colorToSet = [UIColor cscp_colorFromHexString:preferenceManager.topBarPrivateBackgroundColor];
		}

		_UIBackdropView* backdrop = MSHookIvar<_UIBackdropView*>(self, "_backdrop");
		_UIBackdropViewSettings* newSettings;

		newSettings = [self _backdropInputSettings];

		if(colorToSet)
		{
			newSettings.colorTint = [colorToSet colorWithAlphaComponent:1.0];
			CGFloat alphaToSet;
			[colorToSet getRed:nil green:nil blue:nil alpha:&alphaToSet];
			newSettings.colorTintAlpha = alphaToSet;
			newSettings.colorTintMaskAlpha = alphaToSet;
			newSettings.grayscaleTintAlpha = 0;
			newSettings.usesGrayscaleTintView = NO;
			newSettings.usesColorTintView = YES;
		}

		[backdrop transitionToSettings:newSettings];

		return;
	}

	%orig;
}

//Top Bar Tint Color
- (void)setTintColor:(UIColor*)tintColor
{
	if(preferenceManager.topBarNormalTintColorEnabled || preferenceManager.topBarPrivateTintColorEnabled)
	{
		if(preferenceManager.topBarNormalTintColorEnabled && !self.usingLightControls)
		{
			return %orig([UIColor cscp_colorFromHexString:preferenceManager.topBarNormalTintColor]);
		}
		else if(preferenceManager.topBarPrivateTintColorEnabled && self.usingLightControls)
		{
			return %orig([UIColor cscp_colorFromHexString:preferenceManager.topBarPrivateTintColor]);
		}
	}

	%orig;
}

//Progress Bar Color
- (void)_updateProgressView
{
	%orig;
	if(preferenceManager.topBarNormalProgressBarColorEnabled || preferenceManager.topBarPrivateProgressBarColorEnabled)
	{
		_SFFluidProgressView* progressView = MSHookIvar<_SFFluidProgressView*>(self, "_progressView");

		BOOL privateBrowsing = privateBrowsingEnabled(self.delegate);

		if(preferenceManager.topBarNormalProgressBarColorEnabled && !privateBrowsing)
		{
			progressView.progressBarFillColor = [UIColor cscp_colorFromHexString:preferenceManager.topBarNormalProgressBarColor];
		}
		else if(preferenceManager.topBarPrivateProgressBarColorEnabled && privateBrowsing)
		{
			progressView.progressBarFillColor = [UIColor cscp_colorFromHexString:preferenceManager.topBarPrivateProgressBarColor];
		}
	}
}

- (void)_updateReaderButtonTint
{
	%orig;

	if(preferenceManager.topBarNormalReaderButtonColorEnabled || preferenceManager.topBarPrivateReaderButtonColorEnabled)
	{
		SFNavigationBarReaderButton* readerButton = MSHookIvar<SFNavigationBarReaderButton*>(self, "_readerButton");

		BOOL privateBrowsing = self.usingLightControls;

		UIColor* colorToSet;

		if(preferenceManager.topBarNormalReaderButtonColorEnabled && preferenceManager.topBarNormalReaderButtonColor && !privateBrowsing)
		{
			colorToSet = [UIColor cscp_colorFromHexString:preferenceManager.topBarNormalReaderButtonColor];
		}
		else if(preferenceManager.topBarPrivateReaderButtonColorEnabled && preferenceManager.topBarPrivateReaderButtonColor && privateBrowsing)
		{
			colorToSet = [UIColor cscp_colorFromHexString:preferenceManager.topBarPrivateReaderButtonColor];
		}

		if(colorToSet)
		{
			if([readerButton respondsToSelector:@selector(setGlyphTintColor:)])
			{
				[readerButton setGlyphTintColor:colorToSet];
			}
			else
			{
				UIImage* readerButtonImage;
				UIImage* readerButtonKnockoutImage;

				if([UIImage respondsToSelector:@selector(ss_imageNamed:)])
				{
					readerButtonImage = [UIImage ss_imageNamed:@"ReaderButton"];
					readerButtonKnockoutImage = [UIImage ss_imageNamed:@"ReaderButtonKnockout"];
				}
				else
				{
					readerButtonImage = [UIImage imageNamed:@"ReaderButton"];
					readerButtonKnockoutImage = [UIImage imageNamed:@"ReaderButtonKnockout"];
				}

				readerButtonImage = [readerButtonImage _flatImageWithColor:colorToSet];
				readerButtonKnockoutImage = [readerButtonKnockoutImage _flatImageWithColor:colorToSet];

				if([readerButtonImage respondsToSelector:@selector(imageFlippedForRightToLeftLayoutDirection)])
				{
					readerButtonKnockoutImage = [readerButtonKnockoutImage imageFlippedForRightToLeftLayoutDirection];
					readerButtonImage = [readerButtonImage imageFlippedForRightToLeftLayoutDirection];
				}

				UIImageView* glyphView = MSHookIvar<UIImageView*>(readerButton, "_glyphView");
				UIImageView* glyphKnockoutView = MSHookIvar<UIImageView*>(readerButton, "_glyphKnockoutView");
				[glyphView setImage:readerButtonImage];
				[glyphKnockoutView setImage:readerButtonKnockoutImage];
			}
		}
	}
}

%group iOS9Up

//URL Text Color
- (UIColor*)_URLTextColor
{
	if(preferenceManager.topBarNormalURLFontColorEnabled || preferenceManager.topBarPrivateURLFontColorEnabled)
	{
		if(preferenceManager.topBarNormalURLFontColorEnabled && !self.usingLightControls)
		{
			return [UIColor cscp_colorFromHexString:preferenceManager.topBarNormalURLFontColor];
		}
		else if(preferenceManager.topBarPrivateURLFontColorEnabled && self.usingLightControls)
		{
			return [UIColor cscp_colorFromHexString:preferenceManager.topBarPrivateURLFontColor];
		}
	}

	return %orig;
}

//Reload Button Color
- (UIColor*)_URLControlsColor
{
	if(preferenceManager.topBarNormalReloadButtonColorEnabled || preferenceManager.topBarPrivateReloadButtonColorEnabled)
	{
		if(preferenceManager.topBarNormalReloadButtonColorEnabled && !self.usingLightControls)
		{
			return [UIColor cscp_colorFromHexString:preferenceManager.topBarNormalReloadButtonColor];
		}
		else if(preferenceManager.topBarPrivateReloadButtonColorEnabled && self.usingLightControls)
		{
			return [UIColor cscp_colorFromHexString:preferenceManager.topBarPrivateReloadButtonColor];
		}
	}

	return %orig;
}

%end

//Text color of search placeholder text (on blank tab), needs to be less visible
- (UIColor*)_placeholderColor
{
	if(preferenceManager.topBarNormalURLFontColorEnabled || preferenceManager.topBarPrivateURLFontColorEnabled)
	{
		if(preferenceManager.topBarNormalURLFontColorEnabled && !self.usingLightControls)
		{
			return [[UIColor cscp_colorFromHexString:preferenceManager.topBarNormalURLFontColor] colorWithAlphaComponent:0.5];
		}
		else if(preferenceManager.topBarPrivateURLFontColorEnabled && self.usingLightControls)
		{
			return [[UIColor cscp_colorFromHexString:preferenceManager.topBarPrivateURLFontColor] colorWithAlphaComponent:0.5];
		}
	}

	return %orig;
}

%group iOS8

//URL Text Color
- (void)_updateTextColor
{
	%orig;

	if((preferenceManager.topBarNormalURLFontColorEnabled || preferenceManager.topBarPrivateURLFontColorEnabled))
	{
		UILabel* URLLabel = MSHookIvar<UILabel*>(self, "_URLLabel");

		if(![URLLabel.textColor isEqual:[self _placeholderColor]])
		{
			if(preferenceManager.topBarNormalURLFontColorEnabled && !self.usingLightControls)
			{
				URLLabel.textColor = [UIColor cscp_colorFromHexString:preferenceManager.topBarNormalURLFontColor];
			}
			else if(preferenceManager.topBarPrivateURLFontColorEnabled && self.usingLightControls)
			{
				URLLabel.textColor = [UIColor cscp_colorFromHexString:preferenceManager.topBarPrivateURLFontColor];
			}
		}
	}
}

- (void)_configureStopReloadButtonTintedImages
{
	%orig;

	if((preferenceManager.topBarNormalReloadButtonColorEnabled && !self.usingLightControls) || (preferenceManager.topBarPrivateReloadButtonColorEnabled && self.usingLightControls))
	{
		UIButton* reloadButton = MSHookIvar<UIButton*>(self, "_reloadButton");
		UIButton* stopButton = MSHookIvar<UIButton*>(self, "_stopButton");

		UIImage* reloadImage = [UIImage imageNamed:@"NavigationBarReload"];
		UIImage* stopImage = [UIImage imageNamed:@"NavigationBarStopLoading"];

		if(preferenceManager.topBarNormalReloadButtonColorEnabled && !self.usingLightControls)
		{
			[reloadButton setImage:[reloadImage _flatImageWithColor:[UIColor cscp_colorFromHexString:preferenceManager.topBarNormalReloadButtonColor]] forState:0];
			[stopButton setImage:[stopImage _flatImageWithColor:[UIColor cscp_colorFromHexString:preferenceManager.topBarNormalReloadButtonColor]] forState:0];
		}
		else if(preferenceManager.topBarPrivateReloadButtonColorEnabled && self.usingLightControls)
		{
			[reloadButton setImage:[reloadImage _flatImageWithColor:[UIColor cscp_colorFromHexString:preferenceManager.topBarPrivateReloadButtonColor]] forState:0];
			[stopButton setImage:[stopImage _flatImageWithColor:[UIColor cscp_colorFromHexString:preferenceManager.topBarPrivateReloadButtonColor]] forState:0];
		}
	}
}

%end

%group iOS10Up

//Lock Icon Color
- (UIColor*)_tintForLockImage:(BOOL)arg1
{
	if(preferenceManager.topBarNormalLockIconColorEnabled || preferenceManager.topBarPrivateLockIconColorEnabled)
	{
		if(preferenceManager.topBarNormalLockIconColorEnabled && !self.usingLightControls)
		{
			return [UIColor cscp_colorFromHexString:preferenceManager.topBarNormalLockIconColor];
		}
		else if(preferenceManager.topBarPrivateLockIconColorEnabled && self.usingLightControls)
		{
			return [UIColor cscp_colorFromHexString:preferenceManager.topBarPrivateLockIconColor];
		}
	}

	return %orig;
}

%end

%group iOS9Down

//Lock Icon Color
- (UIImage*)_lockImageUsingMiniatureVersion:(BOOL)miniatureVersion
{
	if(preferenceManager.topBarNormalLockIconColorEnabled && !self.usingLightControls)
	{
		return [self _lockImageWithTint:[UIColor cscp_colorFromHexString:preferenceManager.topBarNormalLockIconColor] usingMiniatureVersion:miniatureVersion];
	}
	else if(preferenceManager.topBarPrivateLockIconColorEnabled && self.usingLightControls)
	{
		return [self _lockImageWithTint:[UIColor cscp_colorFromHexString:preferenceManager.topBarPrivateLockIconColor] usingMiniatureVersion:miniatureVersion];
	}

	return %orig;
}

%end
%end

%hook TabThumbnailView

%group iOS11Up

//Tab Title Color
- (UIColor*)titleColor
{
	if(preferenceManager.tabTitleBarNormalTextColorEnabled || preferenceManager.tabTitleBarPrivateTextColorEnabled)
	{
		if(preferenceManager.tabTitleBarNormalTextColorEnabled && !self.usesDarkTheme)
		{
			return [UIColor cscp_colorFromHexString:preferenceManager.tabTitleBarNormalTextColor];
		}
		else if(preferenceManager.tabTitleBarPrivateTextColorEnabled && self.usesDarkTheme)
		{
			return [UIColor cscp_colorFromHexString:preferenceManager.tabTitleBarPrivateTextColor];
		}
	}

	return %orig;
}

//Tab Background Color
- (UIColor*)headerBackgroundColor
{
	if(preferenceManager.tabTitleBarNormalBackgroundColorEnabled || preferenceManager.tabTitleBarPrivateBackgroundColorEnabled)
	{
		if(preferenceManager.tabTitleBarNormalBackgroundColorEnabled && !self.usesDarkTheme)
		{
			return [UIColor cscp_colorFromHexString:preferenceManager.tabTitleBarNormalBackgroundColor];
		}
		else if(preferenceManager.tabTitleBarPrivateBackgroundColorEnabled && self.usesDarkTheme)
		{
			return [UIColor cscp_colorFromHexString:preferenceManager.tabTitleBarPrivateBackgroundColor];
		}
	}

	return %orig;
}

%end

%group iOS10Down

- (void)setTitleColor:(UIColor*)titleColor
{
	if(preferenceManager.tabTitleBarNormalTextColorEnabled || preferenceManager.tabTitleBarPrivateTextColorEnabled || preferenceManager.tabTitleBarNormalBackgroundColorEnabled || preferenceManager.tabTitleBarPrivateBackgroundColorEnabled)
	{
		BOOL privateMode = titleColor != nil;

		//Tab Header Background Color
		if(preferenceManager.tabTitleBarNormalBackgroundColorEnabled || preferenceManager.tabTitleBarPrivateBackgroundColorEnabled)
		{
			UIView* headerView = MSHookIvar<UILabel*>(self, "_headerView");

			if(preferenceManager.tabTitleBarNormalBackgroundColorEnabled && !privateMode)
			{
				headerView.backgroundColor = [UIColor cscp_colorFromHexString:preferenceManager.tabTitleBarNormalBackgroundColor];
			}
			else if(preferenceManager.tabTitleBarPrivateBackgroundColorEnabled && privateMode)
			{
				headerView.backgroundColor = [UIColor cscp_colorFromHexString:preferenceManager.tabTitleBarPrivateBackgroundColor];
			}
			else
			{
				headerView.backgroundColor = nil;
			}
		}

		//Tab Header Title Color
		if(preferenceManager.tabTitleBarNormalTextColorEnabled || preferenceManager.tabTitleBarPrivateTextColorEnabled)
		{
			if(preferenceManager.tabTitleBarNormalTextColorEnabled && !privateMode)
			{
				return %orig([UIColor cscp_colorFromHexString:preferenceManager.tabTitleBarNormalTextColor]);
			}
			else if(preferenceManager.tabTitleBarPrivateTextColorEnabled && privateMode)
			{
				return %orig([UIColor cscp_colorFromHexString:preferenceManager.tabTitleBarPrivateTextColor]);
			}
		}
	}

	return %orig;
}

%end

%end

%group iOS8

//Tab Bar Title Color
%hook TabBarItemView

- (void)_updateTitleBlends
{
	%orig;

	if(preferenceManager.topBarNormalTabBarTitleColorEnabled || preferenceManager.topBarPrivateTabBarTitleColorEnabled)
	{
		TabBar* tabBar = MSHookIvar<TabBar*>(self, "_tabBar");
		UILabel* titleLabel = MSHookIvar<UILabel*>(self, "_titleLabel");
		UILabel* titleOverlayLabel = MSHookIvar<UILabel*>(self, "_titleOverlayLabel");

		if(preferenceManager.topBarNormalTabBarTitleColorEnabled && ((TabBar8*)tabBar).barStyle == 0)
		{
			[titleLabel.layer setCompositingFilter:nil];

			if(self.active)
			{
				CGFloat activeTitleAlpha = 1.0;

				[[UIColor cscp_colorFromHexString:preferenceManager.topBarNormalTabBarTitleColor] getRed:nil green:nil blue:nil alpha:&activeTitleAlpha];

				titleLabel.alpha = activeTitleAlpha;
				titleOverlayLabel.alpha = activeTitleAlpha;
			}
			else
			{
				titleLabel.alpha = preferenceManager.topBarNormalTabBarInactiveTitleOpacity;
				titleOverlayLabel.alpha = preferenceManager.topBarNormalTabBarInactiveTitleOpacity;
			}
		}
		else if(preferenceManager.topBarPrivateTabBarTitleColorEnabled && ((TabBar8*)tabBar).barStyle == 1)
		{
			[titleLabel.layer setCompositingFilter:nil];

			if(self.active)
			{
				CGFloat activeTitleAlpha = 1.0;

				[[UIColor cscp_colorFromHexString:preferenceManager.topBarPrivateTabBarTitleColor] getRed:nil green:nil blue:nil alpha:&activeTitleAlpha];

				titleLabel.alpha = activeTitleAlpha;
				titleOverlayLabel.alpha = activeTitleAlpha;
			}
			else
			{
				titleLabel.alpha = preferenceManager.topBarPrivateTabBarInactiveTitleOpacity;
				titleOverlayLabel.alpha = preferenceManager.topBarPrivateTabBarInactiveTitleOpacity;
			}
		}
	}
}

- (void)_layoutTitleLabelUsingCachedTruncation
{
	%orig;

	if(preferenceManager.topBarNormalTabBarTitleColorEnabled || preferenceManager.topBarPrivateTabBarTitleColorEnabled)
	{
		TabBar* tabBar = MSHookIvar<TabBar*>(self, "_tabBar");
		UILabel* titleLabel = MSHookIvar<UILabel*>(self, "_titleLabel");

		if(preferenceManager.topBarNormalTabBarTitleColorEnabled && ((TabBar8*)tabBar).barStyle == 0)
		{
			titleLabel.textColor = [[UIColor cscp_colorFromHexString:preferenceManager.topBarNormalTabBarTitleColor] colorWithAlphaComponent:1.0];
		}
		else if(preferenceManager.topBarPrivateTabBarTitleColorEnabled && ((TabBar8*)tabBar).barStyle == 1)
		{
			titleLabel.textColor = [[UIColor cscp_colorFromHexString:preferenceManager.topBarPrivateTabBarTitleColor] colorWithAlphaComponent:1.0];
		}
	}
}

- (void)_layoutCloseButton
{
	%orig;

	if(preferenceManager.topBarNormalTabBarCloseButtonColorEnabled || preferenceManager.topBarPrivateTabBarCloseButtonColorEnabled)
	{
		TabBar* tabBar = MSHookIvar<TabBar*>(self, "_tabBar");
		UIColor* colorToSet;

		if(preferenceManager.topBarNormalTabBarCloseButtonColorEnabled && ((TabBar8*)tabBar).barStyle == 0)
		{
			colorToSet = [UIColor cscp_colorFromHexString:preferenceManager.topBarNormalTabBarCloseButtonColor];
			//titleLabel.textColor = [[UIColor cscp_colorFromHexString:preferenceManager.topBarNormalTabBarTitleColor] colorWithAlphaComponent:1.0];
		}
		else if(preferenceManager.topBarPrivateTabBarCloseButtonColorEnabled && ((TabBar8*)tabBar).barStyle == 1)
		{
			colorToSet = [UIColor cscp_colorFromHexString:preferenceManager.topBarPrivateTabBarCloseButtonColor];
			//titleLabel.textColor = [[UIColor cscp_colorFromHexString:preferenceManager.topBarPrivateTabBarTitleColor] colorWithAlphaComponent:1.0];
		}

		if(colorToSet)
		{
			[self.closeButton setImage:[self.closeButton.currentImage _flatImageWithColor:colorToSet] forState:UIControlStateNormal];
		}
	}
}

%end

%end

%group iOS9Up

//Tab Bar Title Color
%hook TabBarStyle

+ (TabBarStyle*)normalStyle
{
	TabBarStyle* normalStyle = %orig;

	if(preferenceManager.topBarNormalTabBarTitleColorEnabled)
	{
		UIColor* topBarNormalTabBarTitleColor = [UIColor cscp_colorFromHexString:preferenceManager.topBarNormalTabBarTitleColor];

		MSHookIvar<UIColor*>(normalStyle, "_itemTitleColor") = [topBarNormalTabBarTitleColor colorWithAlphaComponent:1.0];

		CGFloat activeTitleAlpha = 1.0;

		[topBarNormalTabBarTitleColor getRed:nil green:nil blue:nil alpha:&activeTitleAlpha];

		MSHookIvar<CGFloat>(normalStyle, "_itemActiveTitleAlpha") = activeTitleAlpha;
		MSHookIvar<CGFloat>(normalStyle, "_itemInactiveTitleAlpha") = preferenceManager.topBarNormalTabBarInactiveTitleOpacity;

		//This filter causes the title color to go weird in some cases, so we just disable it
		MSHookIvar<id>(normalStyle, "_itemInactiveTitleCompositingFilter") = nil;
	}

	if(preferenceManager.topBarNormalTabBarCloseButtonColorEnabled)
	{
		UIColor* topBarNormalTabBarCloseButtonColor = [UIColor cscp_colorFromHexString:preferenceManager.topBarNormalTabBarCloseButtonColor];

		MSHookIvar<UIImage*>(normalStyle, "_itemCloseButtonImage") = [%c(TabBarStyle) _closeButtonWithColor:topBarNormalTabBarCloseButtonColor];
		MSHookIvar<UIImage*>(normalStyle, "_itemCloseButtonOverlayImage") = [%c(TabBarStyle) _closeButtonWithColor:topBarNormalTabBarCloseButtonColor];

		//This filter causes the color to go weird, so we just disable it
		MSHookIvar<id>(normalStyle, "_itemCloseButtonOverlayCompositingFilter") = nil;
	}

	return normalStyle;
}

+ (TabBarStyle*)privateBrowsingStyle
{
	TabBarStyle* privateBrowsingStyle = %orig;

	if(preferenceManager.topBarPrivateTabBarTitleColorEnabled)
	{
		UIColor* topBarPrivateTabBarTitleColor = [UIColor cscp_colorFromHexString:preferenceManager.topBarPrivateTabBarTitleColor];

		MSHookIvar<UIColor*>(privateBrowsingStyle, "_itemTitleColor") = [topBarPrivateTabBarTitleColor colorWithAlphaComponent:1.0];

		CGFloat activeTitleAlpha = 1.0;

		[topBarPrivateTabBarTitleColor getRed:nil green:nil blue:nil alpha:&activeTitleAlpha];

		MSHookIvar<CGFloat>(privateBrowsingStyle, "_itemActiveTitleAlpha") = activeTitleAlpha;
		MSHookIvar<CGFloat>(privateBrowsingStyle, "_itemInactiveTitleAlpha") = preferenceManager.topBarPrivateTabBarInactiveTitleOpacity;

		//This filter causes the title color to go weird in some cases, so we just disable it
		MSHookIvar<id>(privateBrowsingStyle, "_itemInactiveTitleCompositingFilter") = nil;
	}

	if(preferenceManager.topBarPrivateTabBarCloseButtonColorEnabled)
	{
		UIColor* topBarNormalTabBarCloseButtonColor = [UIColor cscp_colorFromHexString:preferenceManager.topBarPrivateTabBarCloseButtonColor];

		MSHookIvar<UIImage*>(privateBrowsingStyle, "_itemCloseButtonImage") = [%c(TabBarStyle) _closeButtonWithColor:topBarNormalTabBarCloseButtonColor];
		MSHookIvar<UIImage*>(privateBrowsingStyle, "_itemCloseButtonOverlayImage") = [%c(TabBarStyle) _closeButtonWithColor:topBarNormalTabBarCloseButtonColor];

		//This filter causes the color to go weird, so we just disable it
		MSHookIvar<id>(privateBrowsingStyle, "_itemCloseButtonOverlayCompositingFilter") = nil;
	}

	return privateBrowsingStyle;
}

%end

%end

%hook TabOverview

- (void)layoutSubviews
{
	%orig;

	if(preferenceManager.tabSwitcherNormalToolbarBackgroundColorEnabled || preferenceManager.tabSwitcherPrivateToolbarBackgroundColorEnabled)
	{
		_UIBackdropView* header = MSHookIvar<_UIBackdropView*>(self, "_header");
		_UIBackdropViewSettings* settings = [_UIBackdropViewSettings settingsForPrivateStyle:2030];

		if([header isKindOfClass:NSClassFromString(@"_UIBackdropView")])
		{
			BOOL privateBrowsing = privateBrowsingEnabled(MSHookIvar<BrowserController*>(self.delegate, "_browserController"));

			UIColor* colorToSet;

			if(preferenceManager.tabSwitcherNormalToolbarBackgroundColorEnabled && preferenceManager.tabSwitcherNormalToolbarBackgroundColor && !privateBrowsing)
			{
				colorToSet = [UIColor cscp_colorFromHexString:preferenceManager.tabSwitcherNormalToolbarBackgroundColor];
			}
			else if(preferenceManager.tabSwitcherPrivateToolbarBackgroundColorEnabled && preferenceManager.tabSwitcherPrivateToolbarBackgroundColor && privateBrowsing)
			{
				colorToSet = [UIColor cscp_colorFromHexString:preferenceManager.tabSwitcherPrivateToolbarBackgroundColor];
			}

			if(colorToSet)
			{
				settings.usesGrayscaleTintView = NO;
				settings.usesColorTintView = YES;
				settings.colorTint = [colorToSet colorWithAlphaComponent:1.0];
				CGFloat alpha;
				[colorToSet getRed:nil green:nil blue:nil alpha:&alpha];
				settings.colorTintAlpha = alpha;
				settings.grayscaleTintAlpha = 0;
			}

			[header transitionToSettings:settings];
		}
	}
}

%end

%hook BrowserToolbar

%new
- (void)updateCustomBackgroundColorForStyle:(NSUInteger)style
{
	BrowserController* browserController = browserControllerForBrowserToolbar(self);

	_UIBackdropView* backgroundView = MSHookIvar<_UIBackdropView*>(self, "_backgroundView");

	BOOL privateBrowsing = privateBrowsingEnabled(browserController);

	UIColor* colorToSet;

	if(browserControllerIsShowingTabView(browserController))
	{
		if(preferenceManager.tabSwitcherNormalToolbarBackgroundColorEnabled || preferenceManager.tabSwitcherPrivateToolbarBackgroundColorEnabled)
		{
			if(preferenceManager.tabSwitcherNormalToolbarBackgroundColorEnabled && preferenceManager.tabSwitcherNormalToolbarBackgroundColor && !privateBrowsing)
			{
				colorToSet = [UIColor cscp_colorFromHexString:preferenceManager.tabSwitcherNormalToolbarBackgroundColor];
			}
			else if(preferenceManager.tabSwitcherPrivateToolbarBackgroundColorEnabled && preferenceManager.tabSwitcherPrivateToolbarBackgroundColor && privateBrowsing)
			{
				colorToSet = [UIColor cscp_colorFromHexString:preferenceManager.tabSwitcherPrivateToolbarBackgroundColor];
			}
		}
	}
	else
	{
		if((preferenceManager.bottomBarNormalBackgroundColorEnabled || preferenceManager.bottomBarPrivateBackgroundColorEnabled))
		{
			if(preferenceManager.bottomBarNormalBackgroundColorEnabled && preferenceManager.bottomBarNormalBackgroundColor && !privateBrowsing)
			{
				colorToSet = [UIColor cscp_colorFromHexString:preferenceManager.bottomBarNormalBackgroundColor];
			}
			else if(preferenceManager.bottomBarPrivateBackgroundColorEnabled && preferenceManager.bottomBarPrivateBackgroundColor && privateBrowsing)
			{
				colorToSet = [UIColor cscp_colorFromHexString:preferenceManager.bottomBarPrivateBackgroundColor];
			}
		}
	}

	_UIBackdropViewSettings* newSettings;

	if(colorToSet)
	{
		newSettings = [[%c(_UIBackdropViewSettingsColored) alloc] init];

		newSettings.colorTint = [colorToSet colorWithAlphaComponent:1.0];
		CGFloat alphaToSet;
		[colorToSet getRed:nil green:nil blue:nil alpha:&alphaToSet];
		newSettings.colorTintAlpha = alphaToSet;
	}
	else
	{
		if([self respondsToSelector:@selector(_backdropInputSettings)])
		{
			newSettings = [self _backdropInputSettings];
		}
	}

	if([self respondsToSelector:@selector(_tintUsesDarkTheme)])
	{
		MSHookIvar<UIView*>(self, "_separator").alpha = [self _tintUsesDarkTheme] ^ 1;
	}
	else if([self respondsToSelector:@selector(hasDarkBackground)])
	{
		MSHookIvar<UIView*>(self, "_separator").alpha = (CGFloat) ![self hasDarkBackground];
	}

	if(newSettings)
	{
		[backgroundView transitionToSettings:newSettings];
		[self updateTintColor];
	}
	else
	{
		if(style == 1)
		{
			[backgroundView transitionToPrivateStyle:2030];
		}
		else
		{
			[backgroundView transitionToPrivateStyle:2010];
		}
	}

	return;
}

//Bottom Bar Tint Color
- (void)setTintColor:(UIColor*)tintColor
{
	if(preferenceManager.topBarNormalTintColorEnabled || preferenceManager.topBarPrivateTintColorEnabled || preferenceManager.bottomBarNormalTintColorEnabled || preferenceManager.bottomBarPrivateTintColorEnabled)
	{
		NSInteger placement = MSHookIvar<NSInteger>(self, "_placement");

		BOOL privateMode;
		if([self respondsToSelector:@selector(hasDarkBackground)])
		{
			privateMode = self.hasDarkBackground;
		}
		else
		{
			privateMode = MSHookIvar<BOOL>(self, "_usesDarkTheme");
		}

		if(placement == 0)
		{
			if(preferenceManager.topBarNormalTintColorEnabled || preferenceManager.topBarPrivateTintColorEnabled)
			{
				if(preferenceManager.topBarNormalTintColorEnabled && !privateMode)
				{
					return %orig([UIColor cscp_colorFromHexString:preferenceManager.topBarNormalTintColor]);
				}
				else if(preferenceManager.topBarPrivateTintColorEnabled && privateMode)
				{
					return %orig([UIColor cscp_colorFromHexString:preferenceManager.topBarPrivateTintColor]);
				}
			}
		}
		else
		{
			if(preferenceManager.bottomBarNormalTintColorEnabled || preferenceManager.bottomBarPrivateTintColorEnabled)
			{
				if(preferenceManager.bottomBarNormalTintColorEnabled && !privateMode)
				{
					return %orig([UIColor cscp_colorFromHexString:preferenceManager.bottomBarNormalTintColor]);
				}
				else if(preferenceManager.bottomBarPrivateTintColorEnabled && privateMode)
				{
					return %orig([UIColor cscp_colorFromHexString:preferenceManager.bottomBarPrivateTintColor]);
				}
			}
		}
	}

	%orig;
}

//Bottom Bar Background Color

%group iOS10Up

- (void)setTintStyle:(NSUInteger)style
{
	if(preferenceManager.bottomBarNormalBackgroundColorEnabled || preferenceManager.bottomBarPrivateBackgroundColorEnabled || preferenceManager.tabSwitcherNormalToolbarBackgroundColorEnabled || preferenceManager.tabSwitcherPrivateToolbarBackgroundColorEnabled)
	{
		NSInteger placement = MSHookIvar<NSInteger>(self, "_placement");
		if(placement == 1)
		{
			MSHookIvar<NSUInteger>(self, "_tintStyle") = style;
			[self updateCustomBackgroundColorForStyle:style];
			return;
		}
	}

	%orig;
}

%end

%group iOS9Down

- (void)setHasDarkBackground:(BOOL)darkBackground
{
	if(preferenceManager.bottomBarNormalBackgroundColorEnabled || preferenceManager.bottomBarPrivateBackgroundColorEnabled || preferenceManager.tabSwitcherNormalToolbarBackgroundColorEnabled || preferenceManager.tabSwitcherPrivateToolbarBackgroundColorEnabled)
	{
		NSInteger placement = MSHookIvar<NSInteger>(self, "_placement");
		if(placement == 1)
		{
			MSHookIvar<BOOL>(self, "_hasDarkBackground") = darkBackground;
			[self updateCustomBackgroundColorForStyle:darkBackground];
			return;
		}
	}

	%orig;
}

%end

%end

%group iOS12_1_4_down

%hook BrowserRootViewController

- (void)setPreferredStatusBarStyle:(UIStatusBarStyle)statusBarStyle
{
	if([preferenceManager topBarNormalStatusBarStyleEnabled] || [preferenceManager topBarPrivateStatusBarStyleEnabled])
	{
		BrowserController* browserController;

		if([self respondsToSelector:@selector(browserController)])
		{
			browserController = self.browserController;
		}
		else
		{
			browserController = browserControllers().firstObject;
		}

		if(!browserControllerIsShowingTabView(browserController))
		{
			BOOL privateMode = (statusBarStyle == UIStatusBarStyleLightContent);

			if(!privateMode && [preferenceManager topBarNormalStatusBarStyleEnabled])
			{
				return %orig(preferenceManager.topBarNormalStatusBarStyle);
			}
			else if(privateMode && [preferenceManager topBarPrivateStatusBarStyleEnabled])
			{
				return %orig(preferenceManager.topBarPrivateStatusBarStyle);
			}
		}
	}

	return %orig;
}

%end

%end

%group iOS12_2Up

%hook BrowserRootViewController

- (NSUInteger)preferredStatusBarStyle
{
	if([preferenceManager topBarNormalStatusBarStyleEnabled] || [preferenceManager topBarPrivateStatusBarStyleEnabled])
	{
		BrowserController* browserController;

		if([self respondsToSelector:@selector(browserController)])
		{
			browserController = self.browserController;
		}
		else
		{
			browserController = browserControllers().firstObject;
		}

		if(!browserControllerIsShowingTabView(browserController))
		{
			BOOL privateMode = privateBrowsingEnabled(browserController);

			if(!privateMode && [preferenceManager topBarNormalStatusBarStyleEnabled])
			{
				return preferenceManager.topBarNormalStatusBarStyle;
			}
			else if(privateMode && [preferenceManager topBarPrivateStatusBarStyleEnabled])
			{
				return preferenceManager.topBarPrivateStatusBarStyle;
			}
		}
	}

	return %orig;
}

%end

%end

void initColors()
{
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0)
	{
		return;
	}

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0)
	{
		%init(iOS9Up)
	}
	else
	{
		%init(iOS8)
	}

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0)
	{
		%init(iOS10Up)
	}
	else
	{
		%init(iOS9Down)
	}

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0)
	{
		%init(iOS11Up)
	}
	else
	{
		%init(iOS10Down)
	}

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_12_2)
	{
		%init(iOS12_2Up);
	}
	else
	{
		%init(iOS12_1_4_down);
	}

	%init();
}
