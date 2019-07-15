// SearchEngineController.xm
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
#import "../Classes/SPPreferenceManager.h"

@interface SPSearchEngineInfo : SearchEngineInfo
@end

%subclass SPSearchEngineInfo : SearchEngineInfo

- (NSString*)displayName
{
	return self.shortName;
}

%end

%hook SearchEngineController

%property (nonatomic, retain) SearchEngineInfo* customSearchEngine;

- (void)_populateSearchEngines
{
	%orig;

	if(preferenceManager.customSearchEngineEnabled)
	{
		if(!self.customSearchEngine)
		{
			self.customSearchEngine = [%c(SearchEngineInfo) engineFromDictionary:@{@"SearchEngineID" : @1337, @"SearchURLTemplate" : preferenceManager.customSearchEngineURL, @"SuggestionsURLTemplate" : preferenceManager.customSearchEngineSuggestionsURL, @"ShortName" : preferenceManager.customSearchEngineName, @"ScriptingName" : preferenceManager.customSearchEngineName} withController:self];
			object_setClass(self.customSearchEngine, [%c(SPSearchEngineInfo) class]);
		}

		if([self.engines respondsToSelector:@selector(addObject:)])
		{
			[self.engines addObject:self.customSearchEngine];
		}
		else
		{
			MSHookIvar<NSArray*>(self, "_searchEngines") = [MSHookIvar<NSArray*>(self, "_searchEngines") arrayByAddingObject:self.customSearchEngine];
		}
	}
}

- (SearchEngineInfo*)defaultSearchEngine
{
	if(preferenceManager.customSearchEngineEnabled && self.customSearchEngine)
	{
		return self.customSearchEngine;
	}

	return %orig;
}

%end

void initSearchEngineController()
{
	%init();
}
