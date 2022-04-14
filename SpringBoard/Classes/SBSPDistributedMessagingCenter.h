#import <AppSupport/CPDistributedMessagingCenter.h>

@interface CPDistributedMessagingCenter (Private)
- (void)_dispatchMessageNamed:(NSString*)messageName userInfo:(NSDictionary*)userInfo reply:(NSDictionary**)reply auditToken:(audit_token_t*)auditToken;
@end

@interface SBSPDistributedMessagingCenter : CPDistributedMessagingCenter
@end