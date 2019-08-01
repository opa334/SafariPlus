// SPPRootListController.h
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

#import "SPPPrivacyListController.h"
#import "SafariPlusPrefs.h"

#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>
#import <LocalAuthentication/LocalAuthentication.h>

@implementation SPPPrivacyListController

- (NSString*)plistName
{
	return @"Privacy";
}

- (NSString*)title
{
	return [localizationManager localizedSPStringForKey:@"PRIVACY"];
}

- (void)unlockBiometricProtectionSpecifiers
{
	for(PSSpecifier* specifier in [self valueForKey:@"_allSpecifiers"])
	{
		NSString* key = [specifier propertyForKey:@"key"];
		if([key hasPrefix:@"biometricProtection"])	//Enable all biometric options
		{
			[specifier setProperty:@YES forKey:@"enabled"];
			PSTableCell* cell = [specifier propertyForKey:@"cellObject"];
			[cell setCellEnabled:YES];
		}
		else if([specifier.identifier isEqualToString:@"AUTHENTICATE"])	//Disable authenticate button
		{
			[specifier setProperty:@NO forKey:@"enabled"];
			PSTableCell* cell = [specifier propertyForKey:@"cellObject"];
			[cell setCellEnabled:NO];
		}
	}
}

- (void)authenticate
{
	LAContext* myContext = [[LAContext alloc] init];
	NSError* authError = nil;
	if([myContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError])
	{
		[myContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
		 localizedReason:[localizationManager localizedSPStringForKey:@"ACCESS_BIOMETRIC_PROTECTION"] reply:^(BOOL success, NSError* error)
		{
			if(success)
			{
				dispatch_async(dispatch_get_main_queue(), ^
					       {
						       [self unlockBiometricProtectionSpecifiers];
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
		[self unlockBiometricProtectionSpecifiers];
	}
}

@end
