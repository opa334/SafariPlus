// Copyright (c) 2017-2022 Lars Fröder

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

#import "SPSBReceiver.h"

#import "../SafariPlusSB.h"
#import "../../MobileSafari/Enums.h"
#import "../../MobileSafari/Defines.h"
#import "../../Shared/SPFile.h"
#import "../../Shared/NSFileManager+DirectorySize.h"
#import <dlfcn.h>

#import <AVFoundation/AVFoundation.h>

#include <dlfcn.h>

char* (*sandbox_extension_issue_file_to_process)(const char *extension_class, const char *path, uint32_t flags, audit_token_t);
char* (*sandbox_extension_issue_file)(const char *ext, const char *path, int reserved, int flags);

extern "C"
{
	extern const char *const APP_SANDBOX_READ;
	extern const char *const APP_SANDBOX_READ_WRITE;
}

@implementation SPSBReceiver

- (instancetype)init
{
	self = [super init];

	_messagingCenter = [SBSPDistributedMessagingCenter centerNamed:@"com.opa334.SafariPlus.MessagingCenter"];
	rocketbootstrap_distributedmessagingcenter_apply(_messagingCenter);

	[_messagingCenter runServerOnCurrentThread];

	[_messagingCenter registerForMessageName:@"com.opa334.SafariPlus.testConnection" target:self
	 selector:@selector(testConnection:withUserInfo:)];

	[_messagingCenter registerForMessageName:@"com.opa334.SafariPlus.fileOperation" target:self
	 selector:@selector(handleFileOperation:withUserInfo:)];

	[_messagingCenter registerForMessageName:@"com.opa334.SafariPlus.getApplicationDisplayNames" target:self
	 selector:@selector(getApplicationDisplayNames:withUserInfo:)];

	[_messagingCenter registerForMessageName:@"com.opa334.SafariPlus.getSandboxExtension" target:self
	 selector:@selector(getSandboxExtension:withUserInfo:)];

	return self;
}

- (NSDictionary*)testConnection:(NSString*)name withUserInfo:(NSDictionary*)userInfo
{
	return userInfo;
}

//Returns a dictionary with display names with the paths being the keys
- (NSDictionary*)getApplicationDisplayNames:(NSString*)name withUserInfo:(NSDictionary*)userInfo
{
	NSMutableDictionary* displayNamesForPaths = [NSMutableDictionary new];

	for(SBApplication* app in [[NSClassFromString(@"SBApplicationController") sharedInstance] allApplications])
	{
		SBApplicationInfo* appInfo;

		if([app respondsToSelector:@selector(info)])
		{
			appInfo = app.info;
		}
		else
		{
			appInfo = [app _appInfo];
		}

		NSString* currentDisplayName = appInfo.displayName;

		if(currentDisplayName)
		{
			NSString* currentSandboxPath = appInfo.sandboxURL.path;
			NSString* currentBundleContainerPath = appInfo.bundleContainerURL.path;

			if(currentSandboxPath)
			{
				[displayNamesForPaths setObject:currentDisplayName forKey:currentSandboxPath];
			}

			if(currentBundleContainerPath)
			{
				[displayNamesForPaths setObject:currentDisplayName forKey:currentBundleContainerPath];
			}
		}
	}

	return [displayNamesForPaths copy];
}

- (NSDictionary*)getSandboxExtension:(NSString*)name withUserInfo:(NSDictionary*)userInfo
{
	NSUserDefaults* safariPlusDefaults = [[NSUserDefaults alloc] initWithSuiteName:PREFERENCE_DOMAIN_NAME];
	NSNumber* unsandboxSafariEnabledNum = [safariPlusDefaults objectForKey:@"unsandboxSafariEnabled"];
	BOOL unsandboxSafariEnabled = unsandboxSafariEnabledNum ? unsandboxSafariEnabledNum.boolValue : YES;
	if(unsandboxSafariEnabled)
	{
		NSValue* auditTokenValue = userInfo[@"auditToken"];
		audit_token_t* auditToken = (audit_token_t*)[auditTokenValue pointerValue];

		char* varWriteExtension = NULL;
		char* rootReadExtension = NULL;
		if(sandbox_extension_issue_file_to_process)
		{
			varWriteExtension = sandbox_extension_issue_file_to_process(APP_SANDBOX_READ_WRITE, "/var", 0, *auditToken);
			rootReadExtension = sandbox_extension_issue_file_to_process(APP_SANDBOX_READ, "/", 0, *auditToken);
		}
		else
		{
			varWriteExtension = sandbox_extension_issue_file(APP_SANDBOX_READ_WRITE, "/var", 0, 0);
			rootReadExtension = sandbox_extension_issue_file(APP_SANDBOX_READ, "/", 0, 0);
		}

		if(varWriteExtension && rootReadExtension)
		{
			HBLogDebugWeak(@"varWriteExtension: %s", varWriteExtension);
			HBLogDebugWeak(@"rootReadExtension: %s", rootReadExtension);
			NSString* nsVarWriteExtension = [NSString stringWithUTF8String:varWriteExtension];
			NSString* nsRootReadExtension = [NSString stringWithUTF8String:rootReadExtension];
			return @{ @"varWriteExtension" : nsVarWriteExtension, @"rootReadExtension" : nsRootReadExtension};
		}
	}

	return nil;
}

@end

void initReceiver()
{
	void* libSystemSandboxHandle = dlopen("/usr/lib/system/libsystem_sandbox.dylib", RTLD_NOW);
	sandbox_extension_issue_file_to_process = (char *(*)(const char *, const char *, uint32_t, audit_token_t))dlsym(libSystemSandboxHandle, "sandbox_extension_issue_file_to_process");
	sandbox_extension_issue_file = (char *(*)(const char *, const char *, int, int))dlsym(libSystemSandboxHandle, "sandbox_extension_issue_file");
}