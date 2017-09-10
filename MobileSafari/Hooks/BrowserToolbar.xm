// BrowserToolbar.xm
// (c) 2017 opa334

#import "../SafariPlus.h"

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
        //Portrait mode on plus models, portrait + landscape on non-plus models
        if(![self.browserDelegate usesTabBar] || [orig count] < 15) //count thing fixes crash
        {
          UIBarButtonItem* flexibleItem = [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
            target:nil action:nil];

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

          orig = (NSMutableArray*)@[orig[1], fixedItem, flexibleItem,
            fixedItemHalf, orig[4], fixedItemHalf, flexibleItem, fixedItemTwo,
            orig[7], flexibleItem, orig[10], flexibleItem, self._downloadsItem,
            flexibleItem, orig[13]];
        }
        //Landscape on plus models
        else
        {
          ((UIBarButtonItem*)orig[10]).width = ((UIBarButtonItem*)orig[10]).width / 10;
          ((UIBarButtonItem*)orig[12]).width = ((UIBarButtonItem*)orig[12]).width / 10;
          ((UIBarButtonItem*)orig[15]).width = 0;
          [orig insertObject:orig[10] atIndex:9];
          [orig insertObject:self._downloadsItem atIndex:9];
        }
      }

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
