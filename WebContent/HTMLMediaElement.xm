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

#define ENABLE_VIDEO 1

#define PAL_EXPORT

#import <wtf/HashSet.h>
#import <wtf/RefPtr.h>
#import <wtf/text/WTFString.h>
#import <WebCore/PlatformExportMacros.h>
#import <WebCore/HTMLMediaElement.h>

#import "../MobileSafari/Defines.h"

#ifndef NO_CEPHEI
#import <Cephei/HBPreferences.h>
#endif

#import "substitrate.h"

NSMutableDictionary* URLCache;
NSString* currentFullscreenVideoURL;

extern "C"
{
CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);
}

//This gets called called with initialURL being the URL of the media, only way to get it without C++ fuckery
void (*_WebCore_HTMLMediaElement_loadResource)(WebCore::HTMLMediaElement*, const WTF::URL&, WebCore::ContentType&, const WTF::String&);
void WebCore_HTMLMediaElement_loadResource(WebCore::HTMLMediaElement* self, const WTF::URL& initialURL, WebCore::ContentType& contentType, const WTF::String& keySystem)
{
	_WebCore_HTMLMediaElement_loadResource(self, initialURL, contentType, keySystem);

	NSString* URLString = initialURL;

	if(![URLString isEqualToString:@""])
	{
		NSValue* key = [NSValue valueWithPointer:self];
		HBLogDebug(@"%i added key:%@ URL:%@", (int)getpid(), key, URLString);
		[URLCache setObject:URLString forKey:key];
	}
}

//Destructor of HTMLMediaElement
void (*_WebCore_HTMLMediaElement_destructor)(WebCore::HTMLMediaElement*);
void WebCore_HTMLMediaElement_destructor(WebCore::HTMLMediaElement* self)
{
	NSValue* key = [NSValue valueWithPointer:self];

	if([[URLCache allKeys] containsObject:key])
	{
		HBLogDebug(@"%i removed key %@", (int)getpid(), key);
		[URLCache removeObjectForKey:key];
	}

	_WebCore_HTMLMediaElement_destructor(self);
}

void (*_WebCore_HTMLMediaElement_enterFullscreen)(WebCore::HTMLMediaElement*, unsigned);
void WebCore_HTMLMediaElement_enterFullscreen(WebCore::HTMLMediaElement* self, unsigned a1)
{
	HBLogDebug(@"HTMLMediaElement enterFullscreen");
	currentFullscreenVideoURL = [URLCache objectForKey:[NSValue valueWithPointer:self]];

	_WebCore_HTMLMediaElement_enterFullscreen(self, a1);
}

void (*_WebCore_HTMLMediaElement_enterFullscreen_noArg)(WebCore::HTMLMediaElement*);
void WebCore_HTMLMediaElement_enterFullscreen_noArg(WebCore::HTMLMediaElement* self)
{
	HBLogDebug(@"HTMLMediaElement enterFullscreen_noArg");
	currentFullscreenVideoURL = [URLCache objectForKey:[NSValue valueWithPointer:self]];

	_WebCore_HTMLMediaElement_enterFullscreen_noArg(self);
}

void (*_WebCore_HTMLMediaElement_exitFullscreen)(WebCore::HTMLMediaElement*);
void WebCore_HTMLMediaElement_exitFullscreen(WebCore::HTMLMediaElement* self)
{
	HBLogDebug(@"HTMLMediaElement exitFullscreen");
	currentFullscreenVideoURL = nil;

	_WebCore_HTMLMediaElement_exitFullscreen(self);
}

void currentVideoURLRequested(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	HBLogDebug(@"receivedRequest!");

	HBLogDebug(@"currentFullscreenVideoURL:%@", currentFullscreenVideoURL);

	if(currentFullscreenVideoURL)
	{
		if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_12_0)
		{
			NSDictionary* userInfoToSend = @{@"videoURL" : currentFullscreenVideoURL};
			CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.opa334.safariplus/CurrentVideoURLForRequest"), CFSTR("CurrentVideoURLForRequest"), (__bridge CFDictionaryRef)userInfoToSend, YES);
		}
		else
		{
			//On iOS 11 and below, posting notifications with a user info doesn't seem to work
			[currentFullscreenVideoURL writeToFile:[NSTemporaryDirectory() stringByAppendingPathComponent:@"videoURL.txt"] atomically:NO encoding:NSUTF8StringEncoding error:nil];
			CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.opa334.safariplus/CurrentVideoURLForRequest"), CFSTR("CurrentVideoURLForRequest"), NULL, YES);
		}
	}
}

void initHooks()
{
	const char* webCorePath = "/System/Library/PrivateFrameworks/WebCore.framework/WebCore";

	HBLogDebug(@"initHooks");

	//iOS 12.2 and above (probably)
	int hook1 = _PSHookFunctionCompat(webCorePath, "__ZN7WebCore16HTMLMediaElement12loadResourceERKN3WTF3URLERNS_11ContentTypeERKNS1_6StringE", WebCore_HTMLMediaElement_loadResource);
	if(hook1 == 1000)
	{
		//iOS 8 - 12.1.4
		hook1 = _PSHookFunctionCompat(webCorePath, "__ZN7WebCore16HTMLMediaElement12loadResourceERKNS_3URLERNS_11ContentTypeERKN3WTF6StringE", WebCore_HTMLMediaElement_loadResource);
	}
	int hook2 = _PSHookFunctionCompat(webCorePath, "__ZN7WebCore16HTMLMediaElementD0Ev", WebCore_HTMLMediaElement_destructor);
	int hook3 = _PSHookFunctionCompat(webCorePath, "__ZN7WebCore16HTMLMediaElement15enterFullscreenEj", WebCore_HTMLMediaElement_enterFullscreen);
	if(hook3 == 1000)
	{
		hook3 = _PSHookFunctionCompat(webCorePath, "__ZN7WebCore16HTMLMediaElement15enterFullscreenEv", WebCore_HTMLMediaElement_enterFullscreen_noArg);
	}
	int hook4 = _PSHookFunctionCompat(webCorePath, "__ZN7WebCore16HTMLMediaElement14exitFullscreenEv", WebCore_HTMLMediaElement_exitFullscreen);

	HBLogDebug(@"hook1:%i", hook1);
	HBLogDebug(@"hook2:%i", hook2);
	HBLogDebug(@"hook3:%i", hook3);
	HBLogDebug(@"hook4:%i", hook4);
}

static BOOL isSafari()
{
	NSString* safariPath = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Safari"];

	BOOL isDirectory;

	if([[NSFileManager defaultManager] fileExistsAtPath:safariPath isDirectory:&isDirectory] && isDirectory)
	{
		return YES;
	}

	return NO;
}

static BOOL shouldEnable()
{
	#if !defined NO_CEPHEI
	HBPreferences* preferences = [[HBPreferences alloc] initWithIdentifier:preferenceDomainName];
	BOOL tweakEnabled = [preferences boolForKey:@"tweakEnabled" default:YES];
	BOOL videoDownloadingEnabled = [preferences boolForKey:@"videoDownloadingEnabled" default:NO];
	#else
	return YES;
	#endif

	BOOL globalVideoDownloadingEnabled = [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Application Support/SafariPlus.bundle/.enableGlobalVideoDownloading"];

	if((videoDownloadingEnabled && isSafari()) || globalVideoDownloadingEnabled)
	{
		return YES;
	}

	return NO;
}

%ctor
{
	if(shouldEnable())
	{
		URLCache = [NSMutableDictionary new];

		initHooks();

		CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, currentVideoURLRequested, CFSTR("com.opa334.safariplus/RequestCurrentVideoURL"), CFSTR("RequestCurrentVideoURL"), CFNotificationSuspensionBehaviorDeliverImmediately);
	}
}

%dtor
{
	URLCache = nil;
}
