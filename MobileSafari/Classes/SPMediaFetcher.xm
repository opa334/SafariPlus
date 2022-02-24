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

#import "../Util.h"
#import "../Defines.h"
#import "SPFileManager.h"
#import "SPMediaFetcher.h"
#import "../SafariPlus.h"
#import <xpc/xpc.h> // stolen from xpc service theos template, if this errors out you need to get the xpc headers from the template too and move them into $(THEOS)/include
#import "SPPreferenceManager.h"

%group VideoURLFetch

%hookf(void, xpc_connection_send_message_with_reply, xpc_connection_t connection, xpc_object_t message, dispatch_queue_t replyq, xpc_handler_t handler)
{
	const char* name = xpc_connection_get_name(connection);

	if(name)
	{
		if(strstr(name, "com.apple.WebKit.WebContent") != NULL)
		{
			xpc_type_t messageType = xpc_get_type(message);
			if(messageType == XPC_TYPE_DICTIONARY)
			{
				const char* messageName = xpc_dictionary_get_string(message, "message-name");
				if(messageName)
				{
					if(strcmp(messageName, "bootstrap") == 0)
					{
						xpc_handler_t newHandler = ^(xpc_object_t object)
						{
							handler(object);

							pid_t pid = xpc_connection_get_pid(connection);
							if(pid != 0)
							{
								[[SPMediaFetcher sharedFetcher] cache_setConnection:connection forPid:pid];
							}
						};

						%orig(connection, message, replyq, newHandler);

						return;
					}
				}
			}	
		}
	}
	
	return %orig;
}

%end

@implementation SPMediaFetcher

+ (instancetype)sharedFetcher
{
	static SPMediaFetcher* sharedInstance = nil;
	static dispatch_once_t onceToken;
    dispatch_once (&onceToken, ^{
        sharedInstance = [[SPMediaFetcher alloc] init];
    });
	return sharedInstance;
}

- (instancetype)init
{
	self = [super init];

	_connectionsByPid = [NSMutableDictionary new];

	return self;
}

- (void)cache_removeDeadConnections
{
	[_connectionsByPid enumerateKeysAndObjectsUsingBlock:^(NSNumber* pidNum, xpc_connection_t connection, BOOL *stop)
	{
		if(xpc_connection_get_pid(connection) == 0)
		{
			HBLogDebugWeak(@"removing dead connection %@/%@", pidNum, connection);
			[_connectionsByPid removeObjectForKey:pidNum];
		}
	}];
}

- (void)cache_setConnection:(xpc_connection_t)connection forPid:(pid_t)pid
{
	if(pid == 0 || !connection)
	{
		return;
	}

	HBLogDebugWeak(@"cache_setConnection:%s forPid:%i", xpc_copy_description(connection), pid);

	NSNumber* pidNum = [NSNumber numberWithInt:pid];
	[_connectionsByPid setObject:connection forKey:pidNum];
	[self cache_removeDeadConnections];
}

- (xpc_connection_t)cache_getConnectionForPid:(pid_t)pid
{
	if(pid == 0)
	{
		return nil;
	}

	[self cache_removeDeadConnections];

	NSNumber* pidNum = [NSNumber numberWithInt:pid];	
	return [_connectionsByPid objectForKey:pidNum];
}

- (void)getURLForPlayingMediaOfTabDocument:(TabDocument*)tabDocument withCompletionHandler:(void (^)(NSURL* URL))completionHandler
{
	xpc_object_t fetchMessage = xpc_dictionary_create(NULL,NULL,0);
	xpc_dictionary_set_bool(fetchMessage, "safari-plus-fetch-video-url", YES);

	// pretend to be sending a normal pre-bootstrap message so WebContent doesn't crash in the case where the WebContent hooks don't work for some reason
	xpc_dictionary_set_string(fetchMessage, "message-name", "pre-bootstrap");

	// When WebContent injection is broken, it will never respond to our messages so we need to timeout after one second
	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void)
	{
		intptr_t failed = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC));
		if(failed != 0)
		{
			completionHandler(nil);
		}
	});

	pid_t pid = tabDocument.webView._webProcessIdentifier;
	xpc_connection_t connection = [self cache_getConnectionForPid:pid];

	xpc_connection_send_message_with_reply(connection, fetchMessage, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(xpc_object_t reply)
	{
		if(reply)
		{
			xpc_type_t replyType = xpc_get_type(reply);

			if(replyType == XPC_TYPE_DICTIONARY)
			{
				if(xpc_dictionary_get_bool(reply, "found-video-url"))
				{
					const char* URLCString = xpc_dictionary_get_string(reply, "video-url");
					if(URLCString)
					{
						NSString* URLString = [NSString stringWithUTF8String:URLCString];
						NSURL* URL = [NSURL URLWithString:URLString];

						dispatch_semaphore_signal(semaphore);
						completionHandler(URL);
					}
				}
			}
		}
	});
}

@end

void initSPMediaFetcher()
{
	if(preferenceManager.downloadManagerEnabled && preferenceManager.videoDownloadingEnabled)
	{
		%init(VideoURLFetch);
	}
}