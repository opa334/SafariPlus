// SPCommunicationManager.mm
// (c) 2018 opa334

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

#import "SPCommunicationManager.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import "../Shared.h"
#import "SPFileManager.h"

#if !defined(SIMJECT)
#import <RocketBootstrap/rocketbootstrap.h>
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

  #if !defined(SIMJECT)
	rocketbootstrap_distributedmessagingcenter_apply(_messagingCenter);
  #endif

	return self;
}

#if !defined(SIMJECT)

//Check if communication with SpringBoard works
- (BOOL)testConnection
{
	NSDictionary* userInfo = @{@"message" : @"hello"};
	NSDictionary* response = [_messagingCenter sendMessageAndReceiveReplyName:@"com.opa334.SafariPlus.testConnection" userInfo:userInfo];

	return [[response objectForKey:@"message"] isEqualToString:@"hello"];
}

//Dispatch libbulletin notification via SpringBoard
- (void)dispatchPushNotificationWithIdentifier:(NSString*)bundleIdentifier title:(NSString*)title message:(NSString*)message
{
	//Create userInfo to send to SpringBoard
	NSDictionary* userInfo =
		@{
			@"bundleIdentifier" : bundleIdentifier,
			@"title"            : title,
			@"message"          : message
	};

	[_messagingCenter sendMessageName:@"com.opa334.SafariPlus.pushNotification" userInfo:userInfo];
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

- (void)dispatchPushNotificationWithIdentifier:(NSString*)bundleIdentifier title:(NSString*)title message:(NSString*)message
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
