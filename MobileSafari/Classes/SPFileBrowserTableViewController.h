//  SPFileBrowserTableViewController.h
// (c) 2017 opa334

#import "SPFileBrowserNavigationController.h"
#import "SPFileTableViewCell.h"
#import "SPLocalizationManager.h"
#import "../Shared.h"

@interface SPFileBrowserTableViewController : UITableViewController
{
  NSMutableArray* filesAtCurrentPath;
  NSFileManager* fileManager;
}

@property (nonatomic) NSURL* currentPath;
- (UIBarButtonItem*)defaultRightBarButtonItem;
- (id)initWithPath:(NSURL*)path;
- (void)selectedFileAtURL:(NSURL*)fileURL type:(NSInteger)type atIndexPath:(NSIndexPath*)indexPath;
- (id)newCellWithFileURL:(NSURL*)fileURL;
- (void)reloadDataAndDataSources;
- (void)populateDataSources;
- (void)pulledToRefresh;
- (void)dismiss;
@end
