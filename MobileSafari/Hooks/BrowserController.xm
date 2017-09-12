// BrowserController.xm
// (c) 2017 opa334

#import "../SafariPlus.h"

%group iOS10
%hook BrowserController

//Present downloads view
%new
- (void)downloadsFromButtonBar
{
  //Create SPDownloadsNavigationController
  SPDownloadsNavigationController* downloadsController =
    [[SPDownloadsNavigationController alloc] init];

  dispatch_async(dispatch_get_main_queue(), ^
  {
    //Present SPDownloadsNavigationController
    [self.rootViewController presentViewController:downloadsController animated:YES completion:nil];
  });
}

//URL Swipe actions
%new
- (void)handleSwipe:(NSInteger)swipeAction
{
  //Some cases need cleaning -> Create bool for that
  __block BOOL shouldClean = NO;

  switch(swipeAction)
  {
    case 1: //Close active tab
    [self.tabController.activeTabDocument _closeTabDocumentAnimated:NO];
    shouldClean = YES;
    break;

    case 2: //Open new tab
    [self.tabController newTab];
    break;

    case 3: //Duplicate active tab
    [self loadURLInNewTab:[self.tabController.activeTabDocument URL]
      inBackground:preferenceManager.gestureBackground animated:YES];
    break;

    case 4: //Close all tabs from active mode
    [self.tabController closeAllOpenTabsAnimated:NO exitTabView:YES];
    shouldClean = YES;
    break;

    case 5: //Switch mode (Normal/Private)
    [self togglePrivateBrowsing];
    shouldClean = YES;
    break;

    case 6: //Tab backward
    {
      //Get index of previous tab
      NSInteger tabIndex = [self.tabController.currentTabDocuments
        indexOfObject:self.tabController.activeTabDocument] - 1;

      if(tabIndex >= 0)
      {
        //tabIndex is not smaller than 0 -> switch to previous tab
        [self.tabController
          setActiveTabDocument:self.tabController.currentTabDocuments[tabIndex] animated:NO];
      }
      break;
    }

    case 7: //Tab forward
    {
      //Get index of next tab
      NSInteger tabIndex = [self.tabController.currentTabDocuments
        indexOfObject:self.tabController.activeTabDocument] + 1;

      if(tabIndex < [self.tabController.currentTabDocuments count])
      {
        //tabIndex is not bigger than array -> switch to next tab
        [self.tabController
          setActiveTabDocument:self.tabController.currentTabDocuments[tabIndex] animated:NO];
      }
      break;
    }

    case 8: //Reload active tab
    [self.tabController.activeTabDocument reload];
    break;

    case 9: //Request desktop site
    [self.tabController.activeTabDocument.reloadOptionsController requestDesktopSite];
    break;

    case 10: //Open 'find on page'
    [self.tabController.activeTabDocument.findOnPageView setShouldFocusTextField:YES];
    [self.tabController.activeTabDocument.findOnPageView showFindOnPage];
    break;

    default:
    break;
  }
  if(shouldClean && [self privateBrowsingEnabled])
  {
    //Remove private mode message
    [self.tabController.tiltedTabView setShowsExplanationView:NO animated:NO];
  }
}

%end
%end

%group iOS9
%hook BrowserController

//Present downloads view
%new
- (void)downloadsFromButtonBar
{
  //Create SPDownloadsNavigationController
  SPDownloadsNavigationController* downloadsController =
    [[SPDownloadsNavigationController alloc] init];

  dispatch_async(dispatch_get_main_queue(), ^
  {
    //Present SPDownloadsNavigationController
    [MSHookIvar<BrowserRootViewController*>(self, "_rootViewController")
      presentViewController:downloadsController animated:YES completion:nil];
  });
}

//URL Swipe actions
%new
- (void)handleSwipe:(NSInteger)swipeAction
{
  //Some cases need cleaing -> Create bool for that
  __block BOOL shouldClean = NO;

  switch(swipeAction)
  {
    case 1: //Close active tab
    [self.tabController.activeTabDocument _closeTabDocumentAnimated:NO];
    shouldClean = YES;
    break;

    case 2: //Open new tab
    [self.tabController newTab];
    break;

    case 3: //Duplicate active tab
    [self loadURLInNewWindow:[self.tabController.activeTabDocument URL]
      inBackground:preferenceManager.gestureBackground animated:YES];
    break;

    case 4: //Close all tabs from active mode
    [self.tabController closeAllOpenTabsAnimated:NO exitTabView:YES];
    shouldClean = YES;
    break;

    case 5: //Switch mode (Normal/Private)
    [self togglePrivateBrowsing];
    shouldClean = YES;
    break;

    case 6: //Tab backward
    {
      NSArray* currentTabs;
      if([self privateBrowsingEnabled])
      {
        //Private mode enabled -> set currentTabs to tabs of private mode
        currentTabs = self.tabController.privateTabDocuments;
      }
      else
      {
        //Private mode disabled -> set currentTabs to tabs of normal mode
        currentTabs = self.tabController.tabDocuments;
      }

      //Get index of previous tab
      NSInteger tabIndex = [currentTabs
        indexOfObject:self.tabController.activeTabDocument] - 1;

      if(tabIndex >= 0)
      {
        //tabIndex is not smaller than 0 -> switch to previous tab
        [self.tabController setActiveTabDocument:currentTabs[tabIndex] animated:NO];
      }
      break;
    }

    case 7: //Tab forward
    {
      NSArray* currentTabs;
      if([self privateBrowsingEnabled])
      {
        //Private mode enabled -> set currentTabs to tabs of private mode
        currentTabs = self.tabController.privateTabDocuments;
      }
      else
      {
        //Private mode disabled -> set currentTabs to tabs of normal mode
        currentTabs = self.tabController.tabDocuments;
      }

      //Get index of next tab
      NSInteger tabIndex = [currentTabs
        indexOfObject:self.tabController.activeTabDocument] + 1;

      if(tabIndex < [currentTabs count])
      {
        //tabIndex is not bigger than array -> switch to next tab
        [self.tabController setActiveTabDocument:currentTabs[tabIndex] animated:NO];
      }
      break;
    }

    case 8: //Reload active tab
    [self.tabController.activeTabDocument reload];
    break;

    case 9: //Request desktop site
    [self.tabController.activeTabDocument.reloadOptionsController requestDesktopSite];
    break;

    case 10: //Open 'find on page'
    self.shouldFocusFindOnPageTextField = YES;
    [self showFindOnPage];
    break;

    default:
    break;
  }
  if(shouldClean && [self privateBrowsingEnabled])
  {
    //Remove private mode message
    [self.tabController.tiltedTabView setShowsExplanationView:NO animated:NO];
  }
}

%end
%end

%hook BrowserController

%new
- (void)clearData
{
  //Clear history
  [self clearHistoryMessageReceived];

  //Clear autoFill stuff
  [self clearAutoFillMessageReceived];
}

//Used to close tabs based on the setting
%new
- (void)autoCloseAction
{
  switch(preferenceManager.autoCloseTabsFor)
  {
    case 1: //Active mode
    //Close tabs from active surfing mode
    [self.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];
    break;

    case 2: //Normal mode
    if([self privateBrowsingEnabled])
    {
      //Surfing mode is private -> switch to normal mode
      [self togglePrivateBrowsing];

      //Close tabs from normal mode
      [self.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];

      //Switch back to private mode
      [self togglePrivateBrowsing];
    }
    else
    {
      //Surfing mode is normal -> close tabs
      [self.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];
    }
    break;

    case 3: //Private mode
    if(![self privateBrowsingEnabled])
    {
      //Surfing mode is normal -> switch to private mode
      [self togglePrivateBrowsing];

      //Close tabs from private mode
      [self.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];

      //Switch back to normal mode
      [self togglePrivateBrowsing];
    }
    else
    {
      //Surfing mode is private -> close tabs
      [self.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];
    }
    break;

    case 4: //Both modes
    //Close tabs from active surfing mode
    [self.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];

    //Switch mode
    [self togglePrivateBrowsing];

    //Close tabs from other surfing mode
    [self.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];

    //Switch back
    [self togglePrivateBrowsing];
    break;

    default:
    break;
  }
}

//Used to switch mode based on the setting
%new
- (void)modeSwitchAction:(int)switchToMode
{
  if(switchToMode == 1 /*Normal Mode*/ &&
    [self privateBrowsingEnabled])
  {
    //Private browsing mode is active -> toggle browsing mode
    [self togglePrivateBrowsing];
  }

  else if(switchToMode == 2 /*Private Mode*/  &&
    ![self privateBrowsingEnabled])
  {
    //Normal browsing mode is active -> toggle browsing mode
    [self togglePrivateBrowsing];

    //Hide private mode notice
    [self.tabController.tiltedTabView
      setShowsExplanationView:NO animated:NO];
  }
}

%new
- (BOOL)usesTabBar
{
  //Return status of tabbar (delegate function)
  return [self.tabController usesTabBar];
}

//Full screen scrolling
- (BOOL)_isVerticallyConstrained
{
  if(preferenceManager.enableFullscreenScrolling)
  {
    return true;
  }

  return %orig;
}

//Fully disable private mode
- (BOOL)isPrivateBrowsingAvailable
{
  if(preferenceManager.disablePrivateMode)
  {
    return false;
  }

  return %orig;
}

//Update tabs according to desktop button status when user toggles browsing mode
- (void)togglePrivateBrowsing
{
  %orig;
  if(preferenceManager.desktopButtonEnabled)
  {
    [self.tabController reloadTabsIfNeeded];
  }
}

//Add swipe gestures to URL bar

//Create properties for gesture recognizers
%property(nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeLeftGestureRecognizer;
%property(nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeRightGestureRecognizer;
%property(nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeDownGestureRecognizer;

- (NavigationBar *)navigationBar
{
  if(preferenceManager.URLLeftSwipeGestureEnabled ||
    preferenceManager.URLRightSwipeGestureEnabled ||
    preferenceManager.URLDownSwipeGestureEnabled)
  {
    //At least one gesture enabled -> Add enabled gestures
    id orig = %orig;

    //Get URLOutline to add the gestures to
    _SFNavigationBarURLButton* URLOutline =
      MSHookIvar<_SFNavigationBarURLButton*>(orig, "_URLOutline");

    if(preferenceManager.URLLeftSwipeGestureEnabled)
    {
      if(!self.URLBarSwipeLeftGestureRecognizer)
      {
        //Left gesture enabled and not created already

        //Create gesture recognizer
        self.URLBarSwipeLeftGestureRecognizer = [[UISwipeGestureRecognizer alloc]
          initWithTarget:self action:@selector(navigationBarURLWasSwiped:)];

        //Set swipe direction to left
        self.URLBarSwipeLeftGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;

        //Add gestureRecognizer
        [URLOutline addGestureRecognizer:self.URLBarSwipeLeftGestureRecognizer];
      }
    }
    if(preferenceManager.URLRightSwipeGestureEnabled)
    {
      if(!self.URLBarSwipeRightGestureRecognizer)
      {
        //Right gesture enabled and not created already

        //Create gesture recognizer
        self.URLBarSwipeRightGestureRecognizer = [[UISwipeGestureRecognizer alloc]
          initWithTarget:self action:@selector(navigationBarURLWasSwiped:)];

        //Set swipe direction to right
        self.URLBarSwipeRightGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;

        //Add gestureRecognizer
        [URLOutline addGestureRecognizer:self.URLBarSwipeRightGestureRecognizer];
      }
    }
    if(preferenceManager.URLDownSwipeGestureEnabled)
    {
      if(!self.URLBarSwipeDownGestureRecognizer)
      {
        //Down gesture enabled and not created already

        //Create gesture recognizer
        self.URLBarSwipeDownGestureRecognizer = [[UISwipeGestureRecognizer alloc]
          initWithTarget:self action:@selector(navigationBarURLWasSwiped:)];

        //Set swipe direction to down
        self.URLBarSwipeDownGestureRecognizer.direction = UISwipeGestureRecognizerDirectionDown;

        //Add gestureRecognizer
        [URLOutline addGestureRecognizer:self.URLBarSwipeDownGestureRecognizer];
      }
    }
    return orig;
  }
  return %orig;
}

//Call method based on the direction of the url bar swipe
%new
- (void)navigationBarURLWasSwiped:(UISwipeGestureRecognizer*)swipe
{
  switch(swipe.direction)
  {
    case UISwipeGestureRecognizerDirectionLeft:
    //Bar swiped left -> handle swipe
    [self handleSwipe:preferenceManager.URLLeftSwipeAction];
    break;

    case UISwipeGestureRecognizerDirectionRight:
    //Bar swiped right -> handle swipe
    [self handleSwipe:preferenceManager.URLRightSwipeAction];
    break;

    case UISwipeGestureRecognizerDirectionDown:
    //Bar swiped down -> handle swipe
    [self handleSwipe:preferenceManager.URLDownSwipeAction];
    break;
  }
}

%end

%ctor
{
  if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0)
  {
    %init(iOS10);
  }
  else if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0)
  {
    %init(iOS9);
  }
  %init;
}
