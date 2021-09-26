#import <AppSupport/CPDistributedMessagingCenter.h>

@interface CPDistributedMessagingCenter (Private)
-(void)_dispatchMessageNamed:(id)arg1 userInfo:(id)arg2 reply:(id*)arg3 auditToken:(audit_token_t*)arg4;
@end

@interface SBSPDistributedMessagingCenter : CPDistributedMessagingCenter
@end