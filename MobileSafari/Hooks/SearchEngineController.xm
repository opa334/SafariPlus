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
@property (nonatomic,retain) NSString *beforeSearchTermString;
@property (nonatomic,retain) NSString *afterSearchTermString;
- (void)setUpSearchURLTemplateString;
- (NSString*)sp_userVisibleQueryFromSearchURL:(NSString*)searchURL;
@end

static NSString* stringWithSchemeStripped(NSString* oldString)
{
	NSString* strippedString = oldString;

	NSRange dividerRange = [strippedString rangeOfString:@"://"];
	if(dividerRange.location != NSNotFound)
	{
		NSUInteger divide = NSMaxRange(dividerRange);
		strippedString = [strippedString substringFromIndex:divide];
	}

	if([strippedString hasPrefix:@"www."])
	{
		strippedString = [strippedString substringFromIndex:4];
	}

	return strippedString;
}

#define spseiSelf ((SPSearchEngineInfo*)self)

%subclass SPSearchEngineInfo : SearchEngineInfo

%property (nonatomic,retain) NSString *beforeSearchTermString;
%property (nonatomic,retain) NSString *afterSearchTermString;

%new
- (void)setUpSearchURLTemplateString
{
	NSString* searchEngineURL = stringWithSchemeStripped(preferenceManager.customSearchEngineURL);

	NSRange searchTermRange = [searchEngineURL rangeOfString:@"{searchTerms}"];
	if(searchTermRange.location != NSNotFound)
	{
		NSRange beforeSearchTermRange, afterSearchTermRange;

		beforeSearchTermRange = NSMakeRange(0, searchTermRange.location);
		self.beforeSearchTermString = [searchEngineURL substringWithRange:beforeSearchTermRange];

		afterSearchTermRange = NSMakeRange(NSMaxRange(searchTermRange), searchEngineURL.length - NSMaxRange(searchTermRange));
		self.afterSearchTermString = [searchEngineURL substringWithRange:afterSearchTermRange];
	}
}

- (NSString*)displayName
{
	return self.shortName;
}

%new
- (NSString*)sp_userVisibleQueryFromSearchURL:(NSString*)searchURL
{
	NSString* strippedSearchURL = stringWithSchemeStripped(searchURL);

	if(self.beforeSearchTermString && self.afterSearchTermString)
	{
		if(([strippedSearchURL hasPrefix:self.beforeSearchTermString] || [self.beforeSearchTermString isEqualToString:@""]) && ([strippedSearchURL hasSuffix:self.afterSearchTermString] || [self.afterSearchTermString isEqualToString:@""]))
		{
			return [[[strippedSearchURL substringWithRange:NSMakeRange(self.beforeSearchTermString.length, strippedSearchURL.length - self.beforeSearchTermString.length - self.afterSearchTermString.length)] stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByRemovingPercentEncoding];
		}
	}

	return nil;
}

//iOS >= 9
- (NSString*)userVisibleQueryFromSearchURL:(NSURL*)searchURL
{
	return [self sp_userVisibleQueryFromSearchURL:searchURL.absoluteString];
}

//iOS 8
- (NSString*)queryForSearchURL:(NSString*)searchURL
{
	return [self sp_userVisibleQueryFromSearchURL:searchURL];
}

%end

%hook SearchEngineController

%property (nonatomic, retain) SearchEngineInfo* customSearchEngine;

- (void)_populateSearchEngines
{
	%orig;

	if(preferenceManager.customSearchEngineEnabled && [preferenceManager.customSearchEngineURL containsString:@"{searchTerms}"])
	{
		if(!self.customSearchEngine)
		{
			NSString* customSearchEngineSuggestionsURL = @"";

			if([preferenceManager.customSearchEngineSuggestionsURL containsString:@"{searchTerms}"])
			{
				customSearchEngineSuggestionsURL = preferenceManager.customSearchEngineSuggestionsURL;
			}

			self.customSearchEngine = [%c(SearchEngineInfo) engineFromDictionary:@{@"SearchEngineID" : @1337, @"SearchURLTemplate" : preferenceManager.customSearchEngineURL, @"SuggestionsURLTemplate" : customSearchEngineSuggestionsURL, @"ShortName" : preferenceManager.customSearchEngineName, @"ScriptingName" : preferenceManager.customSearchEngineName} withController:self];
			object_setClass(self.customSearchEngine, [%c(SPSearchEngineInfo) class]);
			[(SPSearchEngineInfo*)self.customSearchEngine setUpSearchURLTemplateString];
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
