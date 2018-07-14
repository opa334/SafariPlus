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
#import "SPFileManager.h"

@implementation SPFileBrowserTableViewController

- (id)initWithPath:(NSString*)path
{
    self = [super init];
    if(self)
    {
      if(path)
      {
        //Set title to directory name
        self.title = path.lastPathComponent;

        //Resolve possible symlinks
        _currentPath = [fileManager resolveSymlinkForPath:path];
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

  if(!_currentPath)
  {
    //Path is not set -> set it to root
    _currentPath = @"/";
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
  _filesAtCurrentPath = [fileManager
    contentsOfDirectoryAtURL:[NSURL fileURLWithPath:_currentPath] includingPropertiesForKeys:nil
    options:0 error:nil];

  //Sort files alphabetically
  NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
    initWithKey:@"lastPathComponent" ascending:YES
    selector:@selector(caseInsensitiveCompare:)];

  _filesAtCurrentPath = [_filesAtCurrentPath
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
  return [self newCellWithFilePath:_filesAtCurrentPath[indexPath.row].path];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if(tableView.editing)
  {
    //tableView is in editing mode -> Make directories unselectable
    NSURL* selectedFile = _filesAtCurrentPath[indexPath.row];

    NSDictionary* attributes = [fileManager attributesOfItemAtPath:selectedFile.path error:nil];

    if(![[attributes fileType] isEqualToString:NSFileTypeRegular])
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

    NSString* filePath = _filesAtCurrentPath[indexPath.row].path;
    NSDictionary* fileAttributes = [fileManager attributesOfItemAtPath:filePath error:nil];
    NSString* fileType = [fileAttributes objectForKey:NSFileType];

    //Tapped entry is file
    if([fileType isEqualToString:NSFileTypeRegular])
    {
      [self selectedFileAtPath:filePath type:1 atIndexPath:indexPath];
    }
    //Tapped entry is something else
    else
    {
      [self selectedFileAtPath:filePath type:2 atIndexPath:indexPath];
    }
  }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSURL* row = _filesAtCurrentPath[indexPath.row];

  //Get NSNumber for file / directory
  NSDictionary* attributes = [fileManager attributesOfItemAtPath:row.path error:nil];

  if([[attributes fileType] isEqualToString:NSFileTypeRegular])
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

- (void)selectedFileAtPath:(NSString*)filePath type:(NSInteger)type atIndexPath:(NSIndexPath*)indexPath
{
  //Type 1: file; type 2: directory
  if(type == 2)
  {
    [self.navigationController pushViewController:[(SPFileBrowserNavigationController*)self.navigationController newTableViewControllerWithPath:filePath] animated:YES];
  }
}

- (id)newCellWithFilePath:(NSString*)filePath
{
  //Return instance of SPFileTableViewCell
  return [[SPFileTableViewCell alloc] initWithFilePath:filePath];
}

@end
