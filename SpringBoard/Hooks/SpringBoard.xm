// SpringBoard.xm
// (c) 2018 opa334

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

#import "../SafariPlusSB.h"
#import "../../MobileSafari/Enums.h"

//Parse empty strings to nil
id pS(id object)
{
  if([object isKindOfClass:[NSString class]])
  {
    if([object isEqualToString:@""])
    {
      return nil;
    }
  }

  return object;
}

NSArray<NSURL*>* parseURLs(NSArray<NSString*>* URLs)
{
  NSMutableArray* paths = [NSMutableArray new];

  for(NSURL* URL in URLs)
  {
    if([URL isKindOfClass:[NSURL class]])
    {
      [paths addObject:[URL path]];
    }
  }

  return [paths copy];
}

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

  [SPMessagingCenter registerForMessageName:@"com.opa334.SafariPlus.pushNotification" target:self
    selector:@selector(receivedPushNotifiation:withUserInfo:)];

  [SPMessagingCenter registerForMessageName:@"com.opa334.SafariPlus.fileOperation" target:self
    selector:@selector(handleFileOperation:withUserInfo:)];

  return orig;
}

//Dispatch push notification (bulletin) through libbulletin
%new
- (NSDictionary*)receivedPushNotifiation:(NSString*)name withUserInfo:(NSDictionary*)userInfo
{
  [[objc_getClass("JBBulletinManager") sharedInstance]
    showBulletinWithTitle:[userInfo objectForKey:@"title"]
    message:[userInfo objectForKey:@"message"]
    bundleID:[userInfo objectForKey:@"bundleIdentifier"]];

  return nil;
}

//Calls NSFileManager to execute the passed file operation
//Safari is sandboxed on Electra, SpringBoard isn't. Therefore we let it do all of the file related operations.
//NOTE: Does not support errors (yet?)
%new
- (NSDictionary*)handleFileOperation:(NSString*)name withUserInfo:(NSDictionary*)userInfo
{
	NSInteger operationType = [[userInfo objectForKey:@"operationType"] intValue];

	NSFileManager* fileManager = [NSFileManager defaultManager];

	id ret;
	NSMutableDictionary* retDict = [NSMutableDictionary new];

	switch(operationType)
	{
		case FileOperation_DirectoryContents:
		{
			ret = [fileManager contentsOfDirectoryAtPath:pS([userInfo objectForKey:@"path"]) error:nil];
      break;
		}
		case FileOperation_DirectoryContents_URL:
		{
			ret = [fileManager contentsOfDirectoryAtURL:[NSURL fileURLWithPath:pS([userInfo objectForKey:@"url"])] includingPropertiesForKeys:pS([userInfo objectForKey:@"keys"]) options:[pS([userInfo objectForKey:@"mask"]) intValue] error:nil];
      ret = parseURLs(ret);
      break;
		}
		case FileOperation_CreateDirectory:
		{
			ret = [NSNumber numberWithBool:[fileManager createDirectoryAtPath:pS([userInfo objectForKey:@"path"]) withIntermediateDirectories:[pS([userInfo objectForKey:@"createIntermediates"]) boolValue] attributes:pS([userInfo objectForKey:@"attributes"]) error:nil]];
      break;
		}
		case FileOperation_CreateDirectory_URL:
		{
			ret = [NSNumber numberWithBool:[fileManager createDirectoryAtURL:[NSURL fileURLWithPath:pS([userInfo objectForKey:@"url"])] withIntermediateDirectories:[pS([userInfo objectForKey:@"createIntermediates"]) boolValue] attributes:pS([userInfo objectForKey:@"attributes"]) error:nil]];
      break;
		}
		case FileOperation_MoveItem:
		{
			ret = [NSNumber numberWithBool:[fileManager moveItemAtPath:pS([userInfo objectForKey:@"srcPath"]) toPath:pS([userInfo objectForKey:@"dstPath"]) error:nil]];
      break;
		}
		case FileOperation_MoveItem_URL:
		{
			ret = [NSNumber numberWithBool:[fileManager moveItemAtURL:[NSURL fileURLWithPath:pS([userInfo objectForKey:@"srcURL"])] toURL:[NSURL fileURLWithPath:pS([userInfo objectForKey:@"dstURL"])] error:nil]];
      break;
		}
		case FileOperation_RemoveItem:
		{
			ret = [NSNumber numberWithBool:[fileManager removeItemAtPath:pS([userInfo objectForKey:@"path"]) error:nil]];
      break;
		}
		case FileOperation_RemoveItem_URL:
		{
			ret = [NSNumber numberWithBool:[fileManager removeItemAtURL:[NSURL fileURLWithPath:pS([userInfo objectForKey:@"URL"])] error:nil]];
      break;
		}
		case FileOperation_LinkItem:
		{
			ret = [NSNumber numberWithBool:[fileManager linkItemAtPath:pS([userInfo objectForKey:@"srcPath"]) toPath:pS([userInfo objectForKey:@"dstPath"]) error:nil]];
      break;
		}
		case FileOperation_LinkItem_URL:
		{
			ret = [NSNumber numberWithBool:[fileManager linkItemAtURL:[NSURL fileURLWithPath:pS([userInfo objectForKey:@"srcURL"])] toURL:[NSURL fileURLWithPath:pS([userInfo objectForKey:@"dstURL"])] error:nil]];
      break;
		}
		case FileOperation_FileExists:
		{
			ret = [NSNumber numberWithBool:[fileManager fileExistsAtPath:pS([userInfo objectForKey:@"path"])]];
      break;
		}
		case FileOperation_FileExists_isDirectory:
		{
			BOOL isDirectory;
			ret = [NSNumber numberWithBool:[fileManager fileExistsAtPath:pS([userInfo objectForKey:@"path"]) isDirectory:&isDirectory]];
			[retDict setObject:[NSNumber numberWithBool:isDirectory] forKey:@"isDirectory"];
      break;
		}
		case FileOperation_Attributes:
		{
			ret = [fileManager attributesOfItemAtPath:pS([userInfo objectForKey:@"path"]) error:nil];
      break;
		}
    case FileOperation_IsWritable:
    {
      ret = [NSNumber numberWithBool:[fileManager isWritableFileAtPath:pS([userInfo objectForKey:@"path"])]];
      break;
    }
    case FileOperation_ResolveSymlinks:
    {
      ret = ((NSString*)pS([userInfo objectForKey:@"path"])).stringByResolvingSymlinksInPath;
      break;
    }
	}

  if(ret)
  {
    [retDict setObject:ret forKey:@"return"];
  }

	return retDict;
}

%end
