//  SPPreferenceLocalizationManager.xm
//  Localization manager for preferences

// (c) 2017 opa334

#import "SPPreferenceLocalizationManager.h"

NSBundle* SPBundle = [NSBundle bundleWithPath:@"/Library/Application Support/SafariPlus.bundle"];

@implementation SPPreferenceLocalizationManager

+ (instancetype)sharedInstance
{
  static SPPreferenceLocalizationManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
      sharedInstance = [[SPPreferenceLocalizationManager alloc] init];
  });
  return sharedInstance;
}

- (NSString*)localizedSPStringForKey:(NSString*)key;
{
  NSString* localizedString = [SPBundle localizedStringForKey:key value:nil table:nil];
  if([localizedString isEqualToString:key])
  {
    //Handle missing localization
    NSDictionary *englishDict = [[NSDictionary alloc] initWithContentsOfFile:[SPBundle pathForResource:@"Localizable" ofType:@"strings" inDirectory:@"en.lproj"]];
    if([englishDict objectForKey:key])
    {
      localizedString = [englishDict objectForKey:key];
    }
  }
  return localizedString;
}

- (void)parseSPLocalizationsForSpecifiers:(NSArray*)specifiers
{
  //Clone specifiers and return localized specifiers
  NSMutableArray* mutableSpecifiers = (NSMutableArray*)specifiers;
  for(PSSpecifier* specifier in mutableSpecifiers)
  {
    NSString *localizedTitle = [self localizedSPStringForKey:specifier.properties[@"label"]];
    NSString *localizedFooter = [self localizedSPStringForKey:specifier.properties[@"footerText"]];
    specifier.name = localizedTitle;
    [specifier setProperty:localizedFooter forKey:@"footerText"];
  }
}

@end
