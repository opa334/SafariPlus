// BrowserController.xm
// (c) 2017 opa334

#import "../SafariPlus.h"

#import "../Shared.h"
#import "../Classes/SPPreferenceManager.h"
#import "../Classes/SPDownloadsNavigationController.h"

%hook BrowserController

//Present downloads view
%new
- (void)downloadsFromButtonBar
{
  //Create SPDownloadsNavigationController
  SPDownloadsNavigationController* downloadsController =
    [[SPDownloadsNavigationController alloc] init];

  if(iOSVersion > 9)
  {
    dispatch_async(dispatch_get_main_queue(), ^
    {
      //Present SPDownloadsNavigationController
      [self.rootViewController presentViewController:downloadsController
        animated:YES completion:nil];
    });
  }
  else
  {
    dispatch_async(dispatch_get_main_queue(), ^
    {
      //Present SPDownloadsNavigationController
      [MSHookIvar<BrowserRootViewController*>(self, "_rootViewController")
        presentViewController:downloadsController animated:YES completion:nil];
    });
  }
}

//URL Swipe actions
%new
- (void)handleGesture:(NSInteger)swipeAction
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
    {
      if(iOSVersion == 8)
      {
        [self newTabKeyPressed];
      }
      else
      {
        [self.tabController newTab];
      }
      break;
    }

    case 3: //Duplicate active tab
    {
      switch(iOSVersion)
      {
        case 8:
        case 9:
        [self loadURLInNewWindow:[self.tabController.activeTabDocument URL]
          inBackground:preferenceManager.gestureBackground animated:YES];
        break;

        case 10:
        case 11:
        [self loadURLInNewTab:[self.tabController.activeTabDocument URL]
          inBackground:preferenceManager.gestureBackground animated:YES];
        break;
      }
      break;
    }

    case 4: //Close all tabs from active mode
    [self.tabController closeAllOpenTabsAnimated:NO exitTabView:YES];
    shouldClean = YES;
    break;

    case 5: //Switch mode (Normal/Private)
    {
      togglePrivateBrowsing();
      shouldClean = YES;
    }
    break;

    case 6: //Tab backward
    {
      NSArray* activeTabs;

      if(privateBrowsingEnabled())
      {
        //Private mode enabled -> set currentTabs to tabs of private mode
        activeTabs = self.tabController.privateTabDocuments;
      }
      else
      {
        //Private mode disabled -> set currentTabs to tabs of normal mode
        activeTabs = self.tabController.tabDocuments;
      }

      //Get index of previous tab
      NSInteger tabIndex = [activeTabs indexOfObject:
        self.tabController.activeTabDocument] - 1;

      if(tabIndex >= 0)
      {
        //tabIndex is greater than 0 -> switch to previous tab
        [self.tabController setActiveTabDocument: activeTabs[tabIndex] animated:NO];
      }
      break;
    }

    case 7: //Tab forward
    {
      NSArray* activeTabs;

      if(privateBrowsingEnabled())
      {
        //Private mode enabled -> set currentTabs to tabs of private mode
        activeTabs = self.tabController.privateTabDocuments;
      }
      else
      {
        //Private mode disabled -> set currentTabs to tabs of normal mode
        activeTabs = self.tabController.tabDocuments;
      }

      //Get index of next tab
      NSInteger tabIndex = [activeTabs indexOfObject:
        self.tabController.activeTabDocument] + 1;

      if(tabIndex < [activeTabs count])
      {
        //tabIndex is not bigger than array -> switch to next tab
        [self.tabController setActiveTabDocument:activeTabs[tabIndex] animated:NO];
      }
      break;
    }

    case 8: //Reload active tab
    [self.tabController.activeTabDocument reload];
    break;

    case 9: //Request desktop site
    {
      if(iOSVersion > 8)
      {
        [self.tabController.activeTabDocument.reloadOptionsController requestDesktopSite];
      }
      else
      {
        [self.tabController.activeTabDocument requestDesktopSite];
      }
      break;
    }

    case 10: //Open 'find on page'
    {
      if(iOSVersion != 8)
      {
        if(iOSVersion == 9)
        {
          self.shouldFocusFindOnPageTextField = YES;
          [self showFindOnPage];
        }
        else
        {
          [self.tabController.activeTabDocument.findOnPageView setShouldFocusTextField:YES];
          [self.tabController.activeTabDocument.findOnPageView showFindOnPage];
        }
      }
      break;
    }

    default:
    break;
  }
  if(shouldClean && privateBrowsingEnabled())
  {
    //Remove private mode message
    if(iOSVersion >= 11)
    {
      [self.tabController.tiltedTabView setShowsPrivateBrowsingExplanationView:NO
        animated:NO];
    }
    else
    {
      [self.tabController.tiltedTabView setShowsExplanationView:NO animated:NO];
    }
  }
}

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
    if(privateBrowsingEnabled())
    {
      //Surfing mode is private -> switch to normal mode
      togglePrivateBrowsing();

      //Close tabs from normal mode
      [self.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];

      //Switch back to private mode
      togglePrivateBrowsing();
    }
    else
    {
      //Surfing mode is normal -> close tabs
      [self.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];
    }
    break;

    case 3: //Private mode
    if(!privateBrowsingEnabled())
    {
      //Surfing mode is normal -> switch to private mode
      togglePrivateBrowsing();

      //Close tabs from private mode
      [self.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];

      //Switch back to normal mode
      togglePrivateBrowsing();
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
    togglePrivateBrowsing();

    //Close tabs from other surfing mode
    [self.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];

    //Switch back
    togglePrivateBrowsing();
    break;

    default:
    break;
  }
}

//Used to switch mode based on the setting
%new
- (void)modeSwitchAction:(int)switchToMode
{
  if(switchToMode == 1 /*Normal Mode*/ && privateBrowsingEnabled())
  {
    //Private browsing mode is active -> toggle browsing mode
    togglePrivateBrowsing();
  }

  else if(switchToMode == 2 /*Private Mode*/  && !privateBrowsingEnabled())
  {
    //Normal browsing mode is active -> toggle browsing mode
    togglePrivateBrowsing();

    //Hide private mode notice
    [self.tabController.tiltedTabView
      setShowsExplanationView:NO animated:NO];
  }
}

//Full screen scrolling
- (BOOL)_isVerticallyConstrained
{
  return (preferenceManager.enableFullscreenScrolling) ? YES : %orig;
}

//Fully disable private mode
- (BOOL)isPrivateBrowsingAvailable
{
  return (preferenceManager.disablePrivateMode) ? NO : %orig;
}


- (BOOL)dynamicBarAnimator:(id)arg1 canHideBarsByDraggingWithOffset:(float)arg2
{
  return (preferenceManager.lockBars) ? NO : %orig;
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

//Call method based on the direction of the url bar swipe
%new
- (void)navigationBarURLWasSwiped:(UISwipeGestureRecognizer*)swipe
{
  switch(swipe.direction)
  {
    case UISwipeGestureRecognizerDirectionLeft:
    //Bar swiped left -> handle swipe
    [self handleGesture:preferenceManager.URLLeftSwipeAction];
    break;

    case UISwipeGestureRecognizerDirectionRight:
    //Bar swiped right -> handle swipe
    [self handleGesture:preferenceManager.URLRightSwipeAction];
    break;

    case UISwipeGestureRecognizerDirectionDown:
    //Bar swiped down -> handle swipe
    [self handleGesture:preferenceManager.URLDownSwipeAction];
    break;
  }
}

%end
