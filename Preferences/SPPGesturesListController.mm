// SPPGesturesListController.mm
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

#import "SPPGesturesListController.h"
#import "SafariPlusPrefs.h"

@implementation SPPGesturesListController

- (NSString*)plistName
{
	return @"Gestures";
}

- (NSString*)title
{
	return [localizationManager localizedSPStringForKey:@"GESTURES"];
}

- (NSArray *)gestureActionValues
{
	if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_9_0)
	{
		return @[@(GestureActionCloseActiveTab), @(GestureActionOpenNewTab), @(GestureActionDuplicateActiveTab), @(GestureActionCloseAllTabs), @(GestureActionSwitchMode), @(GestureActionSwitchTabBackwards), @(GestureActionSwitchTabForwards), @(GestureActionReloadActiveTab), @(GestureActionRequestDesktopSite)];
	}
	else
	{
		return @[@(GestureActionCloseActiveTab), @(GestureActionOpenNewTab), @(GestureActionDuplicateActiveTab), @(GestureActionCloseAllTabs), @(GestureActionSwitchMode), @(GestureActionSwitchTabBackwards), @(GestureActionSwitchTabForwards), @(GestureActionReloadActiveTab), @(GestureActionRequestDesktopSite), @(GestureActionOpenFindOnPage)];
	}
}

- (NSArray *)gestureActionTitles
{
	NSMutableArray* titles;

	if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_9_0)
	{
		titles = [@[@"CLOSE_ACTIVE_TAB", @"OPEN_NEW_TAB", @"DUPLICATE_ACTIVE_TAB", @"CLOSE_ALL_TABS", @"SWITCH_MODE", @"TAB_BACKWARD", @"TAB_FORWARD", @"RELOAD_ACTIVE_TAB", @"REQUEST_DESTKOP_SITE"] mutableCopy];
	}
	else
	{
		titles = [@[@"CLOSE_ACTIVE_TAB", @"OPEN_NEW_TAB", @"DUPLICATE_ACTIVE_TAB", @"CLOSE_ALL_TABS", @"SWITCH_MODE", @"TAB_BACKWARD", @"TAB_FORWARD", @"RELOAD_ACTIVE_TAB", @"REQUEST_DESTKOP_SITE", @"OPEN_FIND_ON_PAGE"] mutableCopy];
	}

	for(int i = 0; i < titles.count; i++)
	{
		titles[i] = [localizationManager localizedSPStringForKey:titles[i]];
	}
	return titles;
}

@end
