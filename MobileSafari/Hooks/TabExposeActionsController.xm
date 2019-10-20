// Copyright (c) 2017-2019 Lars Fröder

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
		//Force reload actions before updating them
		//This is dirty and could be done much better (by hooking _setActions:)
		//but there's not much point as this approach has better backwards compatibility
		
		NSUInteger actions = MSHookIvar<NSUInteger>(self, "_actions");

		if(actions == prevActions)
		{
			MSHookIvar<NSUInteger>(self, "_actions") = 0;
			[self _setActions:actions];
		}

		updateTabExposeActionsForLockedTabs(self.browserController, self.alertController);
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
