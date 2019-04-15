// Defines.h
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

//Used for debugging
#define DEBUG_CRASH NSMutableArray* arr = (NSMutableArray*)[[NSArray alloc] init]; [arr addObject:@"crash"];
