// SafariPlusPrefs.h
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

#import "../MobileSafari/Classes/SPLocalizationManager.h"
#import "SPPDirectoryPickerNavigationController.h"
#import "../MobileSafari/Enums.h"
#import "../MobileSafari/Defines.h"
#import "../MobileSafari/Classes/SPFileManager.h"
#import <Preferences/PSListController.h>

extern SPFileManager* fileManager;
extern SPLocalizationManager* localizationManager;
extern NSBundle* SPBundle;
extern NSBundle* MSBundle;
extern NSBundle* SSBundle;

#ifdef SIMJECT
extern NSString* simulatorPath(NSString* path);
#define rPath(args ...) ({ simulatorPath(args); })
#else
#define rPath(args ...) ({ args; })
#endif

@interface PSEditableListController : PSListController
- (id)_editButtonBarItem;
- (BOOL)performDeletionActionForSpecifier:(id)arg1;
- (void)setEditable:(BOOL)editable;
- (BOOL)editable;
@end
