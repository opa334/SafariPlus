// SPSBReceiver.mm
// (c) 2017 - 2019 opa334

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

#import "SPSBReceiver.h"

#import "../SafariPlusSB.h"
#import "../../MobileSafari/Enums.h"
#import "../../MobileSafari/Defines.h"
#import "../../Shared/SPFile.h"
#import "../../Shared/NSFileManager+DirectorySize.h"

#import <AVFoundation/AVFoundation.h>

#include <dlfcn.h>

@implementation SPSBReceiver

- (instancetype)init
{
	self = [super init];

	_messagingCenter = [NSClassFromString(@"CPDistributedMessagingCenter") centerNamed:@"com.opa334.SafariPlus.MessagingCenter"];
	rocketbootstrap_distributedmessagingcenter_apply(_messagingCenter);

	[_messagingCenter runServerOnCurrentThread];

	[_messagingCenter registerForMessageName:@"com.opa334.SafariPlus.testConnection" target:self
	 selector:@selector(testConnection:withUserInfo:)];

	[_messagingCenter registerForMessageName:@"com.opa334.SafariPlus.fileOperation" target:self
	 selector:@selector(handleFileOperation:withUserInfo:)];

	[_messagingCenter registerForMessageName:@"com.opa334.SafariPlus.getApplicationDisplayNames" target:self
	 selector:@selector(getApplicationDisplayNames:withUserInfo:)];

	return self;
}

- (NSDictionary*)testConnection:(NSString*)name withUserInfo:(NSDictionary*)userInfo
{
	return userInfo;
}

//Calls NSFileManager to execute the passed file operation
//Safari is sandboxed on modern kppless jailbreaks (Electra / unc0ver), SpringBoard isn't. Therefore we let it do all of the file related operations.
- (NSDictionary*)handleFileOperation:(NSString*)name withUserInfo:(NSDictionary*)serializedUserInfo
{
	NSDictionary* userInfo = [NSKeyedUnarchiver unarchiveObjectWithData:[serializedUserInfo objectForKey:@"data"]];

	NSInteger operationType = [[userInfo objectForKey:@"operationType"] intValue];

	NSFileManager* fileManager = [NSFileManager defaultManager];

	id ret;
	NSError* error;
	NSMutableDictionary* retDict = [NSMutableDictionary new];

	@try
	{
		switch(operationType)
		{
		case FileOperation_DirectoryContents:
		{
			ret = [fileManager contentsOfDirectoryAtPath:[userInfo objectForKey:@"path"] error:&error];
			break;
		}
		case FileOperation_DirectoryContents_URL:
		{
			ret = [fileManager contentsOfDirectoryAtURL:[userInfo objectForKey:@"url"] includingPropertiesForKeys:[userInfo objectForKey:@"keys"] options:[[userInfo objectForKey:@"mask"] intValue] error:&error];
			break;
		}
		case FileOperation_DirectoryContents_SPFile:
		{
			ret = [SPFile filesAtURL:[userInfo objectForKey:@"url"] error:&error];
			break;
		}
		case FileOperation_CreateDirectory:
		{
			ret = [NSNumber numberWithBool:[fileManager createDirectoryAtPath:[userInfo objectForKey:@"path"] withIntermediateDirectories:[[userInfo objectForKey:@"createIntermediates"] boolValue] attributes:[userInfo objectForKey:@"attributes"] error:&error]];
			break;
		}
		case FileOperation_CreateDirectory_URL:
		{
			ret = [NSNumber numberWithBool:[fileManager createDirectoryAtURL:[userInfo objectForKey:@"url"] withIntermediateDirectories:[[userInfo objectForKey:@"createIntermediates"] boolValue] attributes:[userInfo objectForKey:@"attributes"] error:&error]];
			break;
		}
		case FileOperation_MoveItem:
		{
			ret = [NSNumber numberWithBool:[fileManager moveItemAtPath:[userInfo objectForKey:@"srcPath"] toPath:[userInfo objectForKey:@"dstPath"] error:&error]];
			break;
		}
		case FileOperation_MoveItem_URL:
		{
			ret = [NSNumber numberWithBool:[fileManager moveItemAtURL:[userInfo objectForKey:@"srcURL"] toURL:[userInfo objectForKey:@"dstURL"] error:&error]];
			break;
		}
		case FileOperation_RemoveItem:
		{
			ret = [NSNumber numberWithBool:[fileManager removeItemAtPath:[userInfo objectForKey:@"path"] error:&error]];
			break;
		}
		case FileOperation_RemoveItem_URL:
		{
			ret = [NSNumber numberWithBool:[fileManager removeItemAtURL:[userInfo objectForKey:@"URL"] error:&error]];
			break;
		}
		case FileOperation_CopyItem:
		{
			ret = [NSNumber numberWithBool:[fileManager copyItemAtPath:[userInfo objectForKey:@"srcPath"] toPath:[userInfo objectForKey:@"dstPath"] error:&error]];
			break;
		}
		case FileOperation_CopyItem_URL:
		{
			ret = [NSNumber numberWithBool:[fileManager copyItemAtURL:[userInfo objectForKey:@"srcURL"] toURL:[userInfo objectForKey:@"dstURL"] error:&error]];
			break;
		}
		case FileOperation_LinkItem:
		{
			ret = [NSNumber numberWithBool:[fileManager linkItemAtPath:[userInfo objectForKey:@"srcPath"] toPath:[userInfo objectForKey:@"dstPath"] error:&error]];
			break;
		}
		case FileOperation_LinkItem_URL:
		{
			ret = [NSNumber numberWithBool:[fileManager linkItemAtURL:[userInfo objectForKey:@"srcURL"] toURL:[userInfo objectForKey:@"dstURL"] error:&error]];
			break;
		}
		case FileOperation_FileExists:
		{
			ret = [NSNumber numberWithBool:[fileManager fileExistsAtPath:[userInfo objectForKey:@"path"]]];
			break;
		}
		case FileOperation_FileExists_URL:
		{
			ret = [NSNumber numberWithBool:[((NSURL*)[userInfo objectForKey:@"url"]) checkResourceIsReachableAndReturnError:&error]];
			break;
		}
		case FileOperation_FileExists_IsDirectory:
		{
			BOOL isDirectory;
			ret = [NSNumber numberWithBool:[fileManager fileExistsAtPath:[userInfo objectForKey:@"path"] isDirectory:&isDirectory]];
			[retDict setObject:[NSNumber numberWithBool:isDirectory] forKey:@"isDirectory"];
			break;
		}
		case FileOperation_IsDirectory_URL:
		{
			[((NSURL*)[userInfo objectForKey:@"url"]) getResourceValue:&ret forKey:NSURLIsDirectoryKey error:&error];
			break;
		}
		case FileOperation_Attributes:
		{
			ret = [fileManager attributesOfItemAtPath:[userInfo objectForKey:@"path"] error:&error];
			break;
		}
		case FileOperation_ResourceValue_URL:
		{
			id value;

			id key = [userInfo objectForKey:@"key"];

			[((NSURL*)[userInfo objectForKey:@"url"]) getResourceValue:&value forKey:key error:&error];

			if(value)
			{
				[retDict setValue:value forKey:@"value"];
			}

			break;
		}
		case FileOperation_IsWritable:
		{
			ret = [NSNumber numberWithBool:[fileManager isWritableFileAtPath:[userInfo objectForKey:@"path"]]];
			break;
		}
		case FileOperation_ResolveSymlinks:
		{
			ret = ((NSString*)[userInfo objectForKey:@"path"]).stringByResolvingSymlinksInPath;
			break;
		}
		case FileOperation_ResolveSymlinks_URL:
		{
			ret = ((NSURL*)[userInfo objectForKey:@"url"]).URLByResolvingSymlinksInPath;
			break;
		}
		case FileOperation_DirectorySize_URL:
		{
			ret = [NSNumber numberWithUnsignedInteger:[fileManager sizeOfDirectoryAtURL:[userInfo objectForKey:@"url"]]];
			break;
		}
		}
	}
	@catch(NSException* exception)
	{
		NSLog(@"prevented crash with exception %@", exception);
		[retDict setObject:exception forKey:@"exception"];
	}

	if(error)
	{
		[retDict setObject:error forKey:@"error"];
	}

	if(ret)
	{
		[retDict setObject:ret forKey:@"return"];
	}

	NSData* retData = [NSKeyedArchiver archivedDataWithRootObject:retDict];

	NSDictionary* serializedRetDict = @{@"data" : retData};

	return serializedRetDict;
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

@end
