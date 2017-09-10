// TabController.xm
// (c) 2017 opa334

#import "../SafariPlus.h"

%hook TabController

//Property for desktop button in portrait
%property (nonatomic,retain) UIButton *tiltedTabViewDesktopModeButton;

//Set state of desktop button
- (void)tiltedTabViewDidPresent:(id)arg1
{
  %orig;
  if(preferenceManager.desktopButtonEnabled)
  {
    if(desktopButtonSelected)
    {
      //desktop button should be selected -> Select it
      self.tiltedTabViewDesktopModeButton.selected = YES;
      self.tiltedTabViewDesktopModeButton.backgroundColor = [UIColor whiteColor];
    }
    else
    {
      //desktop button should not be selected -> Unselect it
      self.tiltedTabViewDesktopModeButton.selected = NO;
      self.tiltedTabViewDesktopModeButton.backgroundColor = [UIColor clearColor];
    }
  }
}

//Desktop mode button: Portrait
- (NSArray *)tiltedTabViewToolbarItems
{
  if(preferenceManager.desktopButtonEnabled)
  {
    NSArray* old = %orig;

    if(!self.tiltedTabViewDesktopModeButton)
    {
      //desktopButton not created yet -> create and configure it

      self.tiltedTabViewDesktopModeButton = [UIButton buttonWithType:UIButtonTypeCustom];

      [self.tiltedTabViewDesktopModeButton setImage:[UIImage
        imageNamed:@"desktopButtonInactive.png" inBundle:SPBundle
        compatibleWithTraitCollection:nil] forState:UIControlStateNormal];

      [self.tiltedTabViewDesktopModeButton setImage:[UIImage
        imageNamed:@"desktopButtonActive.png" inBundle:SPBundle
        compatibleWithTraitCollection:nil]  forState:UIControlStateSelected];

      self.tiltedTabViewDesktopModeButton.imageEdgeInsets = UIEdgeInsetsMake(2.5, 2.5, 2.5, 2.5);
      self.tiltedTabViewDesktopModeButton.layer.cornerRadius = 4;
      self.tiltedTabViewDesktopModeButton.adjustsImageWhenHighlighted = true;

      [self.tiltedTabViewDesktopModeButton addTarget:self
        action:@selector(tiltedTabViewDesktopModeButtonPressed)
        forControlEvents:UIControlEventTouchUpInside];

      self.tiltedTabViewDesktopModeButton.frame = CGRectMake(0, 0, 27.5, 27.5);

      if(desktopButtonSelected)
      {
        self.tiltedTabViewDesktopModeButton.selected = YES;
        self.tiltedTabViewDesktopModeButton.backgroundColor = [UIColor whiteColor];
      }
    }

    //Create empty space button to align the bottom toolbar perfectly
    UIButton* emptySpace = [UIButton buttonWithType:UIButtonTypeCustom];
    emptySpace.imageEdgeInsets = UIEdgeInsetsMake(2.5, 2.5, 2.5, 2.5);
    emptySpace.layer.cornerRadius = 4;
    emptySpace.frame = CGRectMake(0, 0, 27.5, 27.5);

    //Create UIBarButtonItem from space
    UIBarButtonItem *customSpace = [[UIBarButtonItem alloc] initWithCustomView:emptySpace];

    //Create flexible UIBarButtonItem
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc]
      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
      target:nil action:nil];

    //Create UIBarButtonItem for desktopButton
    UIBarButtonItem *desktopBarButton = [[UIBarButtonItem alloc]
      initWithCustomView:self.tiltedTabViewDesktopModeButton];

    return @[old[0], flexibleItem, desktopBarButton, flexibleItem, old[2],
      flexibleItem, customSpace, flexibleItem, old[4], old[5]];
  }

  return %orig;
}

%new
- (void)tiltedTabViewDesktopModeButtonPressed
{
  if(desktopButtonSelected)
  {
    //Deselect desktop button
    desktopButtonSelected = NO;
    self.tiltedTabViewDesktopModeButton.selected = NO;

    //Remove white color with animation
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    self.tiltedTabViewDesktopModeButton.backgroundColor = [UIColor clearColor];
    [UIView commitAnimations];
  }
  else
  {
    //Select desktop button
    desktopButtonSelected = YES;
    self.tiltedTabViewDesktopModeButton.selected = YES;

    //Set color to white
    self.tiltedTabViewDesktopModeButton.backgroundColor = [UIColor whiteColor];
  }

  //Reload tabs
  [self reloadTabsIfNeeded];

  //Write button state to plist
  [((Application*)[%c(Application) sharedApplication]) updateButtonState];
}

//Reload tabs if the useragents needs to be changed (depending on the desktop button state)
%new
- (void)reloadTabsIfNeeded
{
  NSArray* currentTabs;
  if([self isPrivateBrowsingEnabled])
  {
    //Private mode enabled -> set currentTabs to tabs of private mode
    currentTabs = self.privateTabDocuments;
  }
  else
  {
    //Private mode disabled -> set currentTabs to tabs of normal mode
    currentTabs = self.tabDocuments;
  }

  for(TabDocument* tabDocument in currentTabs)
  {
    if(![tabDocument isBlankDocument] && ((desktopButtonSelected &&
      ([tabDocument.customUserAgent isEqualToString:@""] ||
      tabDocument.customUserAgent == nil)) || (!desktopButtonSelected &&
      [tabDocument.customUserAgent isEqualToString:desktopUserAgent])))
    {
      //Tab is not blank and it's user agent needs to be changed -> reload it
      [tabDocument reload];
    }
  }
}
/*
//Lock tabs (Prevent them from being closable)
- (BOOL)tiltedTabView:(TiltedTabView*)tiltedTabView canCloseItem:(TiltedTabItem*)item
{
  if(item.layoutInfo.contentView.isLocked)
  {
    return NO;
  }

  return %orig;
}

- (BOOL)tabOverview:(TabOverview*)tabOverview canCloseItem:(TabOverviewItem*)item
{
  if(item.layoutInfo.itemView.isLocked)
  {
    return NO;
  }

  return %orig;
}
*/
%end
