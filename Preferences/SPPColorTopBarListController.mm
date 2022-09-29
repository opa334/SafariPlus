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

#import "SPPColorTopBarListController.h"
#import "SafariPlusPrefs.h"
#import "../MobileSafari/Defines.h"
#import "../Shared/ColorPickerCompat.h"

@implementation SPPColorTopBarListController

- (NSString*)plistName
{
	if(useAlderis())
	{
		return @"Alderis_ColorsTopBar";
	}
	else
	{
		return @"CSColorPicker_ColorsTopBar";
	}
	
}

- (NSString*)title
{
	NSString* modeIdentifier = [[self specifier] propertyForKey:@"modeIdentifier"];
	return [NSString stringWithFormat:@"%@ (%@)", [localizationManager localizedSPStringForKey:@"TOP_BAR"], [localizationManager localizedSPStringForKey:[modeIdentifier uppercaseString]]];
}

- (NSArray*)statusBarColorTitles
{
	NSMutableArray* titles = [@[@"BLACK", @"WHITE"] mutableCopy];

	for(int i = 0; i < titles.count; i++)
	{
		titles[i] = [localizationManager localizedSPStringForKey:titles[i]];
	}

	return titles;
}

- (NSArray*)statusBarColorValues
{
	return @[@(UIStatusBarStyleDefault), @(UIStatusBarStyleLightContent)];
}

- (void)applyModificationsToSpecifiers:(NSMutableArray*)specifiers
{
	NSString* modeIdentifier = [[self specifier] propertyForKey:@"modeIdentifier"];
	BOOL isNormal;

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0)
	{
		isNormal = [modeIdentifier hasSuffix:@"Light"];
	}
	else
	{
		isNormal = [modeIdentifier isEqualToString:@"Normal"];
	}

	for(PSSpecifier* specifier in specifiers)
	{
		NSString* key = [specifier propertyForKey:@"key"];
		if([key hasSuffix:@"TabBarInactiveTitleOpacity"])
		{
			NSNumber* defaultValue;

			if(isNormal)
			{
				defaultValue = @0.4;
			}
			else
			{
				defaultValue = @0.2;
			}

			[specifier setProperty:defaultValue forKey:@"default"];
		}
	}

	[super applyModificationsToSpecifiers:specifiers];
}

@end
