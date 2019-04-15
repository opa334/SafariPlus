// SPPRootListController.mm
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

#import "SPPRootListController.h"
#import "SafariPlusPrefs.h"
#import <dlfcn.h>

#import "../Shared/SPPreferenceMerger.h"

SPFileManager* fileManager;
SPLocalizationManager* localizationManager;
NSBundle* SPBundle;	//Safari Plus
NSBundle* MSBundle;	//MobileSafari
NSBundle* SSBundle;	//SafariServices

#ifdef SIMJECT

#import <UIKit/UIFunctions.h>

#define currentUser NSHomeDirectory().pathComponents[2]

NSString* simulatorPath(NSString* path)
{
	if([path hasPrefix:@"/var/mobile/"] || [path hasPrefix:@"/User/"])
	{
		NSString* simulatorID = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject].pathComponents[7];
		NSString* strippedPath = [path stringByReplacingOccurrencesOfString:@"/var/mobile/" withString:@""];
		strippedPath = [strippedPath stringByReplacingOccurrencesOfString:@"/User/" withString:@""];
		return [NSString stringWithFormat:@"/Users/%@/Library/Developer/CoreSimulator/Devices/%@/data/%@", currentUser, simulatorID, strippedPath];
	}
	return [UISystemRootDirectory() stringByAppendingPathComponent:path];
}

#endif

@implementation SPPRootListController

- (id)init
{
	self = [super init];

	fileManager = [SPFileManager sharedInstance];
	localizationManager = [SPLocalizationManager sharedInstance];
	SPBundle = [NSBundle bundleWithPath:SPBundlePath];
	MSBundle = [NSBundle bundleWithPath:rPath(@"/Applications/MobileSafari.app/")];
	SSBundle = [NSBundle bundleWithPath:rPath(@"/System/Library/Frameworks/SafariServices.framework/")];

	[SPPreferenceMerger mergeIfNeeded];

	return self;
}

- (NSMutableArray*)specifiers
{
	return [super specifiers];
}

- (NSString*)title
{
	return @"Safari Plus";
}

- (NSString*)plistName
{
	return @"Root";
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	if(section == 0)
	{
		return self.headerView;
	}

	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	if(!self.headerView)
	{
		UIImage* headerImage = [UIImage imageNamed:@"PrefHeader" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
		self.headerView = [[UIImageView alloc] initWithImage:headerImage];

		CGFloat aspectRatio = 3.312;
		CGFloat width = self.parentViewController.view.frame.size.width;
		CGFloat height = width / aspectRatio;

		self.headerView.frame = CGRectMake(0,0,width,height);
	}

	if(section == 0)
	{
		return self.headerView.frame.size.height;
	}

	return 0;
}

- (void)sourceLink
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/opa334/SafariPlus"]];
}

- (void)openTwitter
{
	if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]])
	{
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitter://user?screen_name=opa334dev"]];
	}
	else
	{
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/opa334dev"]];
	}
}

- (void)donationLink
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=opa334@protonmail.com&item_name=iOS%20Tweak%20Development"]];
}

@end
