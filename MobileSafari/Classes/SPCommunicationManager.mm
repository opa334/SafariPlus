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

#import "SPCommunicationManager.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import "../Util.h"
#import "SPFileManager.h"

#ifndef NO_ROCKETBOOTSTRAP
#import <rocketbootstrap/rocketbootstrap.h>
#endif

#include <sys/types.h>

@implementation SPCommunicationManager

+ (instancetype)sharedInstance
{
	static SPCommunicationManager* sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^
	{
		//Initialise instance
		sharedInstance = [[SPCommunicationManager alloc] init];
	});

	return sharedInstance;
}

- (instancetype)init
{
	self = [super init];

	_messagingCenter = [NSClassFromString(@"CPDistributedMessagingCenter") centerNamed:@"com.opa334.SafariPlus.MessagingCenter"];

  #ifndef NO_ROCKETBOOTSTRAP
	rocketbootstrap_distributedmessagingcenter_apply(_messagingCenter);
  #endif

	return self;
}

#ifndef NO_ROCKETBOOTSTRAP

//Check if communication with SpringBoard works
- (BOOL)testConnection
{
	NSDictionary* userInfo = @{@"message" : @"hello"};
	NSDictionary* response = [_messagingCenter sendMessageAndReceiveReplyName:@"com.opa334.SafariPlus.testConnection" userInfo:userInfo];

	return [[response objectForKey:@"message"] isEqualToString:@"hello"];
}

//Executes file operation unsandboxed via SpringBoard
- (NSDictionary*)executeFileOperationOnSpringBoard:(NSDictionary*)operation
{
	//Serialize operation so we pass any object we want (NSURLs would cause a crash otherwise)
	NSData* serializedOperation = [NSKeyedArchiver archivedDataWithRootObject:operation];
	NSDictionary* operationDict = @{@"data" : serializedOperation};

	NSDictionary* serializedResponse = [_messagingCenter sendMessageAndReceiveReplyName:@"com.opa334.SafariPlus.fileOperation" userInfo:operationDict];

	NSDictionary* response = [NSKeyedUnarchiver unarchiveObjectWithData:[serializedResponse objectForKey:@"data"]];

	return response;
}

- (NSDictionary*)applicationDisplayNamesForPaths
{
	return [_messagingCenter sendMessageAndReceiveReplyName:@"com.opa334.SafariPlus.getApplicationDisplayNames" userInfo:nil];
}

#else

- (BOOL)testConnection
{
	return YES;
}

- (void)dispatchPushNotificationWithTitle:(NSString*)title message:(NSString*)message badgeCount:(NSInteger)badgeCount
{

}

- (NSDictionary*)executeFileOperationOnSpringBoard:(NSDictionary*)operation
{
	return nil;
}

- (NSDictionary*)applicationDisplayNamesForPaths
{
	return nil;
}

#endif

@end
