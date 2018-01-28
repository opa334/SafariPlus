// SPFileBrowserTableViewController.m
// (c) 2017 opa334

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import "SPFileBrowserTableViewController.h"

#import "../Shared.h"
#import "SPFileBrowserNavigationController.h"
#import "SPFileTableViewCell.h"
#import "SPLocalizationManager.h"

@implementation SPFileBrowserTableViewController

- (id)initWithPath:(NSURL*)path
{
    self = [super init];
    if(self)
    {
      if(path)
      {
        //Set title to directory name
        self.title = path.lastPathComponent;

        //Resolve possible symlinks
        _currentPath = path.URLByResolvingSymlinksInPath;

        //Do some magic to fix up the path
        _currentPath = [NSURL fileURLWithPath:[_currentPath.path
          stringByReplacingOccurrencesOfString:@"/var" withString:@"/private/var"]];
      }
    }
    return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  //Add refreshControl (pull up to refresh)
  self.refreshControl = [[UIRefreshControl alloc] init];
  [self.refreshControl addTarget:self
                  action:@selector(pulledToRefresh)
                forControlEvents:UIControlEventValueChanged];

  //Create variable for _fileManager
  _fileManager = [NSFileManager defaultManager];


  if(!_currentPath)
  {
    //Üath is not set -> set it to root
    _currentPath = ((SPFileBrowserNavigationController*)self.navigationController).rootPath;
  }

  //Set rightBarButtonItem
  self.navigationItem.rightBarButtonItem = [self defaultRightBarButtonItem];

  [self populateDataSources];
}

- (void)pulledToRefresh
{
  //Reload table
  [self reloadDataAndDataSources];

  //Stop refreshing
  [self.refreshControl endRefreshing];
}

- (void)populateDataSources
{
  //Fetch files from current path into array
  _filesAtCurrentPath = (NSMutableArray*)[_fileManager
    contentsOfDirectoryAtURL:_currentPath includingPropertiesForKeys:nil
    options:0 error:nil];

  //Sort files alphabetically
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
    initWithKey:@"lastPathComponent" ascending:YES
    selector:@selector(caseInsensitiveCompare:)];

  _filesAtCurrentPath = (NSMutableArray*)[_filesAtCurrentPath
    sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
}

- (void)reloadDataAndDataSources
{
  dispatch_async(dispatch_get_main_queue(),
  ^{
    //Repopulate dataSources
    [self populateDataSources];

    //Reload tableView with new dataSources
    NSRange range = NSMakeRange(0, [self numberOfSectionsInTableView:self.tableView]);
    NSIndexSet* sections = [NSIndexSet indexSetWithIndexesInRange:range];
    [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationFade];
  });
}

- (UIBarButtonItem*)defaultRightBarButtonItem
{
  //Return dismiss button
  return [[UIBarButtonItem alloc] initWithTitle:[localizationManager
    localizedSPStringForKey:@"DISMISS"] style:UIBarButtonItemStylePlain
    target:self action:@selector(dismiss)];
}

- (void)dismiss
{
  dispatch_async(dispatch_get_main_queue(), ^
  {
    //Dismiss controller
    [self dismissViewControllerAnimated:YES completion:nil];
  });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  //One section (files)
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  //Return amount of files at current path
  return [_filesAtCurrentPath count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  //Return cell for file
  return [self newCellWithFileURL:_filesAtCurrentPath[indexPath.row]];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if(tableView.editing)
  {
    //tableView is in editing mode -> Make directories unselectable
    NSURL* selectedFile = _filesAtCurrentPath[indexPath.row];
    NSNumber* isFile;

    [selectedFile getResourceValue:&isFile forKey:NSURLIsRegularFileKey error:nil];
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
    //tableView is not in editing mode -> Select file / directory

    NSURL* fileURL = _filesAtCurrentPath[indexPath.row];
    NSNumber* isFile;
    [fileURL getResourceValue:&isFile forKey:NSURLIsRegularFileKey error:nil];

    //Tapped entry is file
    if([isFile boolValue])
    {
      [self selectedFileAtURL:fileURL type:1 atIndexPath:indexPath];
    }
    //Tapped entry is directory
    else
    {
      [self selectedFileAtURL:fileURL type:2 atIndexPath:indexPath];
    }
  }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSNumber* isFile;
  NSURL* row = _filesAtCurrentPath[indexPath.row];

  //Get NSNumber for file / directory
  [row getResourceValue:&isFile forKey:NSURLIsRegularFileKey error:nil];

  if([isFile boolValue])
  {
    //file -> can edit
    return YES;
  }
  else
  {
    //directory -> can't edit
    return NO;
  }
}

- (void)selectedFileAtURL:(NSURL*)fileURL type:(NSInteger)type atIndexPath:(NSIndexPath*)indexPath
{
  //Type 1: file; type 2: directory
  if(type == 2)
  {
    [self.navigationController pushViewController:[(SPFileBrowserNavigationController*)self.navigationController newTableViewControllerWithPath:fileURL] animated:YES];
  }
}

- (id)newCellWithFileURL:(NSURL*)fileURL
{
  //Return instance of SPFileTableViewCell
  return [[SPFileTableViewCell alloc] initWithFileURL:fileURL];
}

@end
