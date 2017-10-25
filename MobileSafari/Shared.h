// Shared.h
// (c) 2017 opa334

@class BrowserController, TabDocument, SPLocalizationManager, SPPreferenceManager, SafariWebView;

extern BOOL desktopButtonSelected;
extern BOOL showAlert;
extern int iOSVersion;
extern SPPreferenceManager* preferenceManager;
extern SPLocalizationManager* localizationManager;
extern NSBundle* SPBundle;
extern NSBundle* MSBundle;
extern NSMutableDictionary* otherPlist;

extern BOOL privateBrowsingEnabled();
extern void togglePrivateBrowsing();
extern TabDocument* activeTabDocument();
extern SafariWebView* activeWebView();
extern BrowserController* mainBrowserController();
extern void loadOtherPlist();
extern void saveOtherPlist();

@interface UIImage (ColorInverse)
+ (UIImage *)inverseColor:(UIImage *)image;
@end
