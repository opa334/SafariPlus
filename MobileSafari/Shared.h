// Shared.h
// (c) 2017 opa334

@class SPLocalizationManager, SPPreferenceManager, SafariWebView;

extern BOOL desktopButtonSelected;
extern BOOL showAlert;
extern int iOSVersion;
extern SPPreferenceManager* preferenceManager;
extern SPLocalizationManager* localizationManager;
extern NSBundle* SPBundle;
extern NSBundle* MSBundle;
extern NSMutableDictionary* otherPlist;

extern BOOL privateBrowsingEnabled();
extern SafariWebView* activeWebView();
extern void loadOtherPlist();
extern void saveOtherPlist();

@interface UIImage (ColorInverse)
+ (UIImage *)inverseColor:(UIImage *)image;
@end
