//  fileBrowserNavigationController.h
// (c) 2017 opa334

#import "fileBrowserTableViewController.h"

@interface fileBrowserNavigationController : UINavigationController {}
- (id)newTableViewControllerWithPath:(NSURL*)path;
- (void)reloadAllTableViews;
- (BOOL)shouldLoadPreviousPathElements;
- (NSURL*)rootPath;
@end
