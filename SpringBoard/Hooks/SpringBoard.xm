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
