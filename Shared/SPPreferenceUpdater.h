// SPPreferenceUpdater.h
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

#ifndef SIMJECT

@interface SPPreferenceUpdater : NSObject
+ (void)update;
+ (BOOL)needsMerge;
+ (NSString*)LCSCPHexFromLCPHex:(NSString*)lcpHex;	//libColorPicker -> libCSColorPicker
+ (NSDictionary*)locationWithName:(NSString*)name path:(NSString*)path;
@end

#endif
