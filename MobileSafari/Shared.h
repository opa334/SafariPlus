// Shared.h
// (c) 2017 opa334

@class SPLocalizationManager, SPPreferenceManager;

extern BOOL desktopButtonSelected;
extern int iOSVersion;
extern SPPreferenceManager* preferenceManager;
extern SPLocalizationManager* localizationManager;
extern NSBundle* SPBundle;
extern NSBundle* MSBundle;
extern NSMutableDictionary* otherPlist;

extern BOOL privateBrowsingEnabled();
extern void loadOtherPlist();
extern void saveOtherPlist();
