// BrowserToolbar.xm
// (c) 2017 opa334

#import "../SafariPlus.h"

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

      //Portrait + Landscape on iPad
      if(IS_PAD)
      {
        ((UIBarButtonItem*)orig[10]).width = ((UIBarButtonItem*)orig[10]).width / 3;
        ((UIBarButtonItem*)orig[12]).width = ((UIBarButtonItem*)orig[12]).width / 3;
        [orig insertObject:orig[10] atIndex:8];
        [orig insertObject:self._downloadsItem atIndex:8];
      }
      else
      {
        //Portrait mode on larger devices, portrait + landscape on smaller devices
        if(MSHookIvar<long long>(self, "_placement"))
        {
          UIBarButtonItem* flexibleItem = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
            target:nil action:nil];

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
        //Landscape on plus models
        else
        {
          ((UIBarButtonItem*)orig[10]).width = ((UIBarButtonItem*)orig[10]).width / 10;
          ((UIBarButtonItem*)orig[12]).width = ((UIBarButtonItem*)orig[12]).width / 10;

          if(iOSVersion >= 11)
          {
            ((UIBarButtonItem*)orig[14]).width = 0;
            [orig insertObject:orig[10] atIndex:8];
            [orig insertObject:self._downloadsItem atIndex:8];
          }
          else
          {
            ((UIBarButtonItem*)orig[15]).width = 0;
            [orig insertObject:orig[10] atIndex:9];
            [orig insertObject:self._downloadsItem atIndex:9];
          }
        }
      }

      NSMutableDictionary* defaultItemsForToolbarSize =
        MSHookIvar<NSMutableDictionary*>(self, "_defaultItemsForToolbarSize");

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
  }

  //Bottom Bar Color (kinda broken? For some reason it only works properly when SafariDownloader + is installed?)
  if(preferenceManager.bottomBarColorNormalEnabled ||
    preferenceManager.bottomBarColorPrivateEnabled)
  {
    BOOL privateMode = privateBrowsingEnabled();

    _UIBackdropView* backgroundView = MSHookIvar<_UIBackdropView*>(self, "_backgroundView");
    backgroundView.grayscaleTintView.hidden = NO;
    if(preferenceManager.bottomBarColorNormalEnabled && !privateMode)
    {
      #ifdef SIMJECT
      backgroundView.grayscaleTintView.backgroundColor = [UIColor redColor];
      #else
      backgroundView.grayscaleTintView.backgroundColor =
        LCPParseColorString(preferenceManager.bottomBarColorNormal, @"#FFFFFF");
      #endif
    }
    else if(preferenceManager.bottomBarColorPrivateEnabled && privateMode)
    {
      #ifdef SIMJECT
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
