//  SPDownloadsNavigationController.h
// (c) 2017 opa334

#import "SPFileBrowserNavigationController.h"
#import "SPPreferenceManager.h"
#import "SPDownloadsTableViewController.h"
#import "../Shared.h"

@interface SPDownloadsNavigationController : SPFileBrowserNavigationController <DownloadNavigationControllerDelegate> {}
- (void)handleNavigationBarLongPress:(UILongPressGestureRecognizer*)sender;
@end
