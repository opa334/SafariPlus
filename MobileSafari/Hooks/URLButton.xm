// _SFNavigationBarURLButton.xm
// (c) 2017 opa334

#import "../SafariPlus.h"

#import "../Classes/SPPreferenceManager.h"
#import "../Defines.h"
#import "../Shared.h"

#define castedSelf ((NavigationBarURLButton*)self)

%group all

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
      castedSelf.URLBarSwipeLeftGestureRecognizer = [[UISwipeGestureRecognizer alloc]
        initWithTarget:mainBrowserController() action:@selector(navigationBarURLWasSwiped:)];

      //Set swipe direction to left
      castedSelf.URLBarSwipeLeftGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;

      //Add gestureRecognizer
      [castedSelf addGestureRecognizer:castedSelf.URLBarSwipeLeftGestureRecognizer];
    }

    if(preferenceManager.URLRightSwipeGestureEnabled)
    {
      //Create gesture recognizer
      castedSelf.URLBarSwipeRightGestureRecognizer = [[UISwipeGestureRecognizer alloc]
        initWithTarget:mainBrowserController() action:@selector(navigationBarURLWasSwiped:)];

      //Set swipe direction to right
      castedSelf.URLBarSwipeRightGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;

      //Add gestureRecognizer
      [castedSelf addGestureRecognizer:castedSelf.URLBarSwipeRightGestureRecognizer];
    }

    if(preferenceManager.URLDownSwipeGestureEnabled)
    {
      //Create gesture recognizer
      castedSelf.URLBarSwipeDownGestureRecognizer = [[UISwipeGestureRecognizer alloc]
        initWithTarget:mainBrowserController() action:@selector(navigationBarURLWasSwiped:)];

      //Set swipe direction to down
      castedSelf.URLBarSwipeDownGestureRecognizer.direction = UISwipeGestureRecognizerDirectionDown;

      //Add gestureRecognizer
      [castedSelf addGestureRecognizer:castedSelf.URLBarSwipeDownGestureRecognizer];
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
    //Class for iOS 9 and above is _SFNavigationBarURLButton
    buttonClass = objc_getClass("_SFNavigationBarURLButton");
  }
  else
  {
    //Class for iOS 8 is NavigationBarURLButton
    buttonClass = objc_getClass("NavigationBarURLButton");
  }

  //Init group with class name
  %init(all, URLButton=buttonClass);
}
