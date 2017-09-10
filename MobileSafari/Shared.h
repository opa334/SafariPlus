// Shared.h
// (c) 2017 opa334

@class SPLocalizationManager, SPPreferenceManager;

extern BOOL desktopButtonSelected;
extern int iOSVersion;
extern SPPreferenceManager* preferenceManager;
extern SPLocalizationManager* localizationManager;
extern NSBundle* SPBundle;
extern NSBundle* MSBundle;

extern BOOL privateBrowsingEnabled();
