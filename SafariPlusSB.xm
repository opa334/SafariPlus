//  SafariPlusSB.xm
// (c) 2017 opa334

#import <RocketBootstrap/rocketbootstrap.h>
#import <AppSupport/CPDistributedMessagingCenter.h>

@interface JBBulletinManager : NSObject
+ (id)sharedInstance;
- (id)showBulletinWithTitle:(NSString *)title message:(NSString *)message bundleID:(NSString *)bundleID;
@end

%hook SpringBoard

//Use rocketbootstrap to recieve messages through CPDistributedMessagingCenter
- (id)init
{
  id orig = %orig;

  CPDistributedMessagingCenter* SPMessagingCenter =
    [%c(CPDistributedMessagingCenter)
    centerNamed:@"com.opa334.SafariPlus.MessagingCenter"];

  rocketbootstrap_distributedmessagingcenter_apply(SPMessagingCenter);

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
