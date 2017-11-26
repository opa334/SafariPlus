// BrowserRootViewController.xm
// (c) 2017 opa334

#import "../SafariPlus.h"

#import "../Defines.h"
#import "../Shared.h"
#import "../Classes/SPPreferenceManager.h"
#import "../Classes/SPDownloadManager.h"
#import "../Lib/CWStatusBarNotification.h"

%group iOS10
%hook BrowserRootViewController

//Initialise status bar notifications
- (void)viewDidLoad
{
  %orig;
  if(preferenceManager.enhancedDownloadsEnabled)
  {
    //Set SPDownloadManager delegate to self for communication
    [SPDownloadManager sharedInstance].rootControllerDelegate = self;

    if(!preferenceManager.disableBarNotificationsEnabled && !self.statusBarNotification)
    {
      //Create Status Bar Notification and set up properties
      self.statusBarNotification = [CWStatusBarNotification new];
      self.statusBarNotification.notificationLabelBackgroundColor = [UIColor blueColor];
      self.statusBarNotification.notificationAnimationInStyle = CWNotificationAnimationStyleTop;
      self.statusBarNotification.notificationAnimationOutStyle = CWNotificationAnimationStyleTop;
    }
  }
}

%end
%end

%group iOS9_8
%hook BrowserRootViewController

//Initialise status bar notifications
- (id)init
{
  self = %orig;
  if(preferenceManager.enhancedDownloadsEnabled)
  {
    //Set SPDownloadManager delegate to self for communication
    [SPDownloadManager sharedInstance].rootControllerDelegate = self;

    if(!preferenceManager.disableBarNotificationsEnabled)
    {
      //Create Status Bar Notification and set up properties
      self.statusBarNotification = [CWStatusBarNotification new];
      self.statusBarNotification.notificationLabelBackgroundColor = [UIColor blueColor];
      self.statusBarNotification.notificationAnimationInStyle = CWNotificationAnimationStyleTop;
      self.statusBarNotification.notificationAnimationOutStyle = CWNotificationAnimationStyleTop;
    }
  }
  return self;
}

%end
%end

%hook BrowserRootViewController

%property(nonatomic, retain) CWStatusBarNotification *statusBarNotification;

//Dispatch status bar notification
%new
- (void)dispatchNotificationWithText:(NSString*)text
{
  dispatch_async(dispatch_get_main_queue(), ^
  {
    [self.statusBarNotification displayNotificationWithMessage:text forDuration:2.0f];
  });
}

//Dismiss notification
%new
- (void)dismissNotificationWithCompletion:(void (^)(void))completion
{
  dispatch_async(dispatch_get_main_queue(), ^
  {
    [self.statusBarNotification dismissNotificationWithCompletion:completion];
  });
}

//Present alertController with sheet on rootController (needed for iPad positions)
%new
- (void)presentAlertControllerSheet:(UIAlertController*)alertController
{
  dispatch_async(dispatch_get_main_queue(), ^
  {
    //Set iPad positions to middle of screen
    alertController.popoverPresentationController.sourceView = self.view;
    alertController.popoverPresentationController.sourceRect =
      CGRectMake(self.view.bounds.size.width / 2,
      self.view.bounds.size.height / 2, 1.0, 1.0);

    //Make it always face upwards on iPad
    [alertController.popoverPresentationController
      setPermittedArrowDirections:UIPopoverArrowDirectionDown];

    //Present alert
    [self presentViewController:alertController animated:YES completion:nil];
  });
}


//Present viewController on rootController
%new
- (void)presentViewController:(id)viewController
{
  dispatch_async(dispatch_get_main_queue(), ^
  {
    [self presentViewController:viewController animated:YES completion:nil];
  });
}

%end

%ctor
{
  if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0)
  {
    %init(iOS10);
  }
  else
  {
    %init(iOS9_8);
  }
  %init;
}
