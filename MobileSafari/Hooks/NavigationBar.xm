// NavigationBar.xm
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

#import "../SafariPlus.h"
#import "../Defines.h"
#import "../Util.h"

%hook NavigationBar

%property (nonatomic,retain) BrowserToolbar *sp_toolbar;

%group iOS12_2Up
- (BrowserToolbar*)toolbarPlacedOnTop
{
	BrowserToolbar* toolbar = %orig;

	self.sp_toolbar = toolbar;

	return toolbar;
}
%end

%group iOS11_3Up
- (void)_updateNavigationBarTrailingButtonsVisibility
{
	%orig;
	if(activeToolbarForBrowserController(self.delegate)._reloadItem)
	{
		activeToolbarForBrowserController(self.delegate)._reloadItem.enabled = !MSHookIvar<UIButton*>(self, "_reloadButton").hidden;
	}
}
%end

%group iOS9Up
- (void)_updateNavigationBarRightButtonsVisibility
{
	%orig;
	if(activeToolbarForBrowserController(self.delegate)._reloadItem)
	{
		activeToolbarForBrowserController(self.delegate)._reloadItem.enabled = !MSHookIvar<UIButton*>(self, "_reloadButton").hidden;
	}
}
%end

%group iOS8
- (void)_updateStopReloadButtonVisibility
{
	%orig;
	if(activeToolbarForBrowserController(self.delegate)._reloadItem)
	{
		activeToolbarForBrowserController(self.delegate)._reloadItem.enabled = !MSHookIvar<UIButton*>(self, "_reloadButton").hidden;
	}
}
%end

%end

void initNavigationBar()
{
	%init();

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_12_2)
	{
		%init(iOS12_2Up);
	}

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_3)
	{
		%init(iOS11_3Up);
	}
	else if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0)
	{
		%init(iOS9Up);
	}
	else
	{
		%init(iOS8);
	}
}
