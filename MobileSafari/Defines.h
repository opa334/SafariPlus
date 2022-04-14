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

#if defined(SIMJECT)
#define SPBundlePath [NSString stringWithFormat:@"%@/layout/Library/Application Support/SafariPlus.bundle", [CUR_DIR stringByDeletingLastPathComponent]]
#define CURRENT_USER NSHomeDirectory().pathComponents[2]
#define DEFAULT_DOWNLOAD_PATH [NSString stringWithFormat:@"/Users/%@/Desktop/SafariPlusFiles/Downloads", CURRENT_USER]
#else
#define SPBundlePath @"/Library/Application Support/SafariPlus.bundle"
#define OLD_DOWNLOAD_PATH [NSHomeDirectory() stringByAppendingString:@"/Documents/Downloads"]
#if defined(NO_ROCKETBOOTSTRAP)
#define DEFAULT_DOWNLOAD_PATH [NSHomeDirectory() stringByAppendingString:@"/Documents/Downloads"]
#else
#define DEFAULT_DOWNLOAD_PATH @"/var/mobile/Downloads"
#endif
#endif

#if defined(ROOTLESS)	//Hack some stuff so that the patcher does not replace /Library with /var/LIB
#define CACHE_PATH [[NSHomeDirectory() stringByAppendingString:[NSString stringWithCString:"/Libr" encoding:NSUTF8StringEncoding]] stringByAppendingString:@"ary/Safari Plus"]
#else
#define CACHE_PATH [NSHomeDirectory() stringByAppendingString:@"/Library/Safari Plus"]
#endif

#define PREFERENCE_DOMAIN_NAME @"com.opa334.safariplusprefs"
#define PREFERENCE_PLIST_NAME [PREFERENCE_DOMAIN_NAME stringByAppendingString:@".plist"]
#define PREF_PLIST_PATH [NSString stringWithFormat:@"/var/mobile/Library/Preferences/%@.plist", PREFERENCE_DOMAIN_NAME]
#define OTHER_PLIST_PATH_DEPRECATED @"/var/mobile/Library/Preferences/com.opa334.safariplusprefsOther.plist"	//NO LONGER USED
#define COLOR_PLIST_PATH_DEPRECATED @"/var/mobile/Library/Preferences/com.opa334.safaripluscolorprefs.plist"	//NO LONGER USED

#define DEPRECATED_CACHE_PATH [NSHomeDirectory() stringByAppendingString:@"/Library/Caches/com.opa334.safariplus"]
#define IS_PAD ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
#define CURRENT_DOWNLOAD_STORAGE_REVISION 3

#ifndef kCFCoreFoundationVersionNumber_iOS_9_0
#define kCFCoreFoundationVersionNumber_iOS_9_0 1223.1
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_10_0
#define kCFCoreFoundationVersionNumber_iOS_10_0 1348.00
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_10_3
#define kCFCoreFoundationVersionNumber_iOS_10_3 1349.56
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_11_0
#define kCFCoreFoundationVersionNumber_iOS_11_0 1443.00
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_11_2
#define kCFCoreFoundationVersionNumber_iOS_11_2 1450.14
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_11_3
#define kCFCoreFoundationVersionNumber_iOS_11_3 1452.23
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_12_0
#define kCFCoreFoundationVersionNumber_iOS_12_0 1556.00
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_12_2
#define kCFCoreFoundationVersionNumber_iOS_12_2 1570.15
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_13_0
#define kCFCoreFoundationVersionNumber_iOS_13_0 1665.15
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_13_4
#define kCFCoreFoundationVersionNumber_iOS_13_4 1675.129
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_14_0
#define kCFCoreFoundationVersionNumber_iOS_14_0 1751.108
#endif

#ifdef __arm64e__
#define ifArm64eElse(a,b) (a)
#else
#define ifArm64eElse(a,b) (b)
#endif

#import <HBLog.h>
#ifdef __DEBUG__
	#define HBLogDebugWeak(args ...) HBLogDebug(args)
#else
	#define HBLogDebugWeak(...)
#endif

//Used for debugging
#define DEBUG_CRASH NSMutableArray* arr = (NSMutableArray*)[[NSArray alloc] init]; [arr addObject:@"crash"];