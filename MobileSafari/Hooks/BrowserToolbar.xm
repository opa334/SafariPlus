// BrowserToolbar.xm
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

BOOL fullSafariInstalled;

%hook BrowserToolbar

//Property for downloads button
%property (nonatomic,retain) UIBarButtonItem *_downloadsItem;

//Correctly enable / disable downloads button when needed
- (void)setEnabled:(BOOL)arg1
{
  %orig;
  if(preferenceManager.enhancedDownloadsEnabled)
  {
    [self setDownloadsEnabled:arg1];
  }
}

%new
- (void)setDownloadsEnabled:(BOOL)enabled
{
  [self._downloadsItem setEnabled:enabled];
}

//Add downloads button to toolbar
- (NSMutableArray *)defaultItems
{
  if(preferenceManager.enhancedDownloadsEnabled)
  {
    NSMutableArray* orig = %orig;

    if(![orig containsObject:self._downloadsItem])
    {
      if(!self._downloadsItem)
      {
        self._downloadsItem = [[UIBarButtonItem alloc] initWithImage:[UIImage
          imageNamed:@"downloadsButton.png" inBundle:SPBundle
          compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain
          target:self.browserDelegate action:@selector(downloadsFromButtonBar)];
      }

      long long placement = MSHookIvar<long long>(self, "_placement");

      //Landscape on newer devices, portrait + landscape on iPads
      if(placement == 0 || placement == 4294967296 || (IS_PAD && iOSVersion <= 8))
      {
        //iPads
        if(IS_PAD)
        {
          ((UIBarButtonItem*)orig[10]).width = ((UIBarButtonItem*)orig[10]).width / 3;
          ((UIBarButtonItem*)orig[12]).width = ((UIBarButtonItem*)orig[12]).width / 3;
        }
        else
        {
          //Plus iPhones
          if([orig count] > 14)
          {
            ((UIBarButtonItem*)orig[10]).width = ((UIBarButtonItem*)orig[10]).width / 10;
            ((UIBarButtonItem*)orig[12]).width = ((UIBarButtonItem*)orig[12]).width / 10;
            ((UIBarButtonItem*)orig.lastObject).width = 0;
          }
          //Non plus iPhones
          else
          {
            ((UIBarButtonItem*)orig[10]).width = 0;
            ((UIBarButtonItem*)orig[12]).width = 0;
          }
        }

        [orig insertObject:orig[10] atIndex:8];
        [orig insertObject:self._downloadsItem atIndex:8];
      }
      //Portrait mode on all iPhones, landscape on smaller iPhones + split view on smaller iPads
      else
      {
        UIBarButtonItem* flexibleItem = [[UIBarButtonItem alloc]
          initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
          target:nil action:nil];

        //Full Safari installed
        if(fullSafariInstalled)
        {
          orig = [@[orig[1], flexibleItem, flexibleItem,
            orig[4], flexibleItem, orig[7], flexibleItem, orig[10], flexibleItem, self._downloadsItem,
            flexibleItem, orig[13]] mutableCopy];

          //Add FullSafari button to final array
          //Code from https://github.com/Bensge/FullSafari/blob/master/Tweak.xm
          GestureRecognizingBarButtonItem *addTabItem =
            MSHookIvar<GestureRecognizingBarButtonItem *>(self, "_addTabItem");

          if(!addTabItem || ![orig containsObject:addTabItem])
          {
            if(!addTabItem)
            {
              // Recreate the "add tab" button for iOS versions that don't do that by default on iPhone models
              addTabItem = [[NSClassFromString(@"GestureRecognizingBarButtonItem") alloc] initWithImage:[UIImage imageNamed:@"AddTab"] style:0 target:[self valueForKey:@"_browserDelegate"] action:@selector(addTabFromButtonBar)];
              UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_addTabLongPressRecognized:)];
              recognizer.allowableMovement = 3.0;
              addTabItem.gestureRecognizer = recognizer;
            }
            [orig addObject:flexibleItem];
            [orig addObject:addTabItem];
          }
        }
        //Full Safari not installed
        else
        {
          UIBarButtonItem *fixedItem = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
            target:nil action:nil];

          UIBarButtonItem *fixedItemHalf = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
            target:nil action:nil];

          //Make everything flexible, thanks apple!
          fixedItem.width = 15;
          fixedItemHalf.width = 7.5f;

          UIBarButtonItem *fixedItemTwo = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
            target:nil action:nil];

          fixedItemTwo.width = 6;

          orig = [@[orig[1], fixedItem, flexibleItem,
            fixedItemHalf, orig[4], fixedItemHalf, flexibleItem, fixedItemTwo,
            orig[7], flexibleItem, orig[10], flexibleItem, self._downloadsItem,
            flexibleItem, orig[13]] mutableCopy];
        }
      }

      NSMutableDictionary* defaultItemsForToolbarSize =
        MSHookIvar<NSMutableDictionary*>(self, "_defaultItemsForToolbarSize");

      //Save items to dictionary
      defaultItemsForToolbarSize[@([self toolbarSize])] = orig;

      return orig;
    }
  }

  return %orig;
}

- (void)layoutSubviews
{
  //Tint Color
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
  }

  //Bottom Bar Color (kinda broken? For some reason it only works properly when SafariDownloader + is installed?)
  if(preferenceManager.bottomBarColorNormalEnabled ||
    preferenceManager.bottomBarColorPrivateEnabled)
  {
    BOOL privateMode = privateBrowsingEnabled(self.delegate);

    _UIBackdropView* backgroundView = MSHookIvar<_UIBackdropView*>(self, "_backgroundView");
    backgroundView.grayscaleTintView.hidden = NO;
    if(preferenceManager.bottomBarColorNormalEnabled && !privateMode)
    {
      #if defined(SIMJECT) || defined(ELECTRA)
      backgroundView.grayscaleTintView.backgroundColor = [UIColor redColor];
      #else
      backgroundView.grayscaleTintView.backgroundColor =
        LCPParseColorString(preferenceManager.bottomBarColorNormal, @"#FFFFFF");
      #endif
    }
    else if(preferenceManager.bottomBarColorPrivateEnabled && privateMode)
    {
      #if defined(SIMJECT) || defined(ELECTRA)
      backgroundView.grayscaleTintView.backgroundColor = [UIColor redColor];
      #else
      backgroundView.grayscaleTintView.backgroundColor =
        LCPParseColorString(preferenceManager.bottomBarColorPrivate, @"#FFFFFF");
      #endif
    }
    else
    {
      [self updateTintColor];
    }
  }

  %orig;
}

%end

%ctor
{
  //Check if FullSafari is installed
  fullSafariInstalled = [[NSFileManager defaultManager]
    fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/FullSafari.dylib"];
}
