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

#import "SPPListController.h"
#import "SafariPlusPrefs.h"

#import "Simulator.h"

@implementation SPPListController

- (NSString*)title
{
	if(NSString* label = [[self specifier] propertyForKey:@"label"])
	{
		return [localizationManager localizedSPStringForKey:label];
	}
	
	return @"";
}

- (NSString*)plistName
{
	if(NSString* plistName = [[self specifier] propertyForKey:@"plistName"])
	{
		return plistName;
	}
	
	return @"";
}

- (NSMutableArray*)specifiers
{
	if(!_specifiers)
	{
		NSString* plistName = [self plistName];

		if(plistName)
		{
			_specifiers = [self loadSpecifiersFromPlistName:[self plistName] target:self];
			
			[self applyModificationsToSpecifiers:_specifiers];
		}
	}

	[(UINavigationItem *)self.navigationItem setTitle:[self title]];
	return _specifiers;
}

- (void)applyModificationsToSpecifiers:(NSMutableArray*)specifiers
{
	[localizationManager parseSPLocalizationsForSpecifiers:specifiers];

	[self removeUnsupportedSpecifiers:specifiers];
	_allSpecifiers = [specifiers copy];
	[self removeDisabledGroups:specifiers];
}

- (void)removeUnsupportedSpecifiers:(NSMutableArray*)specifiers
{
	for(PSSpecifier* specifier in [specifiers reverseObjectEnumerator])
	{
		NSNumber* minCFVersionNumber = [[specifier properties] objectForKey:@"minCFVersion"];
		NSNumber* maxCFVersionNumber = [[specifier properties] objectForKey:@"maxCFVersion"];

		if(minCFVersionNumber)
		{
			if(kCFCoreFoundationVersionNumber < [minCFVersionNumber floatValue])
			{
				[specifiers removeObject:specifier];
				continue;
			}
		}

		if(maxCFVersionNumber)
		{
			if(kCFCoreFoundationVersionNumber > [maxCFVersionNumber floatValue])
			{
				[specifiers removeObject:specifier];
				continue;
			}
		}
	}
}

- (void)removeDisabledGroups:(NSMutableArray*)specifiers;
{
	for(PSSpecifier* specifier in [specifiers reverseObjectEnumerator])
	{
		NSNumber* nestedEntryCount = [[specifier properties] objectForKey:@"nestedEntryCount"];
		if(nestedEntryCount)
		{
			BOOL enabled = [[self readPreferenceValue:specifier] boolValue];

			if(!enabled)
			{
				NSMutableArray* nestedEntries = [[_allSpecifiers subarrayWithRange:NSMakeRange([_allSpecifiers indexOfObject:specifier]+1, [nestedEntryCount intValue])] mutableCopy];

				BOOL containsNestedEntries = NO;

				for(PSSpecifier* nestedEntry in nestedEntries)
				{
					NSNumber* nestedNestedEntryCount = [[nestedEntry properties] objectForKey:@"nestedEntryCount"];
					if(nestedNestedEntryCount)
					{
						containsNestedEntries = YES;
						break;
					}
				}

				if(containsNestedEntries)
				{
					[self removeDisabledGroups:nestedEntries];
				}

				[specifiers removeObjectsInArray:nestedEntries];
			}
		}
	}
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier
{
	#ifdef NO_CEPHEI
	NSString* plistPath = rPath(prefPlistPath);
	NSMutableDictionary* mutableDict = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
	if(!mutableDict)
	{
		mutableDict = [NSMutableDictionary new];
	}
	[mutableDict setObject:value forKey:[[specifier properties] objectForKey:@"key"]];
	[mutableDict writeToFile:plistPath atomically:YES];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.opa334.safariplusprefs/ReloadPrefs"), NULL, NULL, YES);
	#else
	[super setPreferenceValue:value specifier:specifier];
	#endif

	if(specifier.cellType == PSSwitchCell)
	{
		NSNumber* numValue = (NSNumber*)value;
		NSNumber* nestedEntryCount = [[specifier properties] objectForKey:@"nestedEntryCount"];
		if(nestedEntryCount)
		{
			NSInteger index = [_allSpecifiers indexOfObject:specifier];
			NSMutableArray* nestedEntries = [[_allSpecifiers subarrayWithRange:NSMakeRange(index + 1, [nestedEntryCount intValue])] mutableCopy];
			[self removeDisabledGroups:nestedEntries];

			if([numValue boolValue])
			{
				[self insertContiguousSpecifiers:nestedEntries afterSpecifier:specifier animated:YES];
			}
			else
			{
				[self removeContiguousSpecifiers:nestedEntries animated:YES];
			}
		}
	}
}

#ifdef NO_CEPHEI

- (id)readPreferenceValue:(PSSpecifier*)specifier
{
	NSString* plistPath = rPath(prefPlistPath);
	NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:plistPath];

	id obj = [dict objectForKey:[[specifier properties] objectForKey:@"key"]];

	if(!obj)
	{
		obj = [[specifier properties] objectForKey:@"default"];
	}

	return obj;
}

#endif

- (void)openTwitterWithUsername:(NSString*)username
{
	if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]])
	{
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"twitter://user?screen_name=%@", username]]];
	}
	else
	{
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://twitter.com/%@", username]]];
	}
}

- (void)closeKeyboard
{
	[self.view endEditing:YES];
}

@end
