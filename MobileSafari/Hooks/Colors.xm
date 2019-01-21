// Colors.xm
// (c) 2018 opa334

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
#import "../Shared.h"
#import "../Classes/SPPreferenceManager.h"

/******* Top Bar Background View Class *******/

@interface NavigationBarColorView : UIView
@end

%subclass NavigationBarColorView : UIView

//Use custom color instead
- (void)setBackgroundColor:(UIColor*)backgroundColor
{
  CGFloat white, alpha;

  [backgroundColor getWhite:&white alpha:&alpha];

  if(preferenceManager.topBarNormalBackgroundColorEnabled && white >= alpha)
  {
    return %orig([preferenceManager topBarNormalBackgroundColor]);
  }
  else if(preferenceManager.topBarPrivateBackgroundColorEnabled && white < alpha)
  {
    return %orig([preferenceManager topBarPrivateBackgroundColor]);
  }

  %orig;
}

//Don't hide this view if custom color is active
- (void)setHidden:(BOOL)hidden
{
  if(([self.backgroundColor isEqual:[preferenceManager topBarNormalBackgroundColor]] || [self.backgroundColor isEqual:[preferenceManager topBarPrivateBackgroundColor]]))
  {
    %orig(NO);
    return;
  }

  %orig;
}

%end


/******* Bottom Bar Background View Class *******/

@interface BrowserToolbarColorView : UIView
@end

%subclass BrowserToolbarColorView : UIView

//Use custom color instead
- (void)setBackgroundColor:(UIColor*)backgroundColor
{
  CGFloat white, alpha;

  [backgroundColor getWhite:&white alpha:&alpha];

  if(preferenceManager.bottomBarNormalBackgroundColorEnabled && white >= alpha)
  {
    return %orig([preferenceManager bottomBarNormalBackgroundColor]);
  }
  else if(preferenceManager.bottomBarPrivateBackgroundColorEnabled && white < alpha)
  {
    return %orig([preferenceManager bottomBarPrivateBackgroundColor]);
  }

  %orig;
}

//Don't hide this view if custom color is active
- (void)setHidden:(BOOL)hidden
{
  if(([self.backgroundColor isEqual:[preferenceManager bottomBarNormalBackgroundColor]] || [self.backgroundColor isEqual:[preferenceManager bottomBarPrivateBackgroundColor]]))
  {
    %orig(NO);
    return;
  }

  %orig;
}

%end


/******* Color Hooks *******/

%group iOS8

%hook NavigationBarBackdrop

- (NavigationBarBackdrop*)initWithSettings:(_UIBackdropViewSettings*)settings
{
  NavigationBarBackdrop* orig = %orig;

  if(preferenceManager.topBarNormalBackgroundColorEnabled || preferenceManager.topBarPrivateBackgroundColorEnabled)
  {
    //grayscaleTintView cannot be hooked directly, so we change the class to our own
    object_setClass(orig.grayscaleTintView, objc_getClass("NavigationBarColorView"));
  }

  return orig;
}

%end

%end

%group iOS9Up

%hook _SFNavigationBarBackdrop

//Top Bar Background Color
- (_SFNavigationBarBackdrop*)initWithSettings:(_UIBackdropViewSettings*)settings
{
  _SFNavigationBarBackdrop* orig = %orig;

  if(preferenceManager.topBarNormalBackgroundColorEnabled || preferenceManager.topBarPrivateBackgroundColorEnabled)
  {
    //grayscaleTintView cannot be hooked directly, so we change the class to our own
    object_setClass(orig.grayscaleTintView, objc_getClass("NavigationBarColorView"));
  }

  return orig;
}

%end

%end

%hook NavigationBar

//Top Bar Tint Color
- (void)setTintColor:(UIColor*)tintColor
{
  if(preferenceManager.topBarNormalTintColorEnabled || preferenceManager.topBarPrivateTintColorEnabled)
  {
    if(preferenceManager.topBarNormalTintColorEnabled && !self.usingLightControls)
    {
      return %orig([preferenceManager topBarNormalTintColor]);
    }
    else if(preferenceManager.topBarPrivateTintColorEnabled && self.usingLightControls)
    {
      return %orig([preferenceManager topBarPrivateTintColor]);
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

    if(preferenceManager.topBarNormalProgressBarColorEnabled && !self.usingLightControls)
    {
      progressView.progressBarFillColor = [preferenceManager topBarNormalProgressBarColor];
    }
    else if(preferenceManager.topBarPrivateProgressBarColorEnabled && self.usingLightControls)
    {
      progressView.progressBarFillColor = [preferenceManager topBarPrivateProgressBarColor];
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
      return [preferenceManager topBarNormalURLFontColor];
    }
    else if(preferenceManager.topBarPrivateURLFontColorEnabled && self.usingLightControls)
    {
      return [preferenceManager topBarPrivateURLFontColor];
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
      return [preferenceManager topBarNormalReloadButtonColor];
    }
    else if(preferenceManager.topBarPrivateReloadButtonColorEnabled && self.usingLightControls)
    {
      return [preferenceManager topBarPrivateReloadButtonColor];
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
      return [[preferenceManager topBarNormalURLFontColor] colorWithAlphaComponent:0.5];
    }
    else if(preferenceManager.topBarPrivateURLFontColorEnabled && self.usingLightControls)
    {
      return [[preferenceManager topBarPrivateURLFontColor] colorWithAlphaComponent:0.5];
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
        URLLabel.textColor = [preferenceManager topBarNormalURLFontColor];
      }
      else if(preferenceManager.topBarPrivateURLFontColorEnabled && self.usingLightControls)
      {
        URLLabel.textColor = [preferenceManager topBarPrivateURLFontColor];
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
      [reloadButton setImage:[reloadImage _flatImageWithColor:[preferenceManager topBarNormalReloadButtonColor]] forState:0];
      [stopButton setImage:[stopImage _flatImageWithColor:[preferenceManager topBarNormalReloadButtonColor]] forState:0];
    }
    else if(preferenceManager.topBarPrivateReloadButtonColorEnabled && self.usingLightControls)
    {
      [reloadButton setImage:[reloadImage _flatImageWithColor:[preferenceManager topBarPrivateReloadButtonColor]] forState:0];
      [stopButton setImage:[stopImage _flatImageWithColor:[preferenceManager topBarPrivateReloadButtonColor]] forState:0];
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
      return [preferenceManager topBarNormalLockIconColor];
    }
    else if(preferenceManager.topBarPrivateLockIconColorEnabled && self.usingLightControls)
    {
      return [preferenceManager topBarPrivateLockIconColor];
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
    return [self _lockImageWithTint:[preferenceManager topBarNormalLockIconColor] usingMiniatureVersion:miniatureVersion];
  }
  else if(preferenceManager.topBarPrivateLockIconColorEnabled && self.usingLightControls)
  {
    return [self _lockImageWithTint:[preferenceManager topBarPrivateLockIconColor] usingMiniatureVersion:miniatureVersion];
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
      return [preferenceManager tabTitleBarNormalTextColor];
    }
    else if(preferenceManager.tabTitleBarPrivateTextColorEnabled && self.usesDarkTheme)
    {
      return [preferenceManager tabTitleBarPrivateTextColor];
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
      return [preferenceManager tabTitleBarNormalBackgroundColor];
    }
    else if(preferenceManager.tabTitleBarPrivateBackgroundColorEnabled && self.usesDarkTheme)
    {
      return [preferenceManager tabTitleBarPrivateBackgroundColor];
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
        headerView.backgroundColor = [preferenceManager tabTitleBarNormalBackgroundColor];
      }
      else if(preferenceManager.tabTitleBarPrivateBackgroundColorEnabled && privateMode)
      {
        headerView.backgroundColor = [preferenceManager tabTitleBarPrivateBackgroundColor];
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
        return %orig([preferenceManager tabTitleBarNormalTextColor]);
      }
      else if(preferenceManager.tabTitleBarPrivateTextColorEnabled && privateMode)
      {
        return %orig([preferenceManager tabTitleBarPrivateTextColor]);
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

- (void)_layoutTitleLabelUsingCachedTruncation
{
  %orig;

  if(preferenceManager.topBarNormalTabBarTitleColorEnabled || preferenceManager.topBarPrivateTabBarTitleColorEnabled)
  {
    TabBar* tabBar = MSHookIvar<TabBar*>(self, "_tabBar");

    BrowserController* browserController = MSHookIvar<BrowserController*>(tabBar.delegate, "_browserController");

    BOOL privateMode = privateBrowsingEnabled(browserController);

    UILabel* titleLabel = MSHookIvar<UILabel*>(self, "_titleLabel");

    if(preferenceManager.topBarNormalTabBarTitleColorEnabled && !privateMode)
    {
      titleLabel.textColor = [preferenceManager topBarNormalTabBarTitleColor];
    }
    else if(preferenceManager.topBarPrivateTabBarTitleColorEnabled && privateMode)
    {
      titleLabel.textColor = [preferenceManager topBarPrivateTabBarTitleColor];
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
    MSHookIvar<UIColor*>(normalStyle, "_itemTitleColor") = [preferenceManager topBarNormalTabBarTitleColor];

    //This filter causes the title color to go weird in some cases, so we just disable it
    MSHookIvar<id>(normalStyle, "_itemInactiveTitleCompositingFilter") = nil;
  }

  return normalStyle;
}

+ (TabBarStyle*)privateBrowsingStyle
{
  TabBarStyle* privateBrowsingStyle = %orig;

  if(preferenceManager.topBarPrivateTabBarTitleColorEnabled)
  {
    MSHookIvar<UIColor*>(privateBrowsingStyle, "_itemTitleColor") = [preferenceManager topBarPrivateTabBarTitleColor];

    //This filter causes the title color to go weird in some cases, so we just disable it
    MSHookIvar<id>(privateBrowsingStyle, "_itemInactiveTitleCompositingFilter") = nil;
  }

  return privateBrowsingStyle;
}

%end

%end

%hook BrowserToolbar

//Bottom Bar Color
- (id)initWithPlacement:(NSInteger)placement
{
  id orig = %orig;

  if(preferenceManager.bottomBarNormalBackgroundColorEnabled || preferenceManager.bottomBarPrivateBackgroundColorEnabled)
  {
    _UIBackdropView* backgroundView = MSHookIvar<_UIBackdropView*>(orig, "_backgroundView");

    //grayscaleTintView cannot be hooked directly, so we change the class to our own
    object_setClass(backgroundView.grayscaleTintView, objc_getClass("BrowserToolbarColorView"));
  }

  return orig;
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
          return %orig([preferenceManager topBarNormalTintColor]);
        }
        else if(preferenceManager.topBarPrivateTintColorEnabled && privateMode)
        {
          return %orig([preferenceManager topBarPrivateTintColor]);
        }
      }
    }
    else
    {
      if(preferenceManager.bottomBarNormalTintColorEnabled || preferenceManager.bottomBarPrivateTintColorEnabled)
      {
        if(preferenceManager.bottomBarNormalTintColorEnabled && !privateMode)
        {
          return %orig([preferenceManager bottomBarNormalTintColor]);
        }
        else if(preferenceManager.bottomBarPrivateTintColorEnabled && privateMode)
        {
          return %orig([preferenceManager bottomBarPrivateTintColor]);
        }
      }
    }
  }

  %orig;
}

%end

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

    BOOL showingTabView;

    if([browserController respondsToSelector:@selector(isShowingTabView)])
    {
      showingTabView = browserController.showingTabView;
    }
    else
    {
      showingTabView = MSHookIvar<BOOL>(browserController, "_showingTabView");
    }

    if(!showingTabView)
    {
      BOOL privateMode = (statusBarStyle == UIStatusBarStyleLightContent);

      if(!privateMode && [preferenceManager topBarNormalStatusBarStyleEnabled])
      {
        return %orig([preferenceManager topBarNormalStatusBarStyle]);
      }
      else if(privateMode && [preferenceManager topBarPrivateStatusBarStyleEnabled])
      {
        return %orig([preferenceManager topBarPrivateStatusBarStyle]);
      }
    }
  }

  return %orig;
}

%end

void initColors()
{
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

  %init();
}
