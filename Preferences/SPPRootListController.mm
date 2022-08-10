// Copyright (c) 2017-2022 Lars Fröder

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

#import "SPPRootListController.h"
#import "SafariPlusPrefs.h"
#import <dlfcn.h>
#import "Simulator.h"

#import "../Shared/SPPreferenceUpdater.h"
#import "../Shared/ColorPickerCompat.h"
#import "../MobileSafari/Util.h"
#import <mach-o/dyld.h>

SPFileManager* fileManager;
SPLocalizationManager* localizationManager;
NSBundle* SPBundle;	//Safari Plus
NSBundle* MSBundle;	//MobileSafari
NSBundle* SSBundle;	//SafariServices

BOOL isImageLoaded(NSString* imageName)
{
	for (uint32_t i = 0; i < _dyld_image_count(); i++)
	{
		const char *pathC = _dyld_get_image_name(i);
		NSString* path = [NSString stringWithUTF8String:pathC];

		if([path.lastPathComponent isEqualToString:imageName])
		{
			return YES;
		}
	}

	return NO;
}

@implementation SPPRootListController

- (id)init
{
	self = [super init];

	loadColorPicker();

	fileManager = [SPFileManager sharedInstance];
	localizationManager = [SPLocalizationManager sharedInstance];
	SPBundle = [NSBundle bundleWithPath:SPBundlePath];
	MSBundle = [NSBundle bundleWithPath:rPath(@"/Applications/MobileSafari.app/")];
	SSBundle = [NSBundle bundleWithPath:rPath(@"/System/Library/Frameworks/SafariServices.framework/")];

	#ifndef SIMJECT
	[SPPreferenceUpdater update];
	#endif

	return self;
}

- (NSString*)title
{
	return @"Safari Plus";
}

- (NSString*)plistName
{
	return @"Root";
}

- (void)sourceLink
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/opa334/SafariPlus"]];
}

- (void)openTwitter
{
	[self openTwitterWithUsername:@"opa334dev"];
}

- (void)donationLink
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=opa334@protonmail.com&item_name=iOS%20Tweak%20Development"]];
}

@end
