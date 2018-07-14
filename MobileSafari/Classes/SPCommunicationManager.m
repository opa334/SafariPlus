// SPCommunicationManager.m
// (c) 2017 opa334

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

#if !defined(SIMJECT)
#import <RocketBootstrap/rocketbootstrap.h>
#endif

#include <sys/types.h>

@implementation SPCommunicationManager

+ (instancetype)sharedInstance
{
    static SPCommunicationManager* sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,
    ^{
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

- (void)dispatchPushNotificationWithIdentifier:(NSString*)bundleIdentifier title:(NSString*)title message:(NSString*)message
{
  //Create userInfo to send to SpringBoard
  NSDictionary* userInfo =
  @{
    @"bundleIdentifier" : bundleIdentifier,
    @"title"            : title,
    @"message"          : message
  };

  //Send userInfo to SpringBoard using RocketBootstrap
  //There it gets dispatched using libbulletin
  [_messagingCenter sendMessageName:@"com.opa334.SafariPlus.pushNotification" userInfo:userInfo];
}

- (id)executeFileOperationOnSpringBoard:(NSDictionary*)operation
{
	NSDictionary* reply = [_messagingCenter sendMessageAndReceiveReplyName:@"com.opa334.SafariPlus.fileOperation" userInfo:operation];

	return reply;
}

@end
