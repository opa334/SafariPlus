// SpringBoard.xm
// (c) 2017 opa334

#import "../SafariPlusSB.h"

%hook SpringBoard

//Use rocketbootstrap to recieve messages through CPDistributedMessagingCenter
- (id)init
{
  id orig = %orig;

  CPDistributedMessagingCenter* SPMessagingCenter =
    [%c(CPDistributedMessagingCenter)
    centerNamed:@"com.opa334.SafariPlus.MessagingCenter"];

  #ifndef SIMJECT
  rocketbootstrap_distributedmessagingcenter_apply(SPMessagingCenter);
  #endif

	[SPMessagingCenter runServerOnCurrentThread];

  [SPMessagingCenter registerForMessageName:@"pushNotification" target:self
    selector:@selector(recieveMessageNamed:withData:)];

  return orig;
}

//Dispatch push notification (bulletin) through libbulletin
%new
- (NSDictionary *)recieveMessageNamed:(NSString *)name withData:(NSDictionary *)data
{
  [[objc_getClass("JBBulletinManager") sharedInstance]
    showBulletinWithTitle:[data objectForKey:@"title"]
    message:[data objectForKey:@"message"]
    bundleID:[data objectForKey:@"bundleID"]];

	return nil;
}

%end
