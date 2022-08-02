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

#import <xpc/xpc.h>
#import <dlfcn.h>

NSFileHandle* logFileHandle;

#ifdef DEBUG

void _initLogging()
{
	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [formatter setDateFormat:@"MM_dd_yyyy_hh_mm_ss"];
    NSString* timestamp = [formatter stringFromDate:[NSDate date]];
	NSString* filename = [NSString stringWithFormat:@"SafariPlusWC_%@.log", timestamp];
	NSString* logFilePath = [@"/tmp/" stringByAppendingPathComponent:filename];

	[[NSFileManager defaultManager] createFileAtPath:logFilePath contents:nil attributes:nil];
	logFileHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];

	if(logFileHandle)
	{
		[logFileHandle seekToEndOfFile];
	}
}

void logToFile(NSString* fString, ...)
{
	static dispatch_once_t onceToken;

    dispatch_once (&onceToken, ^{
        _initLogging();
    });

	va_list va;
	va_start(va, fString);
	NSString* msg = [[NSString alloc] initWithFormat:fString arguments:va];
	va_end(va);

	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [formatter setDateFormat:@"hh:mm:ss"];
    NSString* timestamp = [formatter stringFromDate:[NSDate date]];

	NSString* prefix = [NSString stringWithFormat:@"[%@] ", timestamp];

	[logFileHandle writeData:[[prefix stringByAppendingString:[msg stringByAppendingString:@"\n"]] dataUsingEncoding:NSUTF8StringEncoding]];
	NSLog(@"%@", msg);
}

#else
#define logToFile(...)
#endif

#define ENABLE_VIDEO 1

#define PAL_EXPORT

#import <wtf/HashSet.h>
#import <wtf/RefPtr.h>
#import <wtf/text/WTFString.h>
#import <WebCore/PlatformExportMacros.h>
#import <WebCore/HTMLMediaElement.h>

#import "../MobileSafari/Defines.h"

#import "substitrate.h"

NSMutableDictionary* URLCache;
NSString* currentFullscreenVideoURL;

//This gets called called with initialURL being the URL of the media, only way to get it without C++ fuckery
void (*_WebCore_HTMLMediaElement_loadResource)(WebCore::HTMLMediaElement*, const WTF::URL&, WebCore::ContentType&, const WTF::String&);
void WebCore_HTMLMediaElement_loadResource(WebCore::HTMLMediaElement* self, const WTF::URL& initialURL, WebCore::ContentType& contentType, const WTF::String& keySystem)
{
	logToFile(@"loadResource:%p", self);
	_WebCore_HTMLMediaElement_loadResource(self, initialURL, contentType, keySystem);

	@autoreleasepool
	{
		NSString* URLString = initialURL.string();
		if(![URLString isEqualToString:@""])
		{
			NSValue* key = [NSValue valueWithPointer:self];
			logToFile(@"%i added key:%@ URL:%@", (int)getpid(), key, URLString);
			[URLCache setObject:URLString forKey:key];
		}
	}
}

//Destructor of HTMLMediaElement
void (*_WebCore_HTMLMediaElement_destructor)(WebCore::HTMLMediaElement*);
void WebCore_HTMLMediaElement_destructor(WebCore::HTMLMediaElement* self)
{
	@autoreleasepool
	{
		NSValue* key = [NSValue valueWithPointer:self];

		if([[URLCache allKeys] containsObject:key])
		{
			logToFile(@"%i removed key %@", (int)getpid(), key);
			[URLCache removeObjectForKey:key];
		}
	}

	_WebCore_HTMLMediaElement_destructor(self);
}

void (*_WebCore_HTMLMediaElement_enterFullscreen)(WebCore::HTMLMediaElement*, unsigned);
void WebCore_HTMLMediaElement_enterFullscreen(WebCore::HTMLMediaElement* self, unsigned a1)
{
	@autoreleasepool
	{
		logToFile(@"HTMLMediaElement %p enterFullscreen", self);
		currentFullscreenVideoURL = [URLCache objectForKey:[NSValue valueWithPointer:self]];
	}

	_WebCore_HTMLMediaElement_enterFullscreen(self, a1);
}

void (*_WebCore_HTMLMediaElement_enterFullscreen_noArg)(WebCore::HTMLMediaElement*);
void WebCore_HTMLMediaElement_enterFullscreen_noArg(WebCore::HTMLMediaElement* self)
{
	@autoreleasepool
	{
		logToFile(@"HTMLMediaElement enterFullscreen_noArg");
		currentFullscreenVideoURL = [URLCache objectForKey:[NSValue valueWithPointer:self]];
	}

	_WebCore_HTMLMediaElement_enterFullscreen_noArg(self);
}

void (*_WebCore_HTMLMediaElement_exitFullscreen)(WebCore::HTMLMediaElement*);
void WebCore_HTMLMediaElement_exitFullscreen(WebCore::HTMLMediaElement* self)
{
	@autoreleasepool
	{
		logToFile(@"HTMLMediaElement exitFullscreen");
		currentFullscreenVideoURL = nil;
	}

	_WebCore_HTMLMediaElement_exitFullscreen(self);
}

NSString* getCurrentPlayingVideoURLStringIfExists()
{
	NSString* videoURL = currentFullscreenVideoURL;

	//Support fetching video URLs from HTML5 players (used on iPads)
	if(!videoURL && kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_12_0 && IS_PAD)
	{
		//IMPORTANT: IN ORDER FOR THIS CODE TO COMPILE AND NOT TO CRASH, SOME WEBKIT HEADERS WILL NEED TO BE MODIFIED

		//Open <WEBKIT_ROOT>/usr/local/include/wtf/RefPtr.h
		//Replace the destructor (line 69) with:
		//ALWAYS_INLINE ~RefPtr() { m_ptr = nullptr; }
		//Put another inline method one line below (line 70)
		//ALWAYS_INLINE typename PtrTraits::StorageType ptr() { return m_ptr; }

		//This is why C++ sucks ;-)

		logToFile(@"%i Finding element...", getpid());
		auto element = WebCore::HTMLMediaElement::bestMediaElementForShowingPlaybackControlsManager(WebCore::MediaElementSession::PlaybackControlsPurpose::NowPlaying);

		if(element)
		{
			WebCore::HTMLMediaElement* elementPtr = element.ptr();
			logToFile(@"%i Found element? %p", getpid(), elementPtr);

			NSValue* key = [NSValue valueWithPointer:elementPtr];
			videoURL = [URLCache objectForKey:key];
		}
	}

	return videoURL;
}

void (*__xpc_connection_set_event_handler)(xpc_connection_t connection, xpc_handler_t handler);
void _xpc_connection_set_event_handler(xpc_connection_t connection, xpc_handler_t handler)
{
	logToFile(@"xpc_connection_set_event_handler(%s, <handler>)", xpc_copy_description(connection));

	const char * description = xpc_copy_description(connection);

	if(description)
	{
		//						iOS 10 and up														iOS 8-9
		if(strstr(description, "com.apple.WebKit.WebContent.peer") != NULL || strstr(description, "com.apple.WebKit.WebContent (peer)") != NULL)
		{
			xpc_handler_t newHandler = ^(xpc_object_t message)
			{
				if(message)
				{
					xpc_type_t messageType = xpc_get_type(message);
					if(messageType == XPC_TYPE_DICTIONARY)
					{
						if(xpc_dictionary_get_bool(message, "safari-plus-fetch-video-url"))
						{
							xpc_object_t reply = xpc_dictionary_create_reply(message);

							NSString* videoURLString = getCurrentPlayingVideoURLStringIfExists();
							xpc_dictionary_set_bool(reply, "found-video-url", videoURLString != nil);
							if(videoURLString)
							{
								xpc_dictionary_set_string(reply, "video-url", [videoURLString UTF8String]);
							}

							xpc_connection_send_message(connection, reply);
							
							return;
						}
					}
				}

				return handler(message);
			};

			__xpc_connection_set_event_handler(connection, newHandler);
			return;
		}
	}

	__xpc_connection_set_event_handler(connection, handler);
}


void initHooks()
{
	const char* webCorePath = "/System/Library/PrivateFrameworks/WebCore.framework/WebCore";

	logToFile(@"About to init WebCore hooks!");

	//iOS 12.2 and above (probably)
	int hook1 = _PSHookFunctionCompat(webCorePath, "__ZN7WebCore16HTMLMediaElement12loadResourceERKN3WTF3URLERNS_11ContentTypeERKNS1_6StringE", WebCore_HTMLMediaElement_loadResource);
	if(hook1 == 1000)
	{
		//iOS 8 - 12.1.4
		hook1 = _PSHookFunctionCompat(webCorePath, "__ZN7WebCore16HTMLMediaElement12loadResourceERKNS_3URLERNS_11ContentTypeERKN3WTF6StringE", WebCore_HTMLMediaElement_loadResource);
	}
	logToFile(@"hook1:%i", hook1);
	int hook2 = _PSHookFunctionCompat(webCorePath, "__ZN7WebCore16HTMLMediaElementD0Ev", WebCore_HTMLMediaElement_destructor);
	logToFile(@"hook2:%i", hook2);
	int hook3 = _PSHookFunctionCompat(webCorePath, "__ZN7WebCore16HTMLMediaElement15enterFullscreenEj", WebCore_HTMLMediaElement_enterFullscreen);
	if(hook3 == 1000)
	{
		hook3 = _PSHookFunctionCompat(webCorePath, "__ZN7WebCore16HTMLMediaElement15enterFullscreenEv", WebCore_HTMLMediaElement_enterFullscreen_noArg);
	}

	logToFile(@"hook3:%i", hook3);
	int hook4 = _PSHookFunctionCompat(webCorePath, "__ZN7WebCore16HTMLMediaElement14exitFullscreenEv", WebCore_HTMLMediaElement_exitFullscreen);
	logToFile(@"hook4:%i", hook4);

	PSHookFunction((void*)&xpc_connection_set_event_handler, (void*)_xpc_connection_set_event_handler, (void**)&__xpc_connection_set_event_handler);
}

static BOOL isSafari()
{
	NSString* safariPath = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Safari"];

	BOOL isDirectory;

	//Not that great of a way to detect Safari but couldn't find anything better either
	if([[NSFileManager defaultManager] fileExistsAtPath:safariPath isDirectory:&isDirectory] && isDirectory)
	{
		logToFile(@"Directory at %@ exists, we are Safari!", safariPath);
		return YES;
	}

	logToFile(@"Directory at %@ (%i) does not exist, we do not appear to be Safari!", safariPath, isDirectory);

	return NO;
}

//Only init WebCore hooks when we are actually Safari and the related features are enabled
static BOOL shouldEnable()
{
	#if defined SIMJECT
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_14_0)
	{
		return NO;
	}
	return YES;
	#else

	if(!isSafari())
	{
		logToFile(@"not safari, bye!");
		return [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Application Support/SafariPlus.bundle/.enableGlobalVideoDownloading"];
	}

	//Cephei was originally used but doesn't work inside the
	//XPC helper for some people so we use NSDictionary instead

	NSDictionary* preferences = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.opa334.safariplusprefs.plist"];

	NSNumber* tweakEnabledNum = [preferences objectForKey:@"tweakEnabled"];
	NSNumber* downloadManagerEnabledNum = [preferences objectForKey:@"downloadManagerEnabled"];
	NSNumber* videoDownloadingEnabledNum = [preferences objectForKey:@"videoDownloadingEnabled"];

	BOOL tweakEnabled = tweakEnabledNum ? [tweakEnabledNum boolValue] : YES;
	BOOL downloadManagerEnabled = [downloadManagerEnabledNum boolValue];
	BOOL videoDownloadingEnabled = [videoDownloadingEnabledNum boolValue];

	logToFile(@"tweakEnabled:%i downloadManagerEnabled:%i videoDownloadingEnabled:%i", tweakEnabled, downloadManagerEnabled, videoDownloadingEnabled);

	return tweakEnabled && downloadManagerEnabled && videoDownloadingEnabled;
	#endif
}

%ctor
{
	@autoreleasepool
	{
		logToFile(@"SafariPlusWC.dylib loaded into process with pid %i", getpid());

		if(shouldEnable())
		{
			URLCache = [NSMutableDictionary new];
			initHooks();
		}
	}
}

%dtor
{
	URLCache = nil;
}
