// SPPCreditsListController.mm
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

#import "SPPCreditsLicensesListController.h"
#import "SafariPlusPrefs.h"

@implementation SPPCreditsLicensesListController

- (NSString*)title
{
	return [localizationManager localizedSPStringForKey:@"CREDITS_AND_LICENSES"];
}

- (NSString*)plistName
{
	return @"CreditsLicenses";
}

- (void)libSubstitrateLink
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/PoomSmart/libSubstitrate"]];
}

- (void)poomsmartLink
{
	[self openTwitterWithUsername:@"poomsmart"];
}

- (void)safariPlusLicenseLink
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/opa334/SafariPlus/blob/master/LICENSE.md"]];
}

@end
