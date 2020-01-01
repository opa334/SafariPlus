// Copyright (c) 2017-2020 Lars Fröder

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
