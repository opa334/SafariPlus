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

#import "SPPEditableListController.h"

#import <Preferences/PSSpecifier.h>

#import "Simulator.h"

@implementation SPPEditableListController

#ifdef NO_CEPHEI

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier
{
	NSString* plistPath = rPath(prefPlistPath);
	NSMutableDictionary* mutableDict = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
	[mutableDict setObject:value forKey:[[specifier properties] objectForKey:@"key"]];
	[mutableDict writeToFile:plistPath atomically:YES];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.opa334.safariplusprefs/ReloadPrefs"), NULL, NULL, YES);
}

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

@end
