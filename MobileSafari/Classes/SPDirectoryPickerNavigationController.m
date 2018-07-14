// SPDirectoryPickerNavigationController.m
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

#import "SPDirectoryPickerNavigationController.h"

#import "../Defines.h"
#import "../Shared.h"
#import "SPDirectoryPickerTableViewController.h"
#import "SPDownloadManager.h"
#import "SPPreferenceManager.h"
#import "SPFileManager.h"

@implementation SPDirectoryPickerNavigationController

- (id)initWithDownloadInfo:(SPDownloadInfo*)downloadInfo
{
  self = [super init];

  self.downloadInfo = downloadInfo;

  if(preferenceManager.customDefaultPathEnabled)
  {
    //customDefaultPath enabled -> return custom path if it is valid
    NSString* path = [NSString stringWithFormat:@"/var%@", preferenceManager.customDefaultPath];
    BOOL isDir;
    BOOL exists = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    if(isDir && exists)
    {
      self.startPath = path;
    }
    else
    {
      self.startPath = defaultDownloadPath;
    }
  }
  else
  {
    self.startPath = defaultDownloadPath;
  }

  self.loadPreviousPathElements = YES;

  return self;
}

- (id)newTableViewControllerWithPath:(NSString*)path
{
  //return instance of directoryPickerTableViewController
  return [[SPDirectoryPickerTableViewController alloc] initWithPath:path];
}

@end
