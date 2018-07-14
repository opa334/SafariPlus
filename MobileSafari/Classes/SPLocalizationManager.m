// SPLocalizationManager.m
// (c) 2017 opa334

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import "SPLocalizationManager.h"

#import <Preferences/PSSpecifier.h>
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

- (void)parseSPLocalizationsForSpecifiers:(NSArray*)specifiers
{
  //Localize specifiers
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
