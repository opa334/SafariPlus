// TabExposeActionsController.xm
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
#import "../Util.h"
#import "../Classes/SPPreferenceManager.h"
#import "../Defines.h"

%hook TabExposeActionsController

- (void)updateActions
{
	NSUInteger prevActions;
	if(preferenceManager.lockedTabsEnabled)
	{
		prevActions = MSHookIvar<NSUInteger>(self, "_actions");
	}

	%orig;

	if(preferenceManager.lockedTabsEnabled)
	{
		BOOL changed = updateTabExposeActionsForLockedTabs(self.browserController, self.alertController);
		if(!changed)
		{
			//Force a reload
			NSUInteger actions = MSHookIvar<NSUInteger>(self, "_actions");

			if(actions == prevActions)
			{
				MSHookIvar<NSUInteger>(self, "_actions") = 0;
				[self _setActions:actions];
			}
		}
	}
}

%end

void initTabExposeActionsController()
{
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_12_2)
	{
		%init();
	}
}
