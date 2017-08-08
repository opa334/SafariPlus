//  SPLocalizationManager.h
// (c) 2017 opa334

@import WebKit;

#define IS_PAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

@class SPLocalizationManager;

extern SPLocalizationManager* localizationManager;
extern NSBundle* SPBundle;
extern NSBundle* MSBundle;

@interface SPLocalizationManager : NSObject {}

+ (instancetype)sharedInstance;
- (NSString*)localizedSPStringForKey:(NSString*)key;
- (NSString*)localizedMSStringForKey:(NSString*)key;

@end
