//  SPDownloadsNavigationController.h
// (c) 2017 opa334

#import "SPFileBrowserNavigationController.h"
#import "../Protocols.h"

@interface SPDownloadsNavigationController : SPFileBrowserNavigationController <DownloadNavigationControllerDelegate> {}
- (void)handleNavigationBarLongPress:(UILongPressGestureRecognizer*)sender;
@end
