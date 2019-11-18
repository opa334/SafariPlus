// Copyright (c) 2017-2019 Lars Fröder

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
#define currentUser NSHomeDirectory().pathComponents[2]
#define defaultDownloadPath [NSString stringWithFormat:@"/Users/%@/Desktop/SafariPlusFiles/Downloads", currentUser]
#else
#define SPBundlePath @"/Library/Application Support/SafariPlus.bundle"
#define oldDownloadPath [NSHomeDirectory() stringByAppendingString:@"/Documents/Downloads"]
#if defined(NO_ROCKETBOOTSTRAP)
#define defaultDownloadPath [NSHomeDirectory() stringByAppendingString:@"/Documents/Downloads"]
#else
#define defaultDownloadPath @"/var/mobile/Downloads"
#endif
#endif

#if defined(ROOTLESS)	//Hack some stuff so that the patcher does not replace /Library with /var/LIB
#define SPCachePath [[NSHomeDirectory() stringByAppendingString:[NSString stringWithCString:"/Libr" encoding:NSUTF8StringEncoding]] stringByAppendingString:@"ary/Safari Plus"]
#else
#define SPCachePath [NSHomeDirectory() stringByAppendingString:@"/Library/Safari Plus"]
#endif

#define preferenceDomainName @"com.opa334.safariplusprefs"
#define preferencePlistName [preferenceDomainName stringByAppendingString:@".plist"];
#define prefPlistPath @"/var/mobile/Library/Preferences/com.opa334.safariplusprefs.plist"
#define otherPlistPath @"/var/mobile/Library/Preferences/com.opa334.safariplusprefsOther.plist"	//NO LONGER USED
#define colorPrefsPath @"/var/mobile/Library/Preferences/com.opa334.safaripluscolorprefs.plist"	//NO LONGER USED

#define SPDeprecatedCachePath [NSHomeDirectory() stringByAppendingString:@"/Library/Caches/com.opa334.safariplus"]
#define IS_PAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define currentDownloadStorageRevision 3

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

//Used for debugging
#define DEBUG_CRASH NSMutableArray* arr = (NSMutableArray*)[[NSArray alloc] init]; [arr addObject:@"crash"];
