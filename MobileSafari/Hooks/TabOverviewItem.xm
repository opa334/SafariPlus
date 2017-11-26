// TabOverviewItem.xm
// (c) 2017 opa334

#import "../SafariPlus.h"

#import "../Classes/SPPreferenceManager.h"
#import "../Shared.h"
#import "libcolorpicker.h"

%hook TabOverviewItem
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
