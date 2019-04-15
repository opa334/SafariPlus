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

#import "SPPCreditsListController.h"
#import "SafariPlusPrefs.h"

@implementation SPPCreditsListController

- (NSString*)title
{
	return [localizationManager localizedSPStringForKey:@"CREDITS"];
}

- (NSString*)plistName
{
	return @"Credits";
}

- (void)WatusiLink
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.reddit.com/r/jailbreak/comments/6f7zdn/release_watusi_2_your_allinone_tweak_for_whatsapp/"]];
}

@end
