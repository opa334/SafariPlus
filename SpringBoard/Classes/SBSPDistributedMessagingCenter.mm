#import "SBSPDistributedMessagingCenter.h"
#import "../../MobileSafari/Defines.h"

extern "C"
{
	CFStringRef SecTaskCopySigningIdentifier(struct __SecTask* task, CFErrorRef* error);
	struct __SecTask* SecTaskCreateWithAuditToken(CFAllocatorRef allocator, audit_token_t token);
}

@implementation SBSPDistributedMessagingCenter

// ignore all messages that don't come from MobileSafari (security reasons)
- (void)_dispatchMessageNamed:(NSString*)messageName userInfo:(NSDictionary*)userInfo reply:(NSDictionary**)reply auditToken:(audit_token_t*)auditToken
{
	struct __SecTask* secTask = SecTaskCreateWithAuditToken(NULL, *auditToken);
	NSString* signingIdentifier = (__bridge_transfer NSString*)SecTaskCopySigningIdentifier(secTask, NULL);
	CFRelease(secTask);

	HBLogDebugWeak(@"signingIdentifier = %@", signingIdentifier);

	if([signingIdentifier isEqualToString:@"com.apple.mobilesafari"])
	{
		if([messageName isEqualToString:@"com.opa334.SafariPlus.getSandboxExtension"])
		{
			NSValue* auditTokenValue = [NSValue valueWithPointer:(void*)auditToken];
			NSMutableDictionary* userInfoM = userInfo.mutableCopy ?: [NSMutableDictionary new];
			userInfoM[@"auditToken"] = auditTokenValue;
			return [super _dispatchMessageNamed:messageName userInfo:userInfoM reply:reply auditToken:auditToken];
		}
		else
		{
			return [super _dispatchMessageNamed:messageName userInfo:userInfo reply:reply auditToken:auditToken];
		}
	}
}

@end