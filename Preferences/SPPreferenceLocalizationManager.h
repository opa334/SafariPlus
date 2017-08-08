//  SPPreferenceLocalizationManager.h
// (c) 2017 opa334

#import <Preferences/PSSpecifier.h>

@interface SPPreferenceLocalizationManager : NSObject {}

+ (instancetype)sharedInstance;

//Used to retrieve a localized string out of SafariPlus
- (NSString*)localizedSPStringForKey:(NSString*)key;

//Used to parse settings pages
- (void)parseSPLocalizationsForSpecifiers:(NSArray*) specifiers;

@end
