// TabBarStyle.xm
// (c) 2017 opa334

#import "../SafariPlus.h"

//Tab Title Color
%hook TabBarStyle
- (UIColor *)itemTitleColor
{
  if(preferenceManager.tabTitleColorNormalEnabled ||
    preferenceManager.tabTitleColorPrivateEnabled)
  {
    BOOL privateMode = privateBrowsingEnabled();

    UIColor* customColor = %orig;
    if(preferenceManager.tabTitleColorNormalEnabled && !privateMode)
    {
      #ifdef SIMJECT
      customColor = [UIColor redColor];
      #else
      customColor = LCPParseColorString(preferenceManager.tabTitleColorNormal, @"#FFFFFF");
      #endif
    }
    else if(preferenceManager.tabTitleColorPrivateEnabled && privateMode)
    {
      #ifdef SIMJECT
      customColor = [UIColor redColor];
      #else
      customColor = LCPParseColorString(preferenceManager.tabTitleColorPrivate, @"#FFFFFF");
      #endif
    }
    return customColor;
  }

  return %orig;
}
%end
