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

#import "../MobileSafari/Defines.h"
#import "SPPreferenceUpdater.h"
#import "../MobileSafari/Util.h"
#import "../MobileSafari/Classes/SPFileManager.h"
#import "Simulator.h"

#ifndef SIMJECT

#ifndef PREFERENCES
#import <Cephei/HBPreferences.h>
#import "../MobileSafari/Classes/SPPreferenceManager.h"
#endif

@implementation SPPreferenceUpdater

+ (BOOL)needsMerge
{
	BOOL colorsExists = [fileManager fileExistsAtPath:rPath(COLOR_PLIST_PATH_DEPRECATED)];
	BOOL otherExists = [fileManager fileExistsAtPath:rPath(OTHER_PLIST_PATH_DEPRECATED)];

	return colorsExists || otherExists;
}

+ (void)update
{
	BOOL mergeNeeded = [self needsMerge];

#ifndef PREFERENCES
	NSUserDefaults* preferences = [preferenceManager userDefaults];
#else
	NSUserDefaults* preferences = [[NSUserDefaults alloc] initWithSuiteName:PREFERENCE_DOMAIN_NAME];
#endif

	if(mergeNeeded)
	{
		NSDictionary* colorDict = [NSDictionary dictionaryWithContentsOfFile:rPath(COLOR_PLIST_PATH_DEPRECATED)];
		if(colorDict)
		{
			for(NSString* key in [colorDict allKeys])
			{
				NSString* lcpHex = [colorDict objectForKey:key];
				NSString* lcscpHex = [self LCSCPHexFromLCPHex:lcpHex];

				[preferences setObject:lcscpHex forKey:key];
			}

			[fileManager removeItemAtPath:rPath(COLOR_PLIST_PATH_DEPRECATED) error:nil];
		}

		NSDictionary* otherDict = [NSDictionary dictionaryWithContentsOfFile:rPath(OTHER_PLIST_PATH_DEPRECATED)];
		if(otherDict)
		{
			NSArray* forceHTTPSExceptions = [otherDict objectForKey:@"ForceHTTPSExceptions"];

			NSArray* pinnedLocationNames = [otherDict objectForKey:@"PinnedLocationNames"];
			NSArray* pinnedLocationPaths = [otherDict objectForKey:@"PinnedLocationPaths"];

			if(forceHTTPSExceptions)
			{
				[preferences setObject:forceHTTPSExceptions forKey:@"forceHTTPSExceptions"];
			}

			if(pinnedLocationNames && pinnedLocationPaths)
			{
				if(pinnedLocationNames.count == pinnedLocationPaths.count)
				{
					NSMutableArray* pinnedLocationsM = [NSMutableArray new];

					for(NSInteger i = 0; i < pinnedLocationNames.count; i++)
					{
						NSString* name = pinnedLocationNames[i];
						NSString* path = pinnedLocationPaths[i];

						NSDictionary* location = [self locationWithName:name path:path];
						[pinnedLocationsM addObject:location];
					}

					[preferences setObject:[pinnedLocationsM copy] forKey:@"pinnedLocations"];
				}

				[fileManager removeItemAtPath:rPath(OTHER_PLIST_PATH_DEPRECATED) error:nil];
			}
		}
	}

	NSDictionary* deprecatedToNewKeys = @{
		@"disablePushNotificationsEnabled" : @"pushNotificationsEnabled",
		@"disableBarNotificationsEnabled" : @"statusBarNotificationsEnabled",
		@"progressUnderDownloadsButtonEnabled" : @"previewDownloadProgressEnabled",
		@"gestureBackground" : @"gestureActionsInBackgroundEnabled",
		@"enhancedDownloadsEnabled" : @"downloadManagerEnabled"
	};

	NSArray* currentKeys = [[preferences dictionaryRepresentation] allKeys];

	for(NSString* deprecatedKey in [deprecatedToNewKeys allKeys])
	{
		if([currentKeys containsObject:deprecatedKey])
		{
			NSString* newKey = [deprecatedToNewKeys objectForKey:deprecatedKey];

			//If new key already exists, don't touch it
			if(![currentKeys containsObject:newKey])
			{
				NSObject* obj = [preferences objectForKey:deprecatedKey];

				if([deprecatedKey hasPrefix:@"disable"] != [newKey hasPrefix:@"disable"])
				{
					//old value needs invert
					obj = [NSNumber numberWithBool:![(NSNumber*) obj boolValue]];
				}

				[preferences setObject:obj forKey:newKey];
			}
#ifdef PREFERENCES
			//This crashes with HBPreferences, no idea why
			[preferences removeObjectForKey:deprecatedKey];
#endif
		}
	}

	[preferences synchronize];
}

+ (NSString*)LCSCPHexFromLCPHex:(NSString*)lcpHex
{
	NSArray* components = [lcpHex componentsSeparatedByString:@":"];

	if(components.count == 1)
	{
		return lcpHex;
	}

	NSString* hexStr = components.firstObject;
	NSString* alphaStr = components.lastObject;

	CGFloat alpha = [alphaStr floatValue];
	NSString* alphaHexStr = [NSString stringWithFormat:@"#%2lX", (long)(255 * alpha)];

	NSString* lcscpHex = [hexStr stringByReplacingOccurrencesOfString:@"#" withString:alphaHexStr];

	return lcscpHex;
}

+ (NSDictionary*)locationWithName:(NSString*)name path:(NSString*)path
{
	NSMutableDictionary* locationM = [NSMutableDictionary new];

	if(name)
	{
		[locationM setObject:name forKey:@"name"];
	}

	if(path)
	{
		[locationM setObject:path forKey:@"path"];
	}

	return [locationM copy];
}

@end

#endif
