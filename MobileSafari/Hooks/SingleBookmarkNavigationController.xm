// SingleBookmarkNavigationController.xm
// (c) 2017 opa334

//#import "../SafariPlus.h"

//Some attempts with custom bookmark pictures that did not work
/*%hook SingleBookmarkNavigationController

- (id)initWithCollection:(id)arg1
{
  id orig = %orig;
  _SFBookmarkInfoViewController* infoViewController = MSHookIvar<_SFBookmarkInfoViewController*>(orig, "_infoViewController");
  if(infoViewController)
  {
    _SFSiteIconView* iconImageView = MSHookIvar<_SFSiteIconView*>(infoViewController, "_iconImageView");
    NSLog(@"iconImageView: %@", iconImageView);
  }
  return orig;
}

+ (id)newBookmarkInfoViewControllerWithBookmark:(id)arg1 inCollection:(id)arg2 addingBookmark:(BOOL)arg3 toFavorites:(BOOL)arg4 willBeDisplayedModally:(BOOL)arg5
{
  id orig = %orig;

  _SFSiteIconView* iconImageView = MSHookIvar<_SFSiteIconView*>(orig, "_iconImageView");
  UIButton* invisibleButton = [UIButton buttonWithType:UIButtonTypeCustom];

  invisibleButton.adjustsImageWhenHighlighted = YES;
  invisibleButton.frame = iconImageView.frame;

  UILongPressGestureRecognizer *siteIconLongPressRecognizer = [[UILongPressGestureRecognizer alloc] init];
  [siteIconLongPressRecognizer addTarget:self action:@selector(siteIconLongPressed:)];
  [siteIconLongPressRecognizer setMinimumPressDuration:0.5];


  [invisibleButton addGestureRecognizer:siteIconLongPressRecognizer];
  [iconImageView addSubview:invisibleButton];
  NSLog(@"iconImageView: %@", iconImageView);

  return orig;
}

- (void)siteIconLongPressed:(UILongPressGestureRecognizer*)sender
{
  NSLog(@"icon long pressed!!!");
}

%end*/
