//  fileBrowserTableViewController.xm
// (c) 2017 opa334

#import "fileBrowserTableViewController.h"

@implementation fileBrowserTableViewController

- (id)initWithPath:(NSURL*)path
{
    self = [super init];
    if(self)
    {
      if(path)
      {
        self.title = path.lastPathComponent;

        self.currentPath = path.URLByResolvingSymlinksInPath;

        //Resolve weird problem
        self.currentPath = [NSURL fileURLWithPath:[self.currentPath.path stringByReplacingOccurrencesOfString:@"/var" withString:@"/private/var"]];
      }
    }
    return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.refreshControl = [[UIRefreshControl alloc] init];
  [self.refreshControl addTarget:self
                  action:@selector(pulledToRefresh)
                forControlEvents:UIControlEventValueChanged];

  fileManager = [NSFileManager defaultManager];

  //If path is not set, set it to root
  if(!self.currentPath)
  {
    self.currentPath = ((fileBrowserNavigationController*)self.navigationController).rootPath;
  }

  self.navigationItem.rightBarButtonItem = [self defaultRightBarButtonItem];

  [self populateDataSources];
}

- (void)pulledToRefresh
{
  [self reloadDataAndDataSources];
  [self.refreshControl endRefreshing];
}

- (void)populateDataSources
{
  //Fetch files from current path into array
  filesAtCurrentPath = (NSMutableArray*)[fileManager contentsOfDirectoryAtURL:self.currentPath includingPropertiesForKeys:nil options:nil error:nil];

  //Sort files alphabetically
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastPathComponent" ascending:YES selector:@selector(caseInsensitiveCompare:)];
  filesAtCurrentPath = (NSMutableArray*)[filesAtCurrentPath sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
}

- (void)reloadDataAndDataSources
{
  dispatch_async(dispatch_get_main_queue(),
  ^{
    [self populateDataSources];
    NSRange range = NSMakeRange(0, [self numberOfSectionsInTableView:self.tableView]);
    NSIndexSet* sections = [NSIndexSet indexSetWithIndexesInRange:range];
    [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationFade];
  });
}

- (UIBarButtonItem*)defaultRightBarButtonItem
{
  return [[UIBarButtonItem alloc] initWithTitle:[localizationManager localizedSPStringForKey:@"DISMISS"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
}

- (void)dismiss
{
  dispatch_async(dispatch_get_main_queue(), ^
  {
    [self dismissViewControllerAnimated:YES completion:nil];
  });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return [filesAtCurrentPath count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell* cell;
  NSURL* currentEntry = filesAtCurrentPath[indexPath.row];
  NSString* currentEntryString = [[[currentEntry absoluteString] lastPathComponent] stringByRemovingPercentEncoding];

  NSNumber* isFile;

  [currentEntry getResourceValue:&isFile forKey:NSURLIsRegularFileKey error:nil];

  //Entry is file
  if([isFile boolValue])
  {
    int64_t fileSize = [[fileManager attributesOfItemAtPath:[currentEntry path] error:nil] fileSize];
    cell = [self newCellWithSize:fileSize];
    cell.imageView.image = [UIImage imageNamed:@"File.png" inBundle:SPBundle compatibleWithTraitCollection:nil];
  }

  //Entry is directory
  else
  {
    cell = [self newCell];
    cell.imageView.image = [UIImage imageNamed:@"Directory.png" inBundle:SPBundle compatibleWithTraitCollection:nil];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  }

  cell.textLabel.text = currentEntryString;

  //Entry is hidden
  if([currentEntryString hasPrefix:@"."])
  {
    cell.imageView.alpha = 0.4;
    cell.textLabel.alpha = 0.4;
  }

  [cell setSeparatorInset:UIEdgeInsetsZero];

  return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if(tableView.editing)
  {
    NSURL* selectedEntry = filesAtCurrentPath[indexPath.row];
    NSNumber* isFile;

    [selectedEntry getResourceValue:&isFile forKey:NSURLIsRegularFileKey error:nil];
    if(![isFile boolValue])
    {
      return nil;
    }
  }

  return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if(!tableView.editing)
  {
    NSURL* fileURL = filesAtCurrentPath[indexPath.row];

    NSNumber* isFile;

    [fileURL getResourceValue:&isFile forKey:NSURLIsRegularFileKey error:nil];

    //Tapped entry is file
    if([isFile boolValue])
    {
      [self selectedEntryAtURL:fileURL type:1 atIndexPath:indexPath];
    }
    //Tapped entry is directory
    else
    {
      [self selectedEntryAtURL:fileURL type:2 atIndexPath:indexPath];
    }
  }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSNumber* isFile;
  NSURL* row = filesAtCurrentPath[indexPath.row];

  [row getResourceValue:&isFile forKey:NSURLIsRegularFileKey error:nil];

  if([isFile boolValue])
  {
    return YES;
  }
  else
  {
    return NO;
  }
}

- (void)selectedEntryAtURL:(NSURL*)entryURL type:(NSInteger)type atIndexPath:(NSIndexPath*)indexPath
{
  //Type 1: file; type 2: directory
  if(type == 2)
  {
    [self.navigationController pushViewController:[(fileBrowserNavigationController*)self.navigationController newTableViewControllerWithPath:entryURL] animated:YES];
  }
}

- (id)newCell
{
  return [[fileTableViewCell alloc] init];
}

- (id)newCellWithSize:(int64_t)size
{
  return [[fileTableViewCell alloc] initWithSize:size];
}

@end
