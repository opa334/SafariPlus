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

#import "../Util.h"
#import "../Defines.h"
#import "SPFileManager.h"
#import "SPMediaFetcher.h"

extern "C"
{
CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);
}

BOOL registered = NO;
void (^g_completionHandler)(NSURL* URL);

void currentVideoURLReceived(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	HBLogDebug(@"currentVideoURLReceived");
	if(!g_completionHandler)
	{
		return;
	}

	NSString* URLString;

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_12_0)
	{
		NSDictionary* dictUserInfo = (__bridge NSDictionary*)userInfo;
		URLString = [dictUserInfo objectForKey:@"videoURL"];
	}
	else
	{
		NSString* videoURLPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"videoURL.txt"];
		URLString = [NSString stringWithContentsOfFile:videoURLPath usedEncoding:nil error:nil];
		[fileManager removeItemAtPath:videoURLPath error:nil];
	}

	NSURL* receivedURL = nil;

	if(URLString)
	{
		receivedURL = [NSURL URLWithString:URLString];
	}

	g_completionHandler(receivedURL);

	g_completionHandler = nil;
}

@implementation SPMediaFetcher

+ (void)getURLForCurrentlyPlayingMediaWithCompletionHandler:(void (^)(NSURL* URL))completionHandler
{
	if(!registered)
	{
		CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, currentVideoURLReceived, CFSTR("com.opa334.safariplus/CurrentVideoURLForRequest"), CFSTR("CurrentVideoURLForRequest"), CFNotificationSuspensionBehaviorDeliverImmediately);
		registered = YES;
	}

	g_completionHandler = completionHandler;
	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.opa334.safariplus/RequestCurrentVideoURL"), CFSTR("RequestCurrentVideoURL"), nil, YES);

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^
	{
		if(g_completionHandler)
		{
			g_completionHandler(nil);
		}
	});
}

@end
