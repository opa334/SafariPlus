// TabController.xm
// (c) 2018 opa334

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
#import "../Classes/SPCacheManager.h"
#import "../Defines.h"
#import "../Shared.h"
#import "libcolorpicker.h"

%hook TabController

//BOOL for desktop button selection
%property (nonatomic,retain) BOOL desktopButtonSelected;

//Property for desktop button in portrait
%property (nonatomic,retain) UIButton *tiltedTabViewDesktopModeButton;

- (TabController*)initWithBrowserController:(BrowserController*)browserController
{
  id orig = %orig;

  if(preferenceManager.desktopButtonEnabled)
  {
    [self loadDesktopButtonState];
  }

  return orig;
}

%new
- (void)loadDesktopButtonState
{
  BrowserController* browserController = MSHookIvar<BrowserController*>(self, "_browserController");

  //Load state of desktop button
  if([browserController respondsToSelector:@selector(UUID)])
  {
    self.desktopButtonSelected = [cacheManager desktopButtonStateForUUID:browserController.UUID];
  }
  else
  {
    self.desktopButtonSelected = [cacheManager desktopButtonStateForUUID:nil];
  }
}

%new
- (void)saveDesktopButtonState
{
  if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0)
  {
    //Save state for browserController UUID
    BrowserController* browserController = MSHookIvar<BrowserController*>(self, "_browserController");
    [cacheManager setDesktopButtonState:self.desktopButtonSelected forUUID:browserController.UUID];
  }
  else
  {
    //Save global state (iOS 9 and below can't have multiple browserControllers)
    [cacheManager setDesktopButtonState:self.desktopButtonSelected forUUID:nil];
  }
}

//Set state of desktop button
- (void)tiltedTabViewDidPresent:(id)arg1
{
  %orig;
  if(preferenceManager.desktopButtonEnabled)
  {
    if(self.desktopButtonSelected)
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

      UIImage* inactiveImage = [UIImage
        imageNamed:@"DesktopButton.png" inBundle:SPBundle
        compatibleWithTraitCollection:nil];

      UIImage* activeImage = [UIImage inverseColor:inactiveImage];

      [self.tiltedTabViewDesktopModeButton setImage:inactiveImage
        forState:UIControlStateNormal];

      [self.tiltedTabViewDesktopModeButton setImage:activeImage
        forState:UIControlStateSelected];

      self.tiltedTabViewDesktopModeButton.imageEdgeInsets = UIEdgeInsetsMake(2.5, 2.5, 2.5, 2.5);
      self.tiltedTabViewDesktopModeButton.layer.cornerRadius = 4;
      self.tiltedTabViewDesktopModeButton.adjustsImageWhenHighlighted = true;

      [self.tiltedTabViewDesktopModeButton addTarget:self
        action:@selector(tiltedTabViewDesktopModeButtonPressed)
        forControlEvents:UIControlEventTouchUpInside];

      self.tiltedTabViewDesktopModeButton.frame = CGRectMake(0, 0, 27.5, 27.5);

      if(self.desktopButtonSelected)
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
  if(self.desktopButtonSelected)
  {
    //Deselect desktop button
    self.desktopButtonSelected = NO;
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
    self.desktopButtonSelected = YES;
    self.tiltedTabViewDesktopModeButton.selected = YES;

    //Set color to white
    self.tiltedTabViewDesktopModeButton.backgroundColor = [UIColor whiteColor];
  }

  //Update user agents
  [self updateUserAgents];

  //Write button state to plist
  [self saveDesktopButtonState];
}

//Update user agent of all tabs
%new
- (void)updateUserAgents
{
  for(TabDocument* tabDocument in self.allTabDocuments)
  {
    if(tabDocument.desktopMode != self.desktopButtonSelected)
    {
      [tabDocument updateDesktopMode];

      if(!tabDocument.isHibernated)
      {
        if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_3)
        {
          [tabDocument _loadURLInternal:[tabDocument URL] userDriven:NO];
        }
        else
        {
          [tabDocument reload];
        }
      }
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
