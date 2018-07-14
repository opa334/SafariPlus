// SPPDirectoryPickerNavigationController.m
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

#import "SPPDirectoryPickerNavigationController.h"

@implementation SPPDirectoryPickerNavigationController

- (id)initWithDelegate:(id<PinnedLocationsDelegate>)delegate name:(NSString*)name
{
  self = [super init];
  self.pinnedLocationsDelegate = delegate;
  self.name = name;
  self.loadPreviousPathElements = YES;
  self.startPath = @"/var/mobile/";
  return self;
}

- (id)newTableViewControllerWithPath:(NSString*)path
{
  //return instance of SPPDirectoryPickerTableViewController
  return [[SPPDirectoryPickerTableViewController alloc] initWithPath:path];
}

@end
