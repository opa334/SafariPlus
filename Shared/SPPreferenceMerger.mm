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
#import "../MobileSafari/Shared.h"
#import "../MobileSafari/Classes/SPFileManager.h"

#ifndef SIMJECT

#ifndef PREFERENCES
#import <Cephei/HBPreferences.h>
#endif

@implementation SPPreferenceMerger

+ (BOOL)needsMerge
{
	BOOL colorsExists = [fileManager fileExistsAtPath:colorPrefsPath];

	return colorsExists;
}

+ (void)mergeIfNeeded
{
	BOOL needed = [self needsMerge];

	if(!needed)
	{
		return;
	}

	NSString* defaults = @"com.opa334.safariplusprefs";

  #ifndef PREFERENCES
	HBPreferences* tmpPreferences = [[HBPreferences alloc] initWithIdentifier:defaults];
  #endif

	NSDictionary* colorDict = [NSDictionary dictionaryWithContentsOfFile:colorPrefsPath];
	if(colorDict)
	{
		for(NSString* key in [colorDict allKeys])
		{
			NSString* lcpHex = [colorDict objectForKey:key];
			NSString* lcscpHex = [self LCSCPHexFromLCPHex:lcpHex];

      #ifdef PREFERENCES
			CFPreferencesSetValue((__bridge CFStringRef)key, (__bridge CFPropertyListRef)lcscpHex, (__bridge CFStringRef)defaults, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			CFPreferencesSynchronize((__bridge CFStringRef)defaults, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
      #else
			[tmpPreferences setObject:lcscpHex forKey:key];
      #endif
		}

		[fileManager removeItemAtPath:colorPrefsPath error:nil];
	}
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
