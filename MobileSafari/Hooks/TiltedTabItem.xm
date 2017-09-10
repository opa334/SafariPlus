// TiltedTabItem.xm
// (c) 2017 opa334

#import "../SafariPlus.h"

%hook TiltedTabItem
- (UIColor *)titleColor
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
