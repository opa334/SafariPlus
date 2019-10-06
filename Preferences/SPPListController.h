// SPPListController.h
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

#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

//Additional features:
//Localizes specifiers
//nestedEntryCount for more dynamic preferences

@interface SPPListController : PSListController
{
	NSArray* _allSpecifiers;
}

- (NSString*)plistName;
- (NSString*)title;
- (void)removeDisabledGroups:(NSMutableArray*)specifiers;
- (void)closeKeyboard;
@end
