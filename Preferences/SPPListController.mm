// SPPListController.mm
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

#import "SPPListController.h"
#import "SafariPlusPrefs.h"

@implementation SPPListController

//Must be overwritten by subclass
- (NSString*)title
{
	return nil;
}

//Must be overwritten by subclass
- (NSString*)plistName
{
	return nil;
}

- (NSMutableArray*)specifiers
{
	if(!_specifiers)
	{
		NSString* plistName = [self plistName];

		if(plistName)
		{
			_specifiers = [self loadSpecifiersFromPlistName:[self plistName] target:self];
			[localizationManager parseSPLocalizationsForSpecifiers:_specifiers];

			_allSpecifiers = [_specifiers copy];
			[self removeDisabledGroups:_specifiers];
		}
	}

	[(UINavigationItem *)self.navigationItem setTitle:[self title]];
	return _specifiers;
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
	[super setPreferenceValue:value specifier:specifier];

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

- (void)closeKeyboard
{
	[self.view endEditing:YES];
}

@end
