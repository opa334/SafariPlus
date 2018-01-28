// preferenceDirectoryPickerNavigationController.h
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

#import "preferenceDirectoryPickerTableViewController.h"
#import "preferenceFileBrowserNavigationController.h"

@protocol PinnedLocationsDelegate
@required
- (void)directoryPickerFinishedWithName:(NSString*)name path:(NSURL*)pathURL;
@end

@interface preferenceDirectoryPickerNavigationController : preferenceFileBrowserNavigationController {}
@property(nonatomic, weak) id<PinnedLocationsDelegate> pinnedLocationsDelegate;
@property(nonatomic) NSString* name;
- (id)initWithDelegate:(id<PinnedLocationsDelegate>)delegate name:(NSString*) name;
@end
