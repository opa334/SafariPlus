//  fileBrowserTableViewController.h
// (c) 2017 opa334

#import "fileBrowserNavigationController.h"
#import "fileTableViewCell.h"
#import "SPLocalizationManager.h"

@interface fileBrowserTableViewController : UITableViewController
{
  NSMutableArray* filesAtCurrentPath;
  NSFileManager* fileManager;
}

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
