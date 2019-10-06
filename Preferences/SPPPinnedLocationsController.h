// SPPPinnedLocationsController.h
// (c) 2017 - 2019 opa334

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

#import "SPPListController.h"
#import "SafariPlusPrefs.h"

@interface SPPPinnedLocationsController : PSEditableListController<PinnedLocationsDelegate>
{
	PSSpecifier* _pinnedLocationsSpecifier;
	NSMutableArray<NSDictionary*>* _pinnedLocations;
	NSString* _modifiedSpecifierName;
	NSIndexPath* _modifiedSpecifierIndexPath;
}
- (void)presentLocationAlertForLocation:(NSDictionary*)location forSpecifierAtIndexPath:(NSIndexPath*)indexPath;
- (void)openDirectoryPickerWithPath:(NSString*)path;
- (NSDictionary*)locationWithName:(NSString*)name path:(NSString*)path;
@end
