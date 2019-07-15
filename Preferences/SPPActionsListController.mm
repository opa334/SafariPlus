// SPPActionsListController.mm
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

#import "SPPActionsListController.h"
#import "SafariPlusPrefs.h"

@implementation SPPActionsListController

- (NSString*)plistName
{
	return @"Actions";
}

- (NSString*)title
{
	return [localizationManager localizedSPStringForKey:@"ACTIONS"];
}

- (NSArray *)modeValues
{
	return @[@(ModeSwitchActionNormalMode), @(ModeSwitchActionPrivateMode)];
}

- (NSArray *)modeTitles
{
	NSMutableArray* titles = [@[@"NORMAL_MODE", @"PRIVATE_MODE"] mutableCopy];
	for(int i = 0; i < titles.count; i++)
	{
		titles[i] = [localizationManager localizedSPStringForKey:titles[i]];
	}
	return titles;
}

- (NSArray *)stateValues
{
	return @[@(CloseTabActionOnSafariClosed), @(CloseTabActionOnSafariMinimized)];
}

- (NSArray *)stateTitles
{
	NSMutableArray* titles = [@[@"SAFARI_CLOSED", @"SAFARI_MINIMIZED"] mutableCopy];
	for(int i = 0; i < titles.count; i++)
	{
		titles[i] = [localizationManager localizedSPStringForKey:titles[i]];
	}
	return titles;
}

- (NSArray *)closeModeValues
{
	return @[@(CloseTabActionFromActiveMode), @(CloseTabActionFromNormalMode), @(CloseTabActionFromPrivateMode), @(CloseTabActionFromBothModes)];
}

- (NSArray *)closeModeTitles
{
	NSMutableArray* titles = [@[@"ACTIVE_MODE", @"NORMAL_MODE", @"PRIVATE_MODE", @"BOTH_MODES"] mutableCopy];
	for(int i = 0; i < titles.count; i++)
	{
		titles[i] = [localizationManager localizedSPStringForKey:titles[i]];
	}
	return titles;
}

@end
