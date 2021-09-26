#import "SBSPDistributedMessagingCenter.h"
#import "../../MobileSafari/Defines.h"

extern "C"
{
	CFStringRef SecTaskCopySigningIdentifier(struct __SecTask* task, CFErrorRef* error);
	struct __SecTask* SecTaskCreateWithAuditToken(CFAllocatorRef allocator, audit_token_t token);
}

@implementation SBSPDistributedMessagingCenter

// ignore all messages that don't come from MobileSafari (security reasons)
- (void)_dispatchMessageNamed:(id)arg1 userInfo:(id)arg2 reply:(id*)arg3 auditToken:(audit_token_t*)auditToken
{
	struct __SecTask* secTask = SecTaskCreateWithAuditToken(NULL, *auditToken);
	NSString* signingIdentifier = (__bridge_transfer NSString*)SecTaskCopySigningIdentifier(secTask, NULL);
	CFRelease(secTask);

	HBLogDebugWeak(@"signingIdentifier = %@", signingIdentifier);

	if([signingIdentifier isEqualToString:@"com.apple.mobilesafari"])
	{
		return [super _dispatchMessageNamed:arg1 userInfo:arg2 reply:arg3 auditToken:auditToken];
	}
}

@end