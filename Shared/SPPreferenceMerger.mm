// SPPreferenceMerger.mm
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
#import "SPPreferenceMerger.h"
#import "../MobileSafari/Util.h"
#import "../MobileSafari/Classes/SPFileManager.h"
#import "Simulator.h"

#ifdef PREFERENCES
@interface PSRootController : UINavigationController
+ (void)setPreferenceValue:(id)arg1 specifier:(id)arg2;
+ (id)readPreferenceValue:(id)arg1;
@end
#import <Preferences/PSSpecifier.h>
#endif

#ifndef SIMJECT

#ifndef NO_CEPHEI
#ifndef PREFERENCES
#import <Cephei/HBPreferences.h>
#endif
#endif

@implementation SPPreferenceMerger

+ (BOOL)needsMerge
{
	BOOL colorsExists = [fileManager fileExistsAtPath:rPath(colorPrefsPath)];
	BOOL otherExists = [fileManager fileExistsAtPath:rPath(otherPlistPath)];

	return colorsExists || otherExists;
}

+ (void)mergeIfNeeded
{
	#ifndef NO_CEPHEI
	BOOL needed = [self needsMerge];

	if(!needed)
	{
		return;
	}

	#ifndef NO_CEPHEI
  #ifndef PREFERENCES
	HBPreferences* tmpPreferences = [[HBPreferences alloc] initWithIdentifier:preferenceDomainName];
  #endif
	#endif

	NSDictionary* colorDict = [NSDictionary dictionaryWithContentsOfFile:rPath(colorPrefsPath)];
	if(colorDict)
	{
		for(NSString* key in [colorDict allKeys])
		{
			NSString* lcpHex = [colorDict objectForKey:key];
			NSString* lcscpHex = [self LCSCPHexFromLCPHex:lcpHex];

      #ifdef PREFERENCES
			CFPreferencesSetValue((__bridge CFStringRef)key, (__bridge CFPropertyListRef)lcscpHex, (__bridge CFStringRef)preferenceDomainName, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			CFPreferencesSynchronize((__bridge CFStringRef)preferenceDomainName, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
      #else
			[tmpPreferences setObject:lcscpHex forKey:key];
      #endif
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
      #ifdef PREFERENCES
			CFPreferencesSetValue((__bridge CFStringRef)@"forceHTTPSExceptions", (__bridge CFPropertyListRef)forceHTTPSExceptions, (__bridge CFStringRef)preferenceDomainName, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			CFPreferencesSynchronize((__bridge CFStringRef)preferenceDomainName, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
      #else
			[tmpPreferences setObject:forceHTTPSExceptions forKey:@"forceHTTPSExceptions"];
      #endif
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

				#ifdef PREFERENCES
				CFPreferencesSetValue((__bridge CFStringRef)@"pinnedLocations", (__bridge CFPropertyListRef)[pinnedLocationsM copy], (__bridge CFStringRef)preferenceDomainName, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				CFPreferencesSynchronize((__bridge CFStringRef)preferenceDomainName, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
				#else
				[tmpPreferences setObject:[pinnedLocationsM copy] forKey:@"pinnedLocations"];
				#endif
			}

			[fileManager removeItemAtPath:rPath(otherPlistPath) error:nil];
		}
	}

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
