//  SPLocalizationManager.h
// (c) 2017 opa334

@class SPLocalizationManager;

@interface SPLocalizationManager : NSObject {}

+ (instancetype)sharedInstance;
- (NSString*)localizedSPStringForKey:(NSString*)key;
- (NSString*)localizedMSStringForKey:(NSString*)key;

@end
