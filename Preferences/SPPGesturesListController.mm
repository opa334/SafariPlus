// Copyright (c) 2017-2021 Lars Fröder

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
