// SPPreferenceUpdater.mm
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

#import "../MobileSafari/Defines.h"
#import "SPPreferenceUpdater.h"
#import "../MobileSafari/Util.h"
#import "../MobileSafari/Classes/SPFileManager.h"
#import "Simulator.h"

#ifndef SIMJECT

#ifndef NO_CEPHEI
#ifndef PREFERENCES
#import <Cephei/HBPreferences.h>
#import "../MobileSafari/Classes/SPPreferenceManager.h"
#endif
#endif

@implementation SPPreferenceUpdater

+ (BOOL)needsMerge
{
	BOOL colorsExists = [fileManager fileExistsAtPath:rPath(colorPrefsPath)];
	BOOL otherExists = [fileManager fileExistsAtPath:rPath(otherPlistPath)];

	return colorsExists || otherExists;
}

+ (void)update
{
	#ifndef NO_CEPHEI
	BOOL mergeNeeded = [self needsMerge];

	#ifndef PREFERENCES
	NSLog(@"preferenceManager=%@", preferenceManager);
	HBPreferences* preferences = [preferenceManager preferences];
  #else
	NSUserDefaults* preferences = [[NSUserDefaults alloc] initWithSuiteName:preferenceDomainName];
	#endif

	if(mergeNeeded)
	{
		NSDictionary* colorDict = [NSDictionary dictionaryWithContentsOfFile:rPath(colorPrefsPath)];
		if(colorDict)
		{
			for(NSString* key in [colorDict allKeys])
			{
				NSString* lcpHex = [colorDict objectForKey:key];
				NSString* lcscpHex = [self LCSCPHexFromLCPHex:lcpHex];

				[preferences setObject:lcscpHex forKey:key];
			}

			[fileManager removeItemAtPath:rPath(colorPrefsPath) error:nil];
		}

		NSDictionary* otherDict = [NSDictionary dictionaryWithContentsOfFile:rPath(otherPlistPath)];
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

				[fileManager removeItemAtPath:rPath(otherPlistPath) error:nil];
			}
		}
	}

	NSDictionary* deprecatedToNewKeys = @
					    {
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

	#endif
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
