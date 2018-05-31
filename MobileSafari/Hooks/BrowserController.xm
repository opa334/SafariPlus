// BrowserController.xm
// (c) 2017 opa334

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

#import "../Defines.h"
#import "../Enums.h"
#import "../Shared.h"
#import "../Classes/SPPreferenceManager.h"
#import "../Classes/SPDownloadsNavigationController.h"

%hook BrowserController

//Properties for gesture recognizers
%property(nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeLeftGestureRecognizer;
%property(nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeRightGestureRecognizer;
%property(nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeDownGestureRecognizer;

//Present downloads view
%new
- (void)downloadsFromButtonBar
{
  //Create SPDownloadsNavigationController
  SPDownloadsNavigationController* downloadsController =
    [[SPDownloadsNavigationController alloc] init];

  //Present SPDownloadsNavigationController
  [rootViewControllerForBrowserController(self) presentViewController:downloadsController
    animated:YES completion:nil];
}

//URL Swipe actions
%new
- (void)handleGesture:(NSInteger)swipeAction
{
  //Some cases need cleaning -> Create bool for that
  __block BOOL shouldClean = NO;

  switch(swipeAction)
  {
    case GestureActionCloseActiveTab:
    [self.tabController.activeTabDocument _closeTabDocumentAnimated:NO];
    shouldClean = YES;
    break;

    case GestureActionOpenNewTab:
    {
      if(iOSVersion >= 9)
      {
        [self.tabController newTab];
      }
      else //iOS 8
      {
        [self newTabKeyPressed];
      }
      break;
    }

    case GestureActionDuplicateActiveTab:
    {
      if(iOSVersion >= 10)
      {
        [self loadURLInNewTab:[self.tabController.activeTabDocument URL]
          inBackground:preferenceManager.gestureBackground animated:YES];
      }
      else //iOS 8, 9
      {
        [self loadURLInNewWindow:[self.tabController.activeTabDocument URL]
          inBackground:preferenceManager.gestureBackground animated:YES];
      }

      break;
    }

    case GestureActionCloseAllTabs:
    {
      [self.tabController closeAllOpenTabsAnimated:NO exitTabView:YES];
      shouldClean = YES;
      break;
    }

    case GestureActionSwitchMode:
    {
      togglePrivateBrowsing(self);
      shouldClean = YES;
    }
    break;

    case GestureActionSwitchTabBackwards:
    {
      NSArray* activeTabs;

      if(privateBrowsingEnabled(self))
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

    case GestureActionSwitchTabForwards:
    {
      NSArray* activeTabs;

      if(privateBrowsingEnabled(self))
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

    case GestureActionReloadActiveTab:
    {
      [self.tabController.activeTabDocument reload];
      break;
    }

    case GestureActionRequestDesktopSite:
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

    case GestureActionOpenFindOnPage:
    {
      //Not available on iOS 8
      if(iOSVersion != 8)
      {
        if(iOSVersion >= 10)
        {
          [self.tabController.activeTabDocument.findOnPageView setShouldFocusTextField:YES];
          [self.tabController.activeTabDocument.findOnPageView showFindOnPage];
        }
        else //iOS 9
        {
          self.shouldFocusFindOnPageTextField = YES;
          [self showFindOnPage];
        }
      }
      break;
    }

    default:
    break;
  }
  if(shouldClean && privateBrowsingEnabled(self))
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
    case CloseTabActionFromActiveMode:
    //Close tabs from active surfing mode
    [self.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];
    break;

    case CloseTabActionFromNormalMode:
    if(privateBrowsingEnabled(self))
    {
      //Surfing mode is private -> switch to normal mode
      togglePrivateBrowsing(self);

      //Close tabs from normal mode
      [self.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];

      //Switch back to private mode
      togglePrivateBrowsing(self);
    }
    else
    {
      //Surfing mode is normal -> close tabs
      [self.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];
    }
    break;

    case CloseTabActionFromPrivateMode:
    if(!privateBrowsingEnabled(self))
    {
      //Surfing mode is normal -> switch to private mode
      togglePrivateBrowsing(self);

      //Close tabs from private mode
      [self.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];

      //Switch back to normal mode
      togglePrivateBrowsing(self);
    }
    else
    {
      //Surfing mode is private -> close tabs
      [self.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];
    }
    break;

    case CloseTabActionFromBothModes: //Both modes
    //Close tabs from active surfing mode
    [self.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];

    //Switch mode
    togglePrivateBrowsing(self);

    //Close tabs from other surfing mode
    [self.tabController closeAllOpenTabsAnimated:YES exitTabView:YES];

    //Switch back
    togglePrivateBrowsing(self);
    break;

    default:
    break;
  }
}

//Used to switch mode based on the setting
%new
- (void)modeSwitchAction:(int)switchToMode
{
  if(switchToMode == ModeSwitchActionNormalMode && privateBrowsingEnabled(self))
  {
    //Private browsing mode is active -> toggle browsing mode
    togglePrivateBrowsing(self);
  }

  else if(switchToMode == ModeSwitchActionPrivateMode  && !privateBrowsingEnabled(self))
  {
    //Normal browsing mode is active -> toggle browsing mode
    togglePrivateBrowsing(self);

    //Hide private mode notice
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

//Full screen scrolling
- (BOOL)_isVerticallyConstrained
{
  return (preferenceManager.fullscreenScrollingEnabled) ? YES : %orig;
}

//Fully disable private mode
- (BOOL)isPrivateBrowsingAvailable
{
  return (preferenceManager.disablePrivateMode) ? NO : %orig;
}


- (BOOL)dynamicBarAnimator:(id)arg1 canHideBarsByDraggingWithOffset:(CGFloat)arg2
{
  return (preferenceManager.lockBars) ? NO : %orig;
}

- (void)_initSubviews
{
  %orig;
  if(preferenceManager.URLLeftSwipeGestureEnabled || preferenceManager.URLRightSwipeGestureEnabled
    || preferenceManager.URLDownSwipeGestureEnabled)
  {
    _SFNavigationBarURLButton* URLButton = MSHookIvar<_SFNavigationBarURLButton*>(self.navigationBar, "_URLOutline");

    if(preferenceManager.URLLeftSwipeGestureEnabled)
    {
      //Create gesture recognizer
      self.URLBarSwipeLeftGestureRecognizer = [[UISwipeGestureRecognizer alloc]
        initWithTarget:self action:@selector(navigationBarURLWasSwiped:)];

      //Set swipe direction to left
      self.URLBarSwipeLeftGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;

      //Add gestureRecognizer
      [URLButton addGestureRecognizer:self.URLBarSwipeLeftGestureRecognizer];
    }

    if(preferenceManager.URLRightSwipeGestureEnabled && !self.URLBarSwipeRightGestureRecognizer)
    {
      //Create gesture recognizer
      self.URLBarSwipeRightGestureRecognizer = [[UISwipeGestureRecognizer alloc]
        initWithTarget:self action:@selector(navigationBarURLWasSwiped:)];

      //Set swipe direction to right
      self.URLBarSwipeRightGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;

      //Add gestureRecognizer
      [URLButton addGestureRecognizer:self.URLBarSwipeRightGestureRecognizer];
    }

    if(preferenceManager.URLDownSwipeGestureEnabled && !self.URLBarSwipeDownGestureRecognizer)
    {
      //Create gesture recognizer
      self.URLBarSwipeDownGestureRecognizer = [[UISwipeGestureRecognizer alloc]
        initWithTarget:self action:@selector(navigationBarURLWasSwiped:)];

      //Set swipe direction to down
      self.URLBarSwipeDownGestureRecognizer.direction = UISwipeGestureRecognizerDirectionDown;

      //Add gestureRecognizer
      [URLButton addGestureRecognizer:self.URLBarSwipeDownGestureRecognizer];
    }
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

%group iOS9Up
%hook BrowserController

//Auto switch mode on external URL opened
- (NSURL*)handleExternalURL:(NSURL*)URL
{
  if(URL && preferenceManager.forceModeOnExternalLinkEnabled)
  {
    [self modeSwitchAction:preferenceManager.forceModeOnExternalLinkFor];
  }

  return %orig;
}

%end
%end

%ctor
{
  if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0)
  {
    %init(iOS9Up);
  }

  %init();
}
