// Defines.h
// (c) 2017 opa334

#ifdef SIMJECT
#define otherPlistPath [NSString stringWithFormat:@"/User/%@/Desktop/SafariPlusFiles/com.opa334.safariplusprefsOther.plist", NSUserName()]
#define SPBundlePath [NSString stringWithFormat:@"%@/layout/Library/Application Support/SafariPlus.bundle", [CUR_DIR stringByDeletingLastPathComponent]]
#define defaultDownloadPath [NSString stringWithFormat:@"/Users/%@/Desktop/SafariPlusFiles/Downloads", USER]
#else
#define otherPlistPath @"/var/mobile/Library/Preferences/com.opa334.safariplusprefsOther.plist"
#define SPBundlePath @"/Library/Application Support/SafariPlus.bundle"
#define defaultDownloadPath @"/User/Downloads"
#endif

#define desktopUserAgent @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_5) AppleWebKit/603.2.4 (KHTML, like Gecko) Version/10.1.1 Safari/603.2.4"
#define downloadStoragePath [NSHomeDirectory() stringByAppendingString:@"/Library/Safari/downloads"]
#define IS_PAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#define DownloadStorageRevision 2

#ifndef kCFCoreFoundationVersionNumber_iOS_9_0
#define kCFCoreFoundationVersionNumber_iOS_9_0 1223.1
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_10_0
#define kCFCoreFoundationVersionNumber_iOS_10_0 1348.00
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_11_0
#define kCFCoreFoundationVersionNumber_iOS_11_0 1438.10
#endif
