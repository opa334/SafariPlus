// Copyright (c) 2017-2019 Lars Fröder

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

/*%hook _SFToolbar

- (void)setTheme:(_SFBarTheme *)arg1
{

}

%end*/

#import "../SafariPlus.h"
#import "../Defines.h"

#import <dlfcn.h>

BOOL (*_SFIsPrivateTintStyle)(NSUInteger tintStyle);

@interface UIBlurEffect ()
+ (instancetype)_effectWithTintColor:(id)arg1;
@end

%hook _SFNavigationBar

- (void)setTheme:(_SFBarTheme*)theme
{
	NSLog(@"theme.backdropEffect = %@", theme.backdropEffect);
	NSLog(@"theme.backdropAdjustmentEffects = %@", theme.backdropAdjustmentEffects);

	if(UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleLight)
	{
		[theme setValue:[UIColor redColor] forKey:@"_preferredControlsTintColor"];
	}
	else if(UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark)
	{
		[theme setValue:[UIColor greenColor] forKey:@"_preferredControlsTintColor"];
	}

	NSLog(@"new theme.backdropEffect = %@", theme.backdropEffect);
	
	%orig(theme);
}

%end

void initColors_13Up()
{
	if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_13_0)
	{
		return;
	}

	void* safariServicesHandle = dlopen("/System/Library/Frameworks/SafariServices.framework/SafariServices", RTLD_NOW);
	_SFIsPrivateTintStyle = (BOOL (*)(NSUInteger))dlsym(safariServicesHandle, "_SFIsPrivateTintStyle");
	NSLog(@"_SFIsPrivateTintStyle:%p", _SFIsPrivateTintStyle);

	%init();
}