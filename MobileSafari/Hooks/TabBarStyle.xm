// TabBarStyle.xm
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
#import "../Shared.h"
#import "libcolorpicker.h"

//Tab Bar Title Color
%hook TabBarStyle

+ (TabBarStyle*)normalStyle
{
  TabBarStyle* normalStyle = %orig;

  if(preferenceManager.tabTitleColorNormalEnabled)
  {
    #if defined(SIMJECT)
    MSHookIvar<UIColor*>(normalStyle, "_itemTitleColor") = [UIColor redColor];
    #else
    MSHookIvar<UIColor*>(normalStyle, "_itemTitleColor") = LCPParseColorString(preferenceManager.tabTitleColorNormal, @"#FFFFFF");
    #endif
  }

  return normalStyle;
}

+ (TabBarStyle*)privateBrowsingStyle
{
  TabBarStyle* privateBrowsingStyle = %orig;

  if(preferenceManager.tabTitleColorPrivateEnabled)
  {
    #if defined(SIMJECT)
    MSHookIvar<UIColor*>(privateBrowsingStyle, "_itemTitleColor") = [UIColor redColor];
    #else
    MSHookIvar<UIColor*>(privateBrowsingStyle, "_itemTitleColor") = LCPParseColorString(preferenceManager.tabTitleColorPrivate, @"#FFFFFF");
    #endif
  }

  return privateBrowsingStyle;
}

%end
