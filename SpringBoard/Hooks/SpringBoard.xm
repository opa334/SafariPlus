// SpringBoard.xm
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

#import "../Classes/SPSBReceiver.h"
#import "../../MobileSafari/Defines.h"

SPSBReceiver* receiver;

%hook SpringBoard

//Use rocketbootstrap to receive messages through CPDistributedMessagingCenter
- (id)init
{
	id orig = %orig;

	receiver = [[SPSBReceiver alloc] init];

	return orig;
}

%end

@interface LSBundleProxy : NSObject
@property (nonatomic,readonly) NSString* bundleIdentifier;
@property (nonatomic,readonly) NSDictionary* entitlements;
@end

%group iOS10Up

%hook LSBundleProxy

//Spoof aps-environment = production entitlement

- (NSDictionary*)entitlementValuesForKeys:(NSArray*)keys
{
	NSDictionary* orig = %orig;

	if([self.bundleIdentifier isEqualToString:@"com.apple.mobilesafari"])
	{
		if([keys containsObject:@"aps-environment"])
		{
			NSMutableDictionary* valuesM = [MSHookIvar<NSDictionary*>(orig, "_values") mutableCopy];

			[valuesM setObject:@"production" forKey:@"aps-environment"];

			MSHookIvar<NSDictionary*>(orig, "_values") = [valuesM copy];
		}
	}

	return orig;
}

- (id)entitlementValueForKey:(NSString*)key ofClass:(Class)arg2 valuesOfClass:(Class)arg3
{
	id orig = %orig;

	if([self.bundleIdentifier isEqualToString:@"com.apple.mobilesafari"])
	{
		if([key isEqualToString:@"aps-environment"])
		{
			return @"production";
		}
	}

	return orig;
}

//Spoof SBAppUsesLocalNotifications = true info.plist key

- (id)objectsForInfoDictionaryKeys:(NSArray*)keys
{
	id orig = %orig;

	if([self.bundleIdentifier isEqualToString:@"com.apple.mobilesafari"])
	{
		if([keys containsObject:@"SBAppUsesLocalNotifications"])
		{
			NSMutableDictionary* valuesM = [MSHookIvar<NSDictionary*>(orig, "_values") mutableCopy];

			[valuesM setObject:@1 forKey:@"SBAppUsesLocalNotifications"];

			MSHookIvar<NSDictionary*>(orig, "_values") = [valuesM copy];
		}
	}

	return orig;
}

- (id)objectForInfoDictionaryKey:(NSString*)key ofClass:(Class)arg2 valuesOfClass:(Class)arg3
{
	if([self.bundleIdentifier isEqualToString:@"com.apple.mobilesafari"])
	{
		if([key isEqualToString:@"SBAppUsesLocalNotifications"])
		{
			return @1;
		}
	}

	return %orig;
}

%end

%end

%group iOS9Down

%hook LSBundleProxy

//Spoof aps-environment = production entitlement

- (NSDictionary*)entitlements
{
	NSDictionary* entitlements = %orig;

	if([self.bundleIdentifier isEqualToString:@"com.apple.mobilesafari"])
	{
		if(![entitlements objectForKey:@"aps-environment"])
		{
			NSMutableDictionary* entitlementsM = [entitlements mutableCopy];

			[entitlementsM setObject:@"production" forKey:@"aps-environment"];

			entitlements = [entitlementsM copy];
		}
	}

	return entitlements;
}

%end

%hook SBApplication

//Spoof SBAppUsesLocalNotifications = true info.plist key

- (instancetype)initWithApplicationInfo:(id /*FBApplicationInfo*/)info bundle:(NSBundle*)bundle infoDictionary:(id)infoDictionary
{
	NSDictionary* __infoDictionary = infoDictionary;
	if([[bundle bundleIdentifier] isEqualToString:@"com.apple.mobilesafari"])
	{
		NSMutableDictionary* infoDictionaryM = [__infoDictionary mutableCopy];
		[infoDictionaryM setObject:@1 forKey:@"SBAppUsesLocalNotifications"];
		__infoDictionary = [infoDictionaryM copy];
	}
	return %orig(info,bundle,__infoDictionary);
}

%end

%end

%ctor
{
	%init();

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0)
	{
		%init(iOS10Up);
	}
	else
	{
		%init(iOS9Down);
	}
}
