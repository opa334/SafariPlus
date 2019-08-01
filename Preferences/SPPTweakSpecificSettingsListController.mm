// SPPTweakSpecificSettingsListController.mm
// (c) 2017 - 2019 opa334

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

#import "SPPTweakSpecificSettingsListController.h"
#import "SafariPlusPrefs.h"
#import "../MobileSafari/Defines.h"
#import <Preferences/PSSpecifier.h>
#import <LocalAuthentication/LocalAuthentication.h>

@interface NPSDomainAccessor : NSObject
- (NSArray*)copyKeyList;
- (NSObject*)objectForKey:(NSString*)key;
- (void)removeObjectForKey:(NSString*)key;
- (id)initWithDomain:(NSString*)domain;
- (id)synchronize;
@end

@implementation SPPTweakSpecificSettingsListController

- (NSString*)plistName
{
	return @"TweakSpecificSettings";
}

- (NSString*)title
{
	return [localizationManager localizedSPStringForKey:@"TWEAK_SPECIFIC_SETTINGS"];
}

- (void)resetAllPreferences
{
	NSUserDefaults* sppDefaults = [[NSUserDefaults alloc] initWithSuiteName:preferenceDomainName];

	void (^resetBlock)(void) = ^
	{
		UIAlertController* confirmationAlert = [UIAlertController alertControllerWithTitle:
							[localizationManager localizedSPStringForKey:@"RESET_ALL_PREFERENCES"]
							message:[localizationManager localizedSPStringForKey:@"RESET_ALL_PREFERENCES_CONFIRMATION"]
							preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction* noAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"NO"]
					   style:UIAlertActionStyleDefault handler:nil];

		UIAlertAction* yesAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"YES"]
					    style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action)
		{
			for(NSString* key in [[sppDefaults dictionaryRepresentation] allKeys])
			{
				[sppDefaults removeObjectForKey:key];
			}

			[sppDefaults synchronize];

			[self reloadSpecifiers];
		}];

		[confirmationAlert addAction:noAction];
		[confirmationAlert addAction:yesAction];

		[self presentViewController:confirmationAlert animated:YES completion:nil];
	};

	if([[sppDefaults objectForKey:@"biometricProtectionEnabled"] boolValue])
	{
		LAContext* myContext = [[LAContext alloc] init];
		NSError* authError = nil;
		if([myContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError])
		{
			[myContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
			 localizedReason:[localizationManager localizedSPStringForKey:@"RESET_ALL_PREFERENCES"] reply:^(BOOL success, NSError* error)
			{
				if(success)
				{
					dispatch_async(dispatch_get_main_queue(), ^
						       {
							       resetBlock();
						       });
				}
				else if(error.code != -2)
				{
					UIAlertController* authenticationAlert = [UIAlertController alertControllerWithTitle:
										  [localizationManager localizedSPStringForKey:@"AUTHENTICATION_ERROR"]
										  message:[NSString stringWithFormat:@"%li: %@", (long)error.code, error.localizedDescription]
										  preferredStyle:UIAlertControllerStyleAlert];

					UIAlertAction* closeAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CLOSE"]
								      style:UIAlertActionStyleDefault handler:nil];

					[authenticationAlert addAction:closeAction];

					[self presentViewController:authenticationAlert animated:YES completion:nil];
				}
			}];
		}
		else
		{
			resetBlock();
		}
	}
	else
	{
		resetBlock();
	}
}

@end
