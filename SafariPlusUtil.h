//  SafariPlusUtil.h
//  Headers for utils

// (c) 2017 opa334

#import <Cephei/HBPreferences.h>
@import WebKit;

#define IS_PAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

@class SPPreferenceManager, SPLocalizationManager;

extern SPPreferenceManager* preferenceManager;
extern SPLocalizationManager* localizationManager;
extern NSBundle* SPBundle;
extern NSBundle* MSBundle;

@interface SPPreferenceManager : NSObject
{
  HBPreferences *preferences;
}

@property(nonatomic, readonly) BOOL enableFullscreenScrolling;
@property(nonatomic, readonly) BOOL forceHTTPSEnabled;
@property(nonatomic, readonly) BOOL disablePrivateMode;
@property(nonatomic, readonly) BOOL uploadAnyFileOptionEnabled;

@property(nonatomic, readonly) BOOL enhancedDownloadsEnabled;
@property(nonatomic, readonly) BOOL instantDownloadsEnabled;
@property(nonatomic, readonly) NSInteger instantDownloadsOption;
@property(nonatomic, readonly) BOOL customDefaultPathEnabled;
@property(nonatomic, readonly, retain) NSString* customDefaultPath;
@property(nonatomic, readonly) BOOL onlyDownloadOnWifiEnabled;
@property(nonatomic, readonly) BOOL disablePushNotificationsEnabled;
@property(nonatomic, readonly) BOOL disableBarNotificationsEnabled;

@property(nonatomic, readonly) BOOL forceModeOnStartEnabled;
@property(nonatomic, readonly) NSInteger forceModeOnStartFor;
@property(nonatomic, readonly) BOOL forceModeOnResumeEnabled;
@property(nonatomic, readonly) NSInteger forceModeOnResumeFor;
@property(nonatomic, readonly) BOOL forceModeOnExternalLinkEnabled;
@property(nonatomic, readonly) NSInteger forceModeOnExternalLinkFor;
@property(nonatomic, readonly) BOOL autoCloseTabsEnabled;
@property(nonatomic, readonly) NSInteger autoCloseTabsOn;
@property(nonatomic, readonly) NSInteger autoCloseTabsFor;
@property(nonatomic, readonly) BOOL autoDeleteDataEnabled;
@property(nonatomic, readonly) NSInteger autoDeleteDataOn;

@property(nonatomic, readonly) BOOL URLLeftSwipeGestureEnabled;
@property(nonatomic, readonly) NSInteger URLLeftSwipeAction;
@property(nonatomic, readonly) BOOL URLRightSwipeGestureEnabled;
@property(nonatomic, readonly) NSInteger URLRightSwipeAction;
@property(nonatomic, readonly) BOOL URLDownSwipeGestureEnabled;
@property(nonatomic, readonly) NSInteger URLDownSwipeAction;
@property(nonatomic, readonly) BOOL gestureBackground;

@property(nonatomic, readonly) BOOL openInNewTabOptionEnabled;
@property(nonatomic, readonly) BOOL desktopButtonEnabled;
@property(nonatomic, readonly) BOOL longPressSuggestionsEnabled;

@property(nonatomic, readonly) BOOL appTintColorNormalEnabled;
@property(nonatomic, readonly,retain) NSString* appTintColorNormal;
@property(nonatomic, readonly) BOOL topBarColorNormalEnabled;
@property(nonatomic, readonly,retain) NSString* topBarColorNormal;
@property(nonatomic, readonly) BOOL URLFontColorNormalEnabled;
@property(nonatomic, readonly,retain) NSString* URLFontColorNormal;
@property(nonatomic, readonly) BOOL progressBarColorNormalEnabled;
@property(nonatomic, readonly,retain) NSString* progressBarColorNormal;
@property(nonatomic, readonly) BOOL tabTitleColorNormalEnabled;
@property(nonatomic, readonly,retain) NSString* tabTitleColorNormal;
@property(nonatomic, readonly) BOOL reloadColorNormalEnabled;
@property(nonatomic, readonly,retain) NSString* reloadColorNormal;
@property(nonatomic, readonly) BOOL lockIconColorNormalEnabled;
@property(nonatomic, readonly,retain) NSString* lockIconColorNormal;
@property(nonatomic, readonly) BOOL bottomBarColorNormalEnabled;
@property(nonatomic, readonly,retain) NSString* bottomBarColorNormal;

@property(nonatomic, readonly) BOOL appTintColorPrivateEnabled;
@property(nonatomic, readonly,retain) NSString* appTintColorPrivate;
@property(nonatomic, readonly) BOOL topBarColorPrivateEnabled;
@property(nonatomic, readonly,retain) NSString* topBarColorPrivate;
@property(nonatomic, readonly) BOOL URLFontColorPrivateEnabled;
@property(nonatomic, readonly,retain) NSString* URLFontColorPrivate;
@property(nonatomic, readonly) BOOL progressBarColorPrivateEnabled;
@property(nonatomic, readonly,retain) NSString* progressBarColorPrivate;
@property(nonatomic, readonly) BOOL tabTitleColorPrivateEnabled;
@property(nonatomic, readonly,retain) NSString* tabTitleColorPrivate;
@property(nonatomic, readonly) BOOL reloadColorPrivateEnabled;
@property(nonatomic, readonly,retain) NSString* reloadColorPrivate;
@property(nonatomic, readonly) BOOL lockIconColorPrivateEnabled;
@property(nonatomic, readonly,retain) NSString* lockIconColorPrivate;
@property(nonatomic, readonly) BOOL bottomBarColorPrivateEnabled;
@property(nonatomic, readonly,retain) NSString* bottomBarColorPrivate;

+ (instancetype)sharedInstance;

@end


@interface SPLocalizationManager : NSObject {}

+ (instancetype)sharedInstance;
- (NSString*)localizedSPStringForKey:(NSString*)key;
- (NSString*)localizedMSStringForKey:(NSString*)key;

@end
