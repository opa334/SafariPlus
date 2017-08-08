//  filePickerTableViewController.xm
// (c) 2017 opa334

#import "filePickerTableViewController.h"

@implementation filePickerTableViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.tableView.allowsMultipleSelectionDuringEditing = YES;

  UILongPressGestureRecognizer *tableLongPressRecognizer = [[UILongPressGestureRecognizer alloc]
  initWithTarget:self action:@selector(tableWasLongPressed:)];
  tableLongPressRecognizer.minimumPressDuration = 1.0;
  [self.tableView addGestureRecognizer:tableLongPressRecognizer];
}

- (void)dismiss
{
  [((filePickerNavigationController*)self.navigationController).filePickerDelegate didSelectFilesAtURL:nil];
}

- (void)selectedEntryAtURL:(NSURL*)entryURL type:(NSInteger)type atIndexPath:(NSIndexPath*)indexPath
{
  //Type 1: file; type 2: symlink; type 3: directory
  if(type == 1)
  {
    [((filePickerNavigationController*)self.navigationController).filePickerDelegate didSelectFilesAtURL:@[entryURL]];
  }

  [super selectedEntryAtURL:entryURL type:type atIndexPath:indexPath];
}

- (void)tableWasLongPressed:(UILongPressGestureRecognizer *)gestureRecognizer
{
  if(!self.tableView.editing)
  {
    CGPoint p = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];

    if(gestureRecognizer.state == UIGestureRecognizerStateBegan && indexPath)
    {
      [self toggleEditing];

      NSNumber* isFile;
      [(NSURL*)filesAtCurrentPath[indexPath.row] getResourceValue:&isFile forKey:NSURLIsRegularFileKey error:nil];

      if([isFile boolValue])
      {
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        [self updateTopRightButtonAvailability];
      }
    }
  }
}

- (void)toggleEditing
{
  [self.tableView setEditing:!self.tableView.editing animated:YES];
  if(self.tableView.editing)
  {
    UIBarButtonItem* cancelItem = [[UIBarButtonItem alloc] initWithTitle:[localizationManager localizedSPStringForKey:@"CANCEL"] style:UIBarButtonItemStylePlain target:self action:@selector(toggleEditing)];
    UIBarButtonItem* uploadItem = [[UIBarButtonItem alloc] initWithTitle:[localizationManager localizedSPStringForKey:@"UPLOAD"] style:UIBarButtonItemStylePlain target:self action:@selector(uploadSelectedItems)];

    self.navigationItem.leftBarButtonItem = cancelItem;
    self.navigationItem.rightBarButtonItem = uploadItem;

    self.navigationItem.rightBarButtonItem.enabled = NO;
  }
  else
  {
    self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;
    self.navigationItem.rightBarButtonItem = [self defaultRightBarButtonItem];
    self.navigationItem.rightBarButtonItem.enabled = YES;
  }
}

- (void)uploadSelectedItems
{
  NSArray* selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
  NSMutableArray* selectedURLs = [NSMutableArray new];

  for(int i = 0; i < [selectedIndexPaths count]; i++)
  {
    NSIndexPath* indexPath = selectedIndexPaths[i];
    NSURL* filePath = filesAtCurrentPath[indexPath.row];
    [selectedURLs addObject:filePath];
  }

  [((filePickerNavigationController*)self.navigationController).filePickerDelegate didSelectFilesAtURL:selectedURLs];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [super tableView:tableView didSelectRowAtIndexPath:indexPath];
  [self updateTopRightButtonAvailability];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [self updateTopRightButtonAvailability];
}

- (void)updateTopRightButtonAvailability
{
  if(self.tableView.editing)
  {
    NSArray *selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
    if([selectedIndexPaths count] <= 0)
    {
      self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    else
    {
      self.navigationItem.rightBarButtonItem.enabled = YES;
    }
  }
  else
  {
    self.navigationItem.rightBarButtonItem.enabled = YES;
  }
}

@end
