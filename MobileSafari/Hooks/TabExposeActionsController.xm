// Copyright (c) 2017-2022 Lars Fröder

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
#import "../Classes/SPLocalizationManager.h"
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

%hook BrowserController

- (BOOL)canPerformAction:(SEL)arg1 withSender:(id)arg2
{
	BOOL orig = %orig;
	if(preferenceManager.lockedTabsEnabled)
	{
		NSString* selString = NSStringFromSelector(arg1);
		if([selString isEqualToString:@"closeActiveTab:"])
		{
			if(self.tabController.activeTabDocument.locked)
			{
				return NO;
			}
		}
		else if([selString isEqualToString:@"closeAllTabs:"])
		{
			BOOL allLocked = YES;
			for(TabDocument* document in self.tabController.currentTabDocuments)
			{
				if(!document.locked)
				{
					allLocked = NO;
					break;
				}
			}
			if(allLocked)
			{
				return NO;
			}
		}
		else if([selString isEqualToString:@"closeAllTabsMatchingSearch:"])
		{
			BOOL allLocked = YES;
			for(TabDocument* document in self.tabController.tabDocumentsMatchingSearchTerm)
			{
				if(!document.locked)
				{
					allLocked = NO;
				}
			}
			if(allLocked)
			{
				return NO;
			}
		}
	}

	return orig;
}

- (void)validateCommand:(UICommand*)command
{
	%orig;

	if(preferenceManager.lockedTabsEnabled)
	{
		NSString* newTitle = nil;
		NSString* selString = NSStringFromSelector(command.action);
		if([selString isEqualToString:@"closeAllTabs:"])
		{
			BOOL anythingLocked = NO;
			NSInteger nonLockedCount = 0;
			for(TabDocument* document in self.tabController.currentTabDocuments)
			{
				if(!document.locked)
				{
					nonLockedCount++;
				}
				else
				{
					anythingLocked = YES;
				}
			}
			
			if(nonLockedCount > 0 && anythingLocked)
			{
				if(nonLockedCount > 1)
				{
					newTitle = [NSString stringWithFormat:[localizationManager localizedSPStringForKey:@"CLOSE_NON_LOCKED_TABS"], nonLockedCount];
				}
				else
				{
					newTitle = [localizationManager localizedSPStringForKey:@"CLOSE_NON_LOCKED_TAB"];
				}
			}
		}
		else if([selString isEqualToString:@"closeAllTabsMatchingSearch:"])
		{
			BOOL anythingLocked = NO;
			NSString* searchTerm = self.tabController.tabThumbnailCollectionView.searchTerm;
			NSInteger nonLockedCount = 0;
			for(TabDocument* document in self.tabController.tabDocumentsMatchingSearchTerm)
			{
				if(!document.locked)
				{
					nonLockedCount++;
				}
				else
				{
					anythingLocked = YES;
				}
			}

			if(nonLockedCount > 0 && anythingLocked)
			{
				if(nonLockedCount > 1)
				{
					newTitle = [NSString stringWithFormat:[localizationManager localizedSPStringForKey:@"CLOSE_NON_LOCKED_TABS_MATCHING"], nonLockedCount, searchTerm];
				}
				else
				{
					newTitle = [NSString stringWithFormat:[localizationManager localizedSPStringForKey:@"CLOSE_NON_LOCKED_TAB_MATCHING"], searchTerm];
				}
			}
		}

		if(newTitle)
		{
			command.title = newTitle;
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
