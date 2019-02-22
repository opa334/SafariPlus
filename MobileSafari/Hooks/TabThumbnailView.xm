// TabThumbnailView.xm
// (c) 2019 opa334

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

//#import "../SafariPlus.h"

/*%hook TabThumbnailView

   %property(nonatomic, retain) UIButton *lockButton;
   %property(nonatomic, assign) BOOL isLocked;

   - (void)layoutSubviews
   {
   %orig;
   UIView* headerView = MSHookIvar<UIView*>(self, "_headerView");
   if(!self.lockButton)
   {
    self.lockButton = [%c(_SFDimmingButton) buttonWithType:UIButtonTypeCustom];
    self.lockButton.backgroundColor = [UIColor redColor];
    [self.lockButton addTarget:self
      action:@selector(lockButtonPressed)
      forControlEvents:UIControlEventTouchUpInside];
    self.lockButton.selected = self.isLocked;
    [headerView addSubview:self.lockButton];
   }
   CGFloat size = self.closeButton.frame.size.width;
   self.lockButton.frame = CGRectMake(headerView.frame.size.width - size, 0, size, size);
   }

   %new
   - (void)lockButtonPressed
   {
   self.lockButton.selected = !self.lockButton.selected;
   self.isLocked = self.lockButton.selected;
   [self layoutSubviews];
   }

   %end*/
