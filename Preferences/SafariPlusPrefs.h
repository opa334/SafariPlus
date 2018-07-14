// SafariPlusPrefs.h
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

#import <Preferences/PSListController.h>
#import <Preferences/PSTableCell.h>
#import <Preferences/PSSpecifier.h>
#import "Protocols.h"

@interface PSEditableListController : PSListController {}
- (id)_editButtonBarItem;
- (BOOL)performDeletionActionForSpecifier:(id)arg1;
@end

//Parses nestedEntryCount property for more dynamic preferences (also localizes specifiers)
@interface SPListController : PSListController
{
  NSArray* _allSpecifiers;
}

- (NSString*)plistName;
- (NSString*)title;
- (void)removeDisabledGroups:(NSMutableArray*)specifiers;
@end

@interface SafariPlusRootListController : SPListController<UITableViewDelegate>
@property(nonatomic) UIImageView* headerView;
@end

@interface GeneralPrefsController : SPListController {}
@end

@interface DownloadPrefsController : SPListController {}
@end

@interface ExceptionsController : PSEditableListController
{
  NSMutableDictionary *plist;
  NSMutableArray *ForceHTTPSExceptions;
}
@end

@interface PinnedLocationsController : PSEditableListController<PinnedLocationsDelegate>
{
  NSMutableDictionary *plist;
  NSMutableArray *PinnedLocationNames;
  NSMutableArray *PinnedLocationPaths;
}
- (void)openDirectoryPickerWithName:(NSString*)name;
@end

@interface ActionPrefsController : SPListController {}
@end

@interface GesturePrefsController : SPListController {}
@end

@interface OtherPrefsController : SPListController {}
@end

@interface ColorOverviewPrefsController : SPListController {}
@end

@interface TopBarNormalColorPrefsController : SPListController {}
@end

@interface BottomBarNormalColorPrefsController : SPListController {}
@end

@interface TabSwitcherNormalColorPrefsController : SPListController {}
@end

@interface TopBarPrivateColorPrefsController : SPListController {}
@end

@interface BottomBarPrivateColorPrefsController : SPListController {}
@end

@interface TabSwitcherPrivateColorPrefsController : SPListController {}
@end

@interface CreditsController : SPListController {}
@end

@protocol PreferencesTableCustomView
- (id)initWithSpecifier:(id)specifier;
@optional
- (CGFloat)preferredHeightForWidth:(CGFloat)width;
- (CGFloat)preferredHeightForWidth:(CGFloat)width inTableView:(id)tableView;
@end

@interface SafariPlusHeaderCell : PSTableCell <PreferencesTableCustomView> {
  UIImage *headerImage;
  UIImageView *headerImageView;
}
@end
