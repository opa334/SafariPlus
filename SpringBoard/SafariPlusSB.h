// SafariPlusSB.h
// (c) 2017 opa334

#ifndef SIMJECT
#import <RocketBootstrap/rocketbootstrap.h>
#endif
#import <AppSupport/CPDistributedMessagingCenter.h>

@interface JBBulletinManager : NSObject
+ (id)sharedInstance;
- (id)showBulletinWithTitle:(NSString *)title message:(NSString *)message bundleID:(NSString *)bundleID;
@end
