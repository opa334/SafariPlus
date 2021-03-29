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

#import "SPLocalizationManager.h"

#import <Preferences/PSSpecifier.h>
#import "../Util.h"

@implementation SPLocalizationManager

+ (instancetype)sharedInstance
{
	static SPLocalizationManager *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^
	{
		sharedInstance = [[SPLocalizationManager alloc] init];
	});
	return sharedInstance;
}

//Retrieves a localized string from SafariPlus
- (NSString*)localizedSPStringForKey:(NSString*)key;
{
	NSString* localizedString = [SPBundle localizedStringForKey:key value:nil table:nil];
	if([localizedString isEqualToString:key])
	{
		//Handle missing localization
		NSDictionary *englishDict = [[NSDictionary alloc]
					     initWithContentsOfFile:[SPBundle pathForResource:@"Localizable"
								     ofType:@"strings" inDirectory:@"en.lproj"]];

		localizedString = [englishDict objectForKey:key];

		if(!localizedString)
		{
			return key;
		}
	}
	return localizedString;
}

//Retrieves a localized string from MobileSafari
- (NSString*)localizedMSStringForKey:(NSString*)key
{
	NSString* localizedString = [MSBundle localizedStringForKey:key value:key table:nil];
	return localizedString;
}

- (NSString*)localizedWBSStringForKey:(NSString*)key
{
	if(!self.WBSBundle)
	{
		//Probably wrong path on iOS 10 and below but the method is only used on 13 anyways
		self.WBSBundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/SafariCore.framework"];
	}

	return [self.WBSBundle localizedStringForKey:key value:@"localized string not found" table:nil];
}

- (void)parseSPLocalizationsForSpecifiers:(NSArray*)specifiers
{
	//Localize specifiers
	NSMutableArray* mutableSpecifiers = (NSMutableArray*)specifiers;
	for(PSSpecifier* specifier in mutableSpecifiers)
	{
		NSString *localizedTitle = [self localizedSPStringForKey:specifier.properties[@"label"]];
		NSString *localizedFooter = [self localizedSPStringForKey:specifier.properties[@"footerText"]];
		specifier.name = localizedTitle;
		[specifier setProperty:localizedFooter forKey:@"footerText"];
	}
}

@end
