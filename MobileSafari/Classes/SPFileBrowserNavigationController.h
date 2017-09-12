//  SPFileBrowserNavigationController.h
// (c) 2017 opa334

#import "SPFileBrowserTableViewController.h"

@interface SPFileBrowserNavigationController : UINavigationController {}
- (id)newTableViewControllerWithPath:(NSURL*)path;
- (void)reloadTopTableView;
- (void)reloadAllTableViews;
- (BOOL)shouldLoadPreviousPathElements;
- (NSURL*)rootPath;
@end
