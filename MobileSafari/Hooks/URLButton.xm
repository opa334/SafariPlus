// _SFNavigationBarURLButton.xm
// (c) 2017 opa334

#import "../SafariPlus.h"

#define selfButton ((NavigationBarURLButton*)self)

%group iOS8_9_10

%hook URLButton

//Create properties for gesture recognizers
%property(nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeLeftGestureRecognizer;
%property(nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeRightGestureRecognizer;
%property(nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeDownGestureRecognizer;

- (id)initWithFrame:(CGRect)frame
{
  if(preferenceManager.URLLeftSwipeGestureEnabled ||
    preferenceManager.URLRightSwipeGestureEnabled ||
    preferenceManager.URLDownSwipeGestureEnabled)
  {
    id orig = %orig;

    if(preferenceManager.URLLeftSwipeGestureEnabled)
    {
      //Create gesture recognizer
      selfButton.URLBarSwipeLeftGestureRecognizer = [[UISwipeGestureRecognizer alloc]
        initWithTarget:mainBrowserController() action:@selector(navigationBarURLWasSwiped:)];

      //Set swipe direction to left
      selfButton.URLBarSwipeLeftGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;

      //Add gestureRecognizer
      [selfButton addGestureRecognizer:selfButton.URLBarSwipeLeftGestureRecognizer];
    }

    if(preferenceManager.URLRightSwipeGestureEnabled)
    {
      //Create gesture recognizer
      selfButton.URLBarSwipeRightGestureRecognizer = [[UISwipeGestureRecognizer alloc]
        initWithTarget:mainBrowserController() action:@selector(navigationBarURLWasSwiped:)];

      //Set swipe direction to right
      selfButton.URLBarSwipeRightGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;

      //Add gestureRecognizer
      [selfButton addGestureRecognizer:selfButton.URLBarSwipeRightGestureRecognizer];
    }

    if(preferenceManager.URLDownSwipeGestureEnabled)
    {
      //Create gesture recognizer
      selfButton.URLBarSwipeDownGestureRecognizer = [[UISwipeGestureRecognizer alloc]
        initWithTarget:mainBrowserController() action:@selector(navigationBarURLWasSwiped:)];

      //Set swipe direction to down
      selfButton.URLBarSwipeDownGestureRecognizer.direction = UISwipeGestureRecognizerDirectionDown;

      //Add gestureRecognizer
      [selfButton addGestureRecognizer:selfButton.URLBarSwipeDownGestureRecognizer];
    }

    return orig;
  }

  return %orig;
}

%end

%end

%ctor
{
  Class buttonClass;

  if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0)
  {
    buttonClass = objc_getClass("_SFNavigationBarURLButton");
  }
  else
  {
    buttonClass = objc_getClass("NavigationBarURLButton");
  }

  %init(iOS8_9_10, URLButton=buttonClass);
}
