// TabThumbnailView.xm
// (c) 2017 opa334

#import "../SafariPlus.h"

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
