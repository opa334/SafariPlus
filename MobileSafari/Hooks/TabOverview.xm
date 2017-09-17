// TabOverview.xm
// (c) 2017 opa334

#import "../SafariPlus.h"

%hook TabOverview

//Property for landscape desktop button
%property (nonatomic,retain) UIButton *desktopModeButton;

//Desktop mode button: Landscape
- (void)layoutSubviews
{
  %orig;
  if(preferenceManager.desktopButtonEnabled)
  {
    if(!self.desktopModeButton)
    {
      //desktopButton not created yet -> create and configure it
      self.desktopModeButton = [UIButton buttonWithType:UIButtonTypeCustom];

      [self.desktopModeButton setImage:[UIImage imageNamed:@"desktopButtonInactive.png"
        inBundle:SPBundle compatibleWithTraitCollection:nil]
        forState:UIControlStateNormal];

      [self.desktopModeButton setImage:[UIImage imageNamed:@"desktopButtonActive.png"
        inBundle:SPBundle compatibleWithTraitCollection:nil]
        forState:UIControlStateSelected];

      self.desktopModeButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
      self.desktopModeButton.layer.cornerRadius = 4;
      self.desktopModeButton.adjustsImageWhenHighlighted = true;

      [self.desktopModeButton addTarget:self
        action:@selector(desktopModeButtonPressed)
        forControlEvents:UIControlEventTouchUpInside];

      self.desktopModeButton.frame = CGRectMake(
        self.privateBrowsingButton.frame.origin.x - 57.5,
        self.privateBrowsingButton.frame.origin.y,
        self.privateBrowsingButton.frame.size.height,
        self.privateBrowsingButton.frame.size.height);

      if(desktopButtonSelected)
      {
        self.desktopModeButton.selected = YES;
        self.desktopModeButton.backgroundColor = [UIColor whiteColor];
      }
    }

    //Add desktopButton to top bar
    switch(iOSVersion)
    {
      case 9:
      [MSHookIvar<UIView*>(self, "_header") addSubview:self.desktopModeButton];
      break;
      case 10:
      [MSHookIvar<_UIBackdropView*>(self, "_header").contentView
        addSubview:self.desktopModeButton];
      break;
    }
  }
}

%new
- (void)desktopModeButtonPressed
{
  if(desktopButtonSelected)
  {
    //Deselect desktop button
    desktopButtonSelected = NO;
    self.desktopModeButton.selected = NO;

    //Remove white color with animation
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    self.desktopModeButton.backgroundColor = [UIColor clearColor];
    [UIView commitAnimations];
  }
  else
  {
    //Select desktop button
    desktopButtonSelected = YES;
    self.desktopModeButton.selected = YES;

    //Set color to white
    self.desktopModeButton.backgroundColor = [UIColor whiteColor];
  }

  //Reload tabs
  switch(iOSVersion)
  {
    case 9:
    [MSHookIvar<BrowserController*>(((Application*)[%c(Application)
      sharedApplication]), "_controller").tabController reloadTabsIfNeeded];
    break;

    case 10:
    [((Application*)[%c(Application)
      sharedApplication]).shortcutController.browserController.tabController
      reloadTabsIfNeeded];
    break;
  }

  //Write button state to plist
  loadOtherPlist();
  [otherPlist setObject:[NSNumber numberWithBool:desktopButtonSelected]
    forKey:@"desktopButtonSelected"];
  saveOtherPlist();
}

%end
