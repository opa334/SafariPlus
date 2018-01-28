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

#ifdef ELECTRA
#define bundlePath @"/bootstrap/Library/PreferenceBundles/SafariPlusPrefs.bundle"
#else
#define bundlePath @"/Library/PreferenceBundles/SafariPlusPrefs.bundle"
#endif
#define otherPlistPath @"/var/mobile/Library/Preferences/com.opa334.safariplusprefsOther.plist"
#import <Preferences/PSListController.h>
#import <Preferences/PSTableCell.h>
#import <Preferences/PSSpecifier.h>
#import "SPPreferenceLocalizationManager.h"
#import "preferenceDirectoryPickerNavigationController.h"
#import "../MobileSafari/Enums.h"

@interface PSEditableListController : PSListController {}
- (id)_editButtonBarItem;
- (BOOL)performDeletionActionForSpecifier:(id)arg1;
@end

@interface SafariPlusRootListController : PSListController<UITableViewDelegate>
@property(nonatomic) UIImageView* headerView;
@end

@interface GeneralPrefsController : PSListController {}
@end

@interface DownloadPrefsController : PSListController {}
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

@interface ActionPrefsController : PSListController {}
@end

@interface GesturePrefsController : PSListController {}
@end

@interface OtherPrefsController : PSListController {}
@end

@interface ColorPrefsController : PSListController {}
@end

@interface NormalColorPrefsController : PSListController {}
@end

@interface PrivateColorPrefsController : PSListController {}
@end

@interface CreditsController : PSListController {}
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
