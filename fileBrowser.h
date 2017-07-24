//  fileBrowser.h
//  Headers for file browser

// (c) 2017 opa334

#import "SafariPlusUtil.h"

@class fileBrowserNavigationController;

@interface fileBrowserNavigationController : UINavigationController {}
- (id)newTableViewControllerWithPath:(NSURL*)path;
- (void)reloadAllTableViews;
- (BOOL)shouldLoadPreviousPathElements;
- (NSURL*)rootPath;
@end

@interface fileBrowserTableViewController : UITableViewController
{
  NSMutableArray* filesAtCurrentPath;
  NSFileManager* fileManager;
}
@property fileBrowserNavigationController* navController;
@property (nonatomic) NSURL* currentPath;
- (UIBarButtonItem*)defaultRightBarButtonItem;
- (id)initWithPath:(NSURL*)path;
- (void)selectedEntryAtURL:(NSURL*)entryURL type:(NSInteger)type atIndexPath:(NSIndexPath*)indexPath;
- (id)newCell;
- (id)newCellWithSize:(int64_t)size;
- (void)reloadDataAndDataSources;
- (void)populateDataSources;
- (void)pulledToRefresh;
- (void)dismiss;
@end

@interface fileTableViewCell : UITableViewCell {}
- (id)initWithSize:(int64_t)size;
@end
