// NavigationBar.xm
// (c) 2017 opa334


#import "../SafariPlus.h"

%group iOS10
%hook NavigationBar

//Lock icon color
- (id)_tintForLockImage:(BOOL)arg1
{
  if(preferenceManager.lockIconColorNormalEnabled ||
    preferenceManager.lockIconColorPrivateEnabled)
  {
    //Get browsing mode (iOS10)
    BOOL privateMode = [((Application*)[%c(Application)
      sharedApplication]).shortcutController.browserController
      privateBrowsingEnabled];

    if(preferenceManager.lockIconColorNormalEnabled && !privateMode)
    {
      //Replace color with the specified one
      #ifdef SIMJECT
      return [UIColor redColor];
      #else
      return LCPParseColorString(preferenceManager.lockIconColorNormal, @"#FFFFFF");
      #endif
    }
    else if(preferenceManager.lockIconColorPrivateEnabled && privateMode)
    {
      //Replace color with the specified one
      #ifdef SIMJECT
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
    //Get browsing mode (iOS9)
    BOOL privateMode = [((Application*)[%c(Application)
      sharedApplication]).shortcutController.browserController
      privateBrowsingEnabled];

    if(preferenceManager.lockIconColorNormalEnabled && !privateMode)
    {
      //Replace color with the specified one
      #ifdef SIMJECT
      arg1 = [UIColor redColor];
      #else
      arg1 = LCPParseColorString(preferenceManager.lockIconColorNormal, @"#FFFFFF");
      #endif
    }
    else if(preferenceManager.lockIconColorPrivateEnabled && privateMode)
    {
      //Replace color with the specified one
      #ifdef SIMJECT
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
    BOOL privateMode = privateBrowsingEnabled();

    if(preferenceManager.appTintColorNormalEnabled && !privateMode)
    {
      #ifdef SIMJECT
      self.tintColor = [UIColor redColor];
      #else
      self.tintColor = LCPParseColorString(preferenceManager.appTintColorNormal, @"#FFFFFF");
      #endif
    }
    else if(preferenceManager.appTintColorPrivateEnabled && privateMode)
    {
      #ifdef SIMJECT
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
    BOOL privateMode = privateBrowsingEnabled();

    _SFNavigationBarBackdrop* backdrop =
      MSHookIvar<_SFNavigationBarBackdrop*>(self, "_backdrop");

    if(preferenceManager.topBarColorNormalEnabled && !privateMode) //Normal Mode
    {
      #ifdef SIMJECT
      backdrop.grayscaleTintView.backgroundColor = [UIColor redColor];
      #else
      backdrop.grayscaleTintView.backgroundColor =
        LCPParseColorString(preferenceManager.topBarColorNormal, @"#FFFFFF");
      #endif
    }

    else if(preferenceManager.topBarColorPrivateEnabled && privateMode) //Private Mode
    {
      #ifdef SIMJECT
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
    BOOL privateMode = privateBrowsingEnabled();

    _SFFluidProgressView* progressView = MSHookIvar<_SFFluidProgressView*>(self, "_progressView");
    if(preferenceManager.progressBarColorNormalEnabled && !privateMode)
    {
      #ifdef SIMJECT
      progressView.progressBarFillColor = [UIColor redColor];
      #else
      progressView.progressBarFillColor =
        LCPParseColorString(preferenceManager.progressBarColorNormal, @"#FFFFFF");
      #endif
    }
    else if(preferenceManager.progressBarColorPrivateEnabled && privateMode)
    {
      #ifdef SIMJECT
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
    BOOL privateMode = privateBrowsingEnabled();

    if(preferenceManager.URLFontColorNormalEnabled && !privateMode)
    {
      #ifdef SIMJECT
      return [UIColor redColor];
      #else
      return LCPParseColorString(preferenceManager.URLFontColorNormal, @"#FFFFFF");
      #endif
    }
    else if(preferenceManager.URLFontColorPrivateEnabled && privateMode)
    {
      #ifdef SIMJECT
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
    BOOL privateMode = privateBrowsingEnabled();

    UIColor* customColor;
    if(preferenceManager.URLFontColorNormalEnabled && !privateMode)
    {
      #ifdef SIMJECT
      customColor = [UIColor redColor];
      #else
      customColor = LCPParseColorString(preferenceManager.URLFontColorNormal, @"#FFFFFF");
      #endif
      return [customColor colorWithAlphaComponent:0.5];
    }
    else if(preferenceManager.URLFontColorPrivateEnabled && privateMode)
    {
      #ifdef SIMJECT
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
    BOOL privateMode = privateBrowsingEnabled();

    if(preferenceManager.reloadColorNormalEnabled && !privateMode)
    {
      #ifdef SIMJECT
      return [UIColor redColor];
      #else
      return LCPParseColorString(preferenceManager.reloadColorNormal, @"#FFFFFF");
      #endif
    }
    else if(preferenceManager.reloadColorPrivateEnabled && privateMode)
    {
      #ifdef SIMJECT
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
