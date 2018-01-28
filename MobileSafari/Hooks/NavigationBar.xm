// NavigationBar.xm
// (c) 2017 opa334

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

#import "../Classes/SPPreferenceManager.h"
#import "../Defines.h"
#import "../Shared.h"
#import "libcolorpicker.h"

%group iOS10
%hook NavigationBar

//Lock icon color
- (id)_tintForLockImage:(BOOL)arg1
{
  if(preferenceManager.lockIconColorNormalEnabled ||
    preferenceManager.lockIconColorPrivateEnabled)
  {
    BOOL privateMode = privateBrowsingEnabled(self.delegate);

    if(preferenceManager.lockIconColorNormalEnabled && !privateMode)
    {
      //Replace color with the specified one
      #if defined(SIMJECT) || defined(ELECTRA)
      return [UIColor redColor];
      #else
      return LCPParseColorString(preferenceManager.lockIconColorNormal, @"#FFFFFF");
      #endif
    }
    else if(preferenceManager.lockIconColorPrivateEnabled && privateMode)
    {
      //Replace color with the specified one
      #if defined(SIMJECT) || defined(ELECTRA)
      return [UIColor redColor];
      #else
      return LCPParseColorString(preferenceManager.lockIconColorPrivate, @"#FFFFFF");
      #endif
    }
  }

  return %orig;
}

%end
%end

%group iOS9
%hook NavigationBar

//Lock icon color
- (id)_lockImageWithTint:(id)arg1 usingMiniatureVersion:(BOOL)arg2
{
  if(preferenceManager.lockIconColorNormalEnabled ||
    preferenceManager.lockIconColorPrivateEnabled)
  {
    BOOL privateMode = privateBrowsingEnabled(self.delegate);

    if(preferenceManager.lockIconColorNormalEnabled && !privateMode)
    {
      //Replace color with the specified one
      #if defined(SIMJECT) || defined(ELECTRA)
      arg1 = [UIColor redColor];
      #else
      arg1 = LCPParseColorString(preferenceManager.lockIconColorNormal, @"#FFFFFF");
      #endif
    }
    else if(preferenceManager.lockIconColorPrivateEnabled && privateMode)
    {
      //Replace color with the specified one
      #if defined(SIMJECT) || defined(ELECTRA)
      arg1 = [UIColor redColor];
      #else
      arg1 = LCPParseColorString(preferenceManager.lockIconColorPrivate, @"#FFFFFF");
      #endif
    }
    return %orig(arg1, arg2);
  }

  return %orig;
}

%end
%end

%hook NavigationBar

- (void)_updateBackdropStyle
{
  %orig;
  if(preferenceManager.appTintColorNormalEnabled ||
    preferenceManager.appTintColorPrivateEnabled)
  {
    BOOL privateMode = privateBrowsingEnabled(self.delegate);

    if(preferenceManager.appTintColorNormalEnabled && !privateMode)
    {
      #if defined(SIMJECT) || defined(ELECTRA)
      self.tintColor = [UIColor redColor];
      #else
      self.tintColor = LCPParseColorString(preferenceManager.appTintColorNormal, @"#FFFFFF");
      #endif
    }
    else if(preferenceManager.appTintColorPrivateEnabled && privateMode)
    {
      #if defined(SIMJECT) || defined(ELECTRA)
      self.tintColor = [UIColor redColor];
      #else
      self.tintColor = LCPParseColorString(preferenceManager.appTintColorPrivate, @"#FFFFFF");
      #endif
    }
    else
    {
      [self _updateControlTints]; //Apply default color
    }
  }

  if(preferenceManager.topBarColorNormalEnabled ||
    preferenceManager.topBarColorPrivateEnabled)
  {
    BOOL privateMode = privateBrowsingEnabled(self.delegate);

    _SFNavigationBarBackdrop* backdrop =
      MSHookIvar<_SFNavigationBarBackdrop*>(self, "_backdrop");

    if(preferenceManager.topBarColorNormalEnabled && !privateMode) //Normal Mode
    {
      #if defined(SIMJECT) || defined(ELECTRA)
      backdrop.grayscaleTintView.backgroundColor = [UIColor redColor];
      #else
      backdrop.grayscaleTintView.backgroundColor =
        LCPParseColorString(preferenceManager.topBarColorNormal, @"#FFFFFF");
      #endif
    }

    else if(preferenceManager.topBarColorPrivateEnabled && privateMode) //Private Mode
    {
      #if defined(SIMJECT) || defined(ELECTRA)
      backdrop.grayscaleTintView.backgroundColor = [UIColor redColor];
      #else
      backdrop.grayscaleTintView.backgroundColor =
        LCPParseColorString(preferenceManager.topBarColorPrivate, @"#FFFFFF");
      #endif
    }
  }
}

//Progress bar color
- (void)_updateProgressView
{
  %orig;
  if(preferenceManager.progressBarColorNormalEnabled ||
    preferenceManager.progressBarColorPrivateEnabled)
  {
    BOOL privateMode = privateBrowsingEnabled(self.delegate);

    _SFFluidProgressView* progressView = MSHookIvar<_SFFluidProgressView*>(self, "_progressView");
    if(preferenceManager.progressBarColorNormalEnabled && !privateMode)
    {
      #if defined(SIMJECT) || defined(ELECTRA)
      progressView.progressBarFillColor = [UIColor redColor];
      #else
      progressView.progressBarFillColor =
        LCPParseColorString(preferenceManager.progressBarColorNormal, @"#FFFFFF");
      #endif
    }
    else if(preferenceManager.progressBarColorPrivateEnabled && privateMode)
    {
      #if defined(SIMJECT) || defined(ELECTRA)
      progressView.progressBarFillColor = [UIColor redColor];
      #else
      progressView.progressBarFillColor =
        LCPParseColorString(preferenceManager.progressBarColorPrivate, @"#FFFFFF");
      #endif
    }
  }
}

//Text color
- (id)_URLTextColor
{
  if(preferenceManager.URLFontColorNormalEnabled ||
    preferenceManager.URLFontColorPrivateEnabled)
  {
    BOOL privateMode = privateBrowsingEnabled(self.delegate);

    if(preferenceManager.URLFontColorNormalEnabled && !privateMode)
    {
      #if defined(SIMJECT) || defined(ELECTRA)
      return [UIColor redColor];
      #else
      return LCPParseColorString(preferenceManager.URLFontColorNormal, @"#FFFFFF");
      #endif
    }
    else if(preferenceManager.URLFontColorPrivateEnabled && privateMode)
    {
      #if defined(SIMJECT) || defined(ELECTRA)
      return [UIColor redColor];
      #else
      return LCPParseColorString(preferenceManager.URLFontColorPrivate, @"#FFFFFF");
      #endif
    }
  }

  return %orig;
}

//Text color of search text, needs to be less visible
- (id)_placeholderColor
{
  if(preferenceManager.URLFontColorNormalEnabled ||
    preferenceManager.URLFontColorPrivateEnabled)
  {
    BOOL privateMode = privateBrowsingEnabled(self.delegate);

    UIColor* customColor;
    if(preferenceManager.URLFontColorNormalEnabled && !privateMode)
    {
      #if defined(SIMJECT) || defined(ELECTRA)
      customColor = [UIColor redColor];
      #else
      customColor = LCPParseColorString(preferenceManager.URLFontColorNormal, @"#FFFFFF");
      #endif
      return [customColor colorWithAlphaComponent:0.5];
    }
    else if(preferenceManager.URLFontColorPrivateEnabled && privateMode)
    {
      #if defined(SIMJECT) || defined(ELECTRA)
      customColor = [UIColor redColor];
      #else
      customColor = LCPParseColorString(preferenceManager.URLFontColorNormal, @"#FFFFFF");
      #endif
      return [customColor colorWithAlphaComponent:0.5];
    }
  }

  return %orig;
}

//Reload button color
- (id)_URLControlsColor
{
  if(preferenceManager.reloadColorNormalEnabled ||
    preferenceManager.reloadColorPrivateEnabled)
  {
    BOOL privateMode = privateBrowsingEnabled(self.delegate);

    if(preferenceManager.reloadColorNormalEnabled && !privateMode)
    {
      #if defined(SIMJECT) || defined(ELECTRA)
      return [UIColor redColor];
      #else
      return LCPParseColorString(preferenceManager.reloadColorNormal, @"#FFFFFF");
      #endif
    }
    else if(preferenceManager.reloadColorPrivateEnabled && privateMode)
    {
      #if defined(SIMJECT) || defined(ELECTRA)
      return [UIColor redColor];
      #else
      return LCPParseColorString(preferenceManager.reloadColorPrivate, @"#FFFFFF");
      #endif
    }
  }

  return %orig;
}
%end

%ctor
{
  if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0)
  {
    %init(iOS10);
  }
  else// if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0)
  {
    %init(iOS9);
  }
  %init;
}
