//  SPLocalizationManager.xm
// (c) 2017 opa334

#import "SPLocalizationManager.h"

#import "../Shared.h"

@implementation SPLocalizationManager

+ (instancetype)sharedInstance
{
  static SPLocalizationManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
      sharedInstance = [[SPLocalizationManager alloc] init];
  });
  return sharedInstance;
}

//Used to retrieve a localized string out of SafariPlus
- (NSString*)localizedSPStringForKey:(NSString*)key;
{
  NSString* localizedString = [SPBundle localizedStringForKey:key value:nil table:nil];
  if([localizedString isEqualToString:key])
  {
    //Handle missing localization
    NSDictionary *englishDict = [[NSDictionary alloc]
      initWithContentsOfFile:[SPBundle pathForResource:@"Localizable"
      ofType:@"strings" inDirectory:@"en.lproj"]];

    localizedString = [englishDict objectForKey:key];

    if(!localizedString)
    {
      return key;
    }
  }
  return localizedString;
}

//Used to retrieve a localized string out of MobileSafari
- (NSString*)localizedMSStringForKey:(NSString*)key
{
  NSString* localizedString = [MSBundle localizedStringForKey:key value:key table:nil];
  return localizedString;
}

@end
