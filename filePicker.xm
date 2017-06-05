//  filePicker.xm
//  File picker for uploading

// (c) 2017 opa334

#import "filePicker.h"

@implementation filePickerTableViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    fileManager = [NSFileManager defaultManager];

    //If path is not set, set it to root
    if(!self.currentPath)
    {
      self.currentPath = [NSURL URLWithString:@"/"];
    }

    //Fetch files from current path into array
    filesAtCurrentPath = [[NSMutableArray alloc] init];
    filesAtCurrentPath = (NSMutableArray*)[fileManager contentsOfDirectoryAtURL:self.currentPath includingPropertiesForKeys:nil options:nil error:nil];

    //Sort files alphabetically
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastPathComponent" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    filesAtCurrentPath = (NSMutableArray*)[filesAtCurrentPath sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];

    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:[%c(LGShared) localisedStringForKey:@"CANCEL"] style:UIBarButtonItemStylePlain target:self action:@selector(cancelFilePicker)];
    self.navigationItem.rightBarButtonItem = cancelButton;

    self.title = [self.currentPath lastPathComponent];
}

- (void)cancelFilePicker
{
  [((filePickerNavigationController*)self.navigationController).filePickerDelegate didSelectFileAtURL:nil shouldCancel:YES];
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
  UITableViewCell* cell = [[UITableViewCell alloc] init];
  NSURL* currentEntry = filesAtCurrentPath[indexPath.row];
  NSString* currentEntryString = [[[currentEntry absoluteString] lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

  cell.textLabel.text = currentEntryString;

  NSNumber* isFile;

  [currentEntry getResourceValue:&isFile forKey:NSURLIsRegularFileKey error:nil];

  //Entry is file
  if([isFile boolValue])
  {
    cell.imageView.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/File.png", imageBundlePath]];
  }
  //Entry is directory / symlink
  else
  {
    cell.imageView.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/Directory.png", imageBundlePath]];
  }

  //Entry is hidden
  if([currentEntryString hasPrefix:@"."])
  {
    cell.imageView.alpha = 0.4;
    cell.textLabel.alpha = 0.4;
  }

  //http://stackoverflow.com/a/17517552
  CGSize itemSize = CGSizeMake(28, 28);
  UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
  CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
  [cell.imageView.image drawInRect:imageRect];
  cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  [cell setSeparatorInset:UIEdgeInsetsZero];

  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSURL* selectedEntry = filesAtCurrentPath[indexPath.row];
  NSNumber* isFile;

  [selectedEntry getResourceValue:&isFile forKey:NSURLIsRegularFileKey error:nil];

  //Tapped entry is file
  if([isFile boolValue])
  {
    [((filePickerNavigationController*)self.navigationController).filePickerDelegate didSelectFileAtURL:selectedEntry shouldCancel:NO];
  }
  else
  {
    NSNumber* isSymlink;
    [selectedEntry getResourceValue:&isSymlink forKey:NSURLIsSymbolicLinkKey error:nil];
    filePickerTableViewController *nextController = [[filePickerTableViewController alloc] init];

    //Tapped entry is symlink
    if([isSymlink boolValue])
    {
      nextController.currentPath = [NSURL URLWithString:[fileManager destinationOfSymbolicLinkAtPath:[selectedEntry path] error:nil]];
    }

    //Tapped entry is directory
    else
    {
      nextController.currentPath = selectedEntry;
    }

    //Present next directory
    [self.navigationController pushViewController:nextController animated:YES];
  }
}
@end

@implementation filePickerNavigationController
@end
