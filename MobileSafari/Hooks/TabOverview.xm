// TabOverview.xm
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
#import "../Shared.h"

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

      UIImage* inactiveImage = [UIImage
        imageNamed:@"DesktopButton.png" inBundle:SPBundle
        compatibleWithTraitCollection:nil];

      UIImage* activeImage = [UIImage inverseColor:inactiveImage];

      [self.desktopModeButton setImage:inactiveImage
        forState:UIControlStateNormal];

      [self.desktopModeButton setImage:activeImage
        forState:UIControlStateSelected];

      self.desktopModeButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
      self.desktopModeButton.layer.cornerRadius = 4;
      self.desktopModeButton.adjustsImageWhenHighlighted = true;

      [self.desktopModeButton addTarget:self
        action:@selector(desktopModeButtonPressed)
        forControlEvents:UIControlEventTouchUpInside];

      if(self.delegate.desktopButtonSelected)
      {
        self.desktopModeButton.selected = YES;
        self.desktopModeButton.backgroundColor = [UIColor whiteColor];
      }
    }

    CGFloat offset = 30;
    if(iPhoneX)
    {
      offset = offset * 1.75;
    }

    self.desktopModeButton.frame = CGRectMake(
      self.privateBrowsingButton.frame.origin.x - (offset + self.privateBrowsingButton.frame.size.height),
      self.privateBrowsingButton.frame.origin.y,
      self.privateBrowsingButton.frame.size.height,
      self.privateBrowsingButton.frame.size.height);

    //Add desktopButton to top bar
    [[self.privateBrowsingButton superview] addSubview:self.desktopModeButton];
  }
}

%new
- (void)desktopModeButtonPressed
{
  if(self.delegate.desktopButtonSelected)
  {
    //Deselect desktop button
    self.delegate.desktopButtonSelected = NO;
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
    self.delegate.desktopButtonSelected = YES;
    self.desktopModeButton.selected = YES;

    //Set color to white
    self.desktopModeButton.backgroundColor = [UIColor whiteColor];
  }

  //Reload tabs
  [self.delegate updateUserAgents];

  //Write button state to plist
  [self.delegate saveDesktopButtonState];
}

%end
