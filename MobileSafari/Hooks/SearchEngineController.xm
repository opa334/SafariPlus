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

#define seSelf ((SearchEngineController*)self)

%hook SearchEngineController

%property (nonatomic, retain) SearchEngineInfo* customSearchEngine;

- (void)_populateSearchEngines
{
	%orig;

	if(preferenceManager.customSearchEngineEnabled && [preferenceManager.customSearchEngineURL containsString:@"{searchTerms}"])
	{
		if(!seSelf.customSearchEngine)
		{
			NSString* customSearchEngineSuggestionsURL = @"";

			if([preferenceManager.customSearchEngineSuggestionsURL containsString:@"{searchTerms}"])
			{
				customSearchEngineSuggestionsURL = preferenceManager.customSearchEngineSuggestionsURL;
			}

			Class SearchEngineInfoClass = NSClassFromString(@"SearchEngineInfo");
			if(!SearchEngineInfoClass)
			{
				SearchEngineInfoClass = NSClassFromString(@"_SFSearchEngineInfo");
			}

			NSDictionary* searchEngineDictionary = @{
				@"SearchEngineIdentifier" : @"com.opa334.safariplus.custom", //required on iOS 14.5 and up
				@"SearchEngineID" : @1337,
				@"SearchURLTemplate" : preferenceManager.customSearchEngineURL,
				@"SuggestionsURLTemplate" : customSearchEngineSuggestionsURL,
				@"ShortName" : preferenceManager.customSearchEngineName,
				@"ScriptingName" : preferenceManager.customSearchEngineName
			};

			if([SearchEngineInfoClass respondsToSelector:@selector(engineFromDictionary:withController:)])
			{
				//iOS 14.4 and down
				seSelf.customSearchEngine = [SearchEngineInfoClass engineFromDictionary:searchEngineDictionary withController:self];
			}
			else
			{
				//iOS 14.5 and up
				seSelf.customSearchEngine = [[SearchEngineInfoClass alloc] initWithDictionary:searchEngineDictionary usingContext:self];
			}
			
			object_setClass(seSelf.customSearchEngine, [%c(SPSearchEngineInfo) class]);
			[(SPSearchEngineInfo*)seSelf.customSearchEngine setUpSearchURLTemplateString];
		}

		if([seSelf.engines respondsToSelector:@selector(addObject:)])
		{
			[seSelf.engines addObject:seSelf.customSearchEngine];
		}
		else
		{
			[self setValue:[[self valueForKey:@"_searchEngines"] arrayByAddingObject:seSelf.customSearchEngine] forKey:@"_searchEngines"];
		}
	}
}

//iOS 14
- (SearchEngineInfo*)defaultSearchEngineIfPopulated
{
	if(preferenceManager.customSearchEngineEnabled && seSelf.customSearchEngine)
	{
		return seSelf.customSearchEngine;
	}

	return %orig;
}

- (SearchEngineInfo*)defaultSearchEngine
{
	if(preferenceManager.customSearchEngineEnabled && seSelf.customSearchEngine)
	{
		return seSelf.customSearchEngine;
	}

	return %orig;
}

%end

void initSearchEngineController()
{
	Class SearchEngineControllerClass = NSClassFromString(@"SearchEngineController");

	if(!SearchEngineControllerClass)
	{
		SearchEngineControllerClass = NSClassFromString(@"_SFSearchEngineController");
	}

	Class SearchEngineInfoClass = NSClassFromString(@"SearchEngineInfo");

	if(!SearchEngineInfoClass)
	{
		SearchEngineInfoClass = NSClassFromString(@"_SFSearchEngineInfo");
	}

	%init(SearchEngineController=SearchEngineControllerClass, SearchEngineInfo=SearchEngineInfoClass);
}
