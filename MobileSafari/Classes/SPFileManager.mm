// SPFileManager.mm
// (c) 2019 opa334

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

#import "SPFileManager.h"

#ifndef PREFERENCES
#import "SPCommunicationManager.h"
#endif

#import "../SafariPlus.h"
#import "../Defines.h"
#import "../Util.h"
#import "../Enums.h"

#ifndef PREFERENCES

//Wrapper around executeFileOperationOnSpringBoard that simplifies error handling
NSDictionary* execute(NSMutableDictionary* mutDict, NSError** error)
{
	NSDictionary* dict = [mutDict copy];

	NSDictionary* response = [communicationManager executeFileOperationOnSpringBoard:dict];

	if(error)
	{
		NSError* responseError = [response objectForKey:@"error"];

		if(responseError)
		{
			*error = responseError;
		}
	}

	return response;
}

#endif

@implementation SPFileManager

+ (instancetype)sharedInstance
{
	static SPFileManager* sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^
	{
		//Initialise instance
		sharedInstance = [[SPFileManager alloc] init];
	});

	return sharedInstance;
}

#if !defined(PREFERENCES) && !defined(NO_ROCKETBOOTSTRAP)

- (instancetype)init
{
	self = [super init];

	NSError* sandboxError;
	[super contentsOfDirectoryAtPath:@"/var/mobile" error:&sandboxError];
	_isSandboxed = sandboxError.code == 257;

	_hardLinkURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"hardLink"]];

	_displayNamesForPaths = [communicationManager applicationDisplayNamesForPaths];

	[self resetHardLinks];

	return self;
}

- (void)resetHardLinks
{
	//Create hardLink directory if it does not exists
	if(![self fileExistsAtURL:_hardLinkURL error:nil])
	{
		[super createDirectoryAtURL:_hardLinkURL withIntermediateDirectories:NO attributes:0 error:nil];
	}

	//Delete all files inside hardLink directory
	NSDirectoryEnumerator *enumerator = [super enumeratorAtURL:_hardLinkURL includingPropertiesForKeys:nil options:0 errorHandler:nil];
	NSURL *fileURL;

	while(fileURL = [enumerator nextObject])
	{
		[super removeItemAtURL:fileURL error:nil];
	}
}

- (NSString*)applicationDisplayNameForURL:(NSURL*)URL
{
	return [_displayNamesForPaths objectForKey:URL.path];
}

- (NSURL*)accessibleHardLinkForFileAtURL:(NSURL*)URL forced:(BOOL)forced
{
	if((rocketBootstrapWorks && _isSandboxed) || forced)
	{
		if(![self isURLReadable:URL] || ![self isURLWritable:URL] || forced)
		{
			NSURL* newURL = [_hardLinkURL URLByAppendingPathComponent:URL.lastPathComponent];

			[self linkItemAtURL:URL toURL:newURL error:nil];

			return newURL;
		}
	}

	return URL;
}

- (BOOL)_isReadable:(const char*)str
{
	int denied = sandbox_check(getpid(), "file-read-data", SANDBOX_FILTER_PATH | SANDBOX_CHECK_NO_REPORT, str);
	return !(BOOL)denied;
}

- (BOOL)_isWritable:(const char*)str
{
	int denied = sandbox_check(getpid(), "file-write-data", SANDBOX_FILTER_PATH | SANDBOX_CHECK_NO_REPORT, str);
	return !(BOOL)denied;
}

- (BOOL)isPathReadable:(NSString*)path
{
	return [self _isReadable:[path UTF8String]];
}

- (BOOL)isURLReadable:(NSURL*)URL
{
	return [self _isReadable:[URL.path UTF8String]];
}

- (BOOL)isPathWritable:(NSString*)path
{
	return [self _isWritable:[path UTF8String]];
}

- (BOOL)isURLWritable:(NSURL*)URL
{
	return [self _isWritable:[URL.path UTF8String]];
}

- (NSArray<NSString*>*)contentsOfDirectoryAtPath:(NSString*)path error:(NSError**)error
{
	if(rocketBootstrapWorks && _isSandboxed)
	{
		if(![self isPathReadable:path])
		{
			NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_DirectoryContents];

			NSMutableDictionary* operation = [NSMutableDictionary new];
			addToDict(operation, operationType, @"operationType");
			addToDict(operation, path, @"path");

			return [execute(operation, error) objectForKey:@"return"];
		}
	}

	return [super contentsOfDirectoryAtPath:path error:error];
}

- (NSArray<NSURL*>*)contentsOfDirectoryAtURL:(NSURL*)url includingPropertiesForKeys:(NSArray<NSURLResourceKey>*)keys options:(NSDirectoryEnumerationOptions)mask error:(NSError**)error
{
	if(rocketBootstrapWorks && _isSandboxed)
	{
		if(![self isURLReadable:url])
		{
			NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_DirectoryContents_URL];
			NSNumber* maskN = [NSNumber numberWithInteger:mask];

			NSMutableDictionary* operation = [NSMutableDictionary new];
			addToDict(operation, operationType, @"operationType");
			addToDict(operation, url, @"url");
			addToDict(operation, keys, @"keys");
			addToDict(operation, maskN, @"mask");

			return [execute(operation, error) objectForKey:@"return"];
		}
	}

	return [super contentsOfDirectoryAtURL:url includingPropertiesForKeys:keys options:mask error:error];
}

- (BOOL)createDirectoryAtPath:(NSString*)path withIntermediateDirectories:(BOOL)createIntermediates attributes:(NSDictionary<NSFileAttributeKey, id>*)attributes error:(NSError**)error
{
	if(rocketBootstrapWorks && _isSandboxed)
	{
		if(![self isPathWritable:path])
		{
			NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_CreateDirectory];
			NSNumber* createIntermediatesN = [NSNumber numberWithBool:createIntermediates];

			NSMutableDictionary* operation = [NSMutableDictionary new];
			addToDict(operation, operationType, @"operationType");
			addToDict(operation, path, @"path");
			addToDict(operation, createIntermediatesN, @"createIntermediates");
			addToDict(operation, attributes, @"attributes");

			return [[execute(operation, error) objectForKey:@"return"] boolValue];
		}
	}

	return [super createDirectoryAtPath:path withIntermediateDirectories:createIntermediates attributes:attributes error:error];
}

- (BOOL)createDirectoryAtURL:(NSURL *)url withIntermediateDirectories:(BOOL)createIntermediates attributes:(NSDictionary<NSFileAttributeKey, id> *)attributes error:(NSError**)error
{
	if(rocketBootstrapWorks && _isSandboxed)
	{
		if(![self isURLWritable:url])
		{
			NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_CreateDirectory_URL];
			NSNumber* createIntermediatesN = [NSNumber numberWithBool:createIntermediates];

			NSMutableDictionary* operation = [NSMutableDictionary new];
			addToDict(operation, operationType, @"operationType");
			addToDict(operation, url, @"url");
			addToDict(operation, createIntermediatesN, @"createIntermediates");
			addToDict(operation, attributes, @"attributes");

			return [[execute(operation, error) objectForKey:@"return"] boolValue];
		}
	}

	return [super createDirectoryAtURL:url withIntermediateDirectories:createIntermediates attributes:attributes error:error];
}

- (BOOL)moveItemAtPath:(NSString*)srcPath toPath:(NSString*)dstPath error:(NSError**)error
{
	if(rocketBootstrapWorks && _isSandboxed)
	{
		if(![self isPathReadable:srcPath] || ![self isPathWritable:dstPath])
		{
			NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_MoveItem];

			NSMutableDictionary* operation = [NSMutableDictionary new];
			addToDict(operation, operationType, @"operationType");
			addToDict(operation, srcPath, @"srcPath");
			addToDict(operation, dstPath, @"dstPath");

			return [[execute(operation, error) objectForKey:@"return"] boolValue];
		}
	}

	return [super moveItemAtPath:srcPath toPath:dstPath error:error];
}

- (BOOL)moveItemAtURL:(NSURL*)srcURL toURL:(NSURL*)dstURL error:(NSError**)error
{
	if(rocketBootstrapWorks && _isSandboxed)
	{
		if(![self isURLReadable:srcURL] || ![self isURLWritable:dstURL])
		{
			NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_MoveItem_URL];

			NSMutableDictionary* operation = [NSMutableDictionary new];
			addToDict(operation, operationType, @"operationType");
			addToDict(operation, srcURL, @"srcURL");
			addToDict(operation, dstURL, @"dstURL");

			return [[execute(operation, error) objectForKey:@"return"] boolValue];
		}
	}

	return [super moveItemAtURL:srcURL toURL:dstURL error:error];
}

- (BOOL)removeItemAtPath:(NSString*)path error:(NSError**)error
{
	if(rocketBootstrapWorks && _isSandboxed)
	{
		if(![self isPathWritable:path])
		{
			NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_RemoveItem];

			NSMutableDictionary* operation = [NSMutableDictionary new];
			addToDict(operation, operationType, @"operationType");
			addToDict(operation, path, @"path");

			return [[execute(operation, error) objectForKey:@"return"] boolValue];
		}
	}

	return [super removeItemAtPath:path error:error];
}

- (BOOL)removeItemAtURL:(NSURL*)URL error:(NSError**)error
{
	if(rocketBootstrapWorks && _isSandboxed)
	{
		if(![self isURLWritable:URL])
		{
			NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_RemoveItem_URL];

			NSMutableDictionary* operation = [NSMutableDictionary new];
			addToDict(operation, operationType, @"operationType");
			addToDict(operation, URL, @"URL");

			return [[execute(operation, error) objectForKey:@"return"] boolValue];
		}
	}

	return [super removeItemAtURL:URL error:error];
}

- (BOOL)copyItemAtPath:(NSString*)srcPath toPath:(NSString*)dstPath error:(NSError**)error
{
	if(rocketBootstrapWorks && _isSandboxed)
	{
		if(![self isPathReadable:srcPath] || ![self isPathWritable:dstPath])
		{
			NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_CopyItem];

			NSMutableDictionary* operation = [NSMutableDictionary new];
			addToDict(operation, operationType, @"operationType");
			addToDict(operation, srcPath, @"srcPath");
			addToDict(operation, dstPath, @"dstPath");

			return [[execute(operation, error) objectForKey:@"return"] boolValue];
		}
	}

	return [super copyItemAtPath:srcPath toPath:dstPath error:error];
}

- (BOOL)copyItemAtURL:(NSURL*)srcURL toURL:(NSURL*)dstURL error:(NSError**)error
{
	if(rocketBootstrapWorks && _isSandboxed)
	{
		if(![self isURLReadable:srcURL] || ![self isURLWritable:dstURL])
		{
			NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_CopyItem_URL];

			NSMutableDictionary* operation = [NSMutableDictionary new];
			addToDict(operation, operationType, @"operationType");
			addToDict(operation, srcURL, @"srcURL");
			addToDict(operation, dstURL, @"dstURL");

			return [[execute(operation, error) objectForKey:@"return"] boolValue];
		}
	}

	return [super copyItemAtURL:srcURL toURL:dstURL error:error];
}

- (BOOL)linkItemAtPath:(NSString*)srcPath toPath:(NSString*)dstPath error:(NSError**)error
{
	if(rocketBootstrapWorks && _isSandboxed)
	{
		if(![self isPathReadable:srcPath] || ![self isPathWritable:dstPath])
		{
			NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_LinkItem];

			NSMutableDictionary* operation = [NSMutableDictionary new];
			addToDict(operation, operationType, @"operationType");
			addToDict(operation, srcPath, @"srcPath");
			addToDict(operation, dstPath, @"dstPath");

			return [[execute(operation, error) objectForKey:@"return"] boolValue];
		}
	}

	return [super linkItemAtPath:srcPath toPath:dstPath error:error];
}

- (BOOL)linkItemAtURL:(NSURL*)srcURL toURL:(NSURL*)dstURL error:(NSError**)error
{
	if(rocketBootstrapWorks && _isSandboxed)
	{
		if(![self isURLReadable:srcURL] || ![self isURLWritable:dstURL])
		{
			NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_LinkItem_URL];

			NSMutableDictionary* operation = [NSMutableDictionary new];
			addToDict(operation, operationType, @"operationType");
			addToDict(operation, srcURL, @"srcURL");
			addToDict(operation, dstURL, @"dstURL");

			return [[execute(operation, error) objectForKey:@"return"] boolValue];
		}
	}

	return [super linkItemAtURL:srcURL toURL:dstURL error:error];
}

- (BOOL)fileExistsAtPath:(NSString*)path
{
	if(rocketBootstrapWorks && _isSandboxed)
	{
		if(![self isPathReadable:path])
		{
			NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_FileExists];

			NSMutableDictionary* operation = [NSMutableDictionary new];
			addToDict(operation, operationType, @"operationType");
			addToDict(operation, path, @"path");

			return [[execute(operation, nil) objectForKey:@"return"] boolValue];
		}
	}

	return [super fileExistsAtPath:path];
}

- (BOOL)fileExistsAtPath:(NSString*)path isDirectory:(BOOL*)isDirectory
{
	if(rocketBootstrapWorks && _isSandboxed)
	{
		if(![self isPathReadable:path])
		{
			NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_FileExists_IsDirectory];

			NSMutableDictionary* operation = [NSMutableDictionary new];
			addToDict(operation, operationType, @"operationType");
			addToDict(operation, path, @"path");

			NSDictionary* response = execute(operation, nil);

			*isDirectory = [[response objectForKey:@"isDirectory"] boolValue];

			return [[response objectForKey:@"return"] boolValue];
		}
	}

	return [super fileExistsAtPath:path isDirectory:isDirectory];
}

- (NSDictionary<NSFileAttributeKey, id> *)attributesOfItemAtPath:(NSString *)path error:(NSError**)error;
{
	if(rocketBootstrapWorks && _isSandboxed)
	{
		if(![self isPathReadable:path])
		{
			NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_Attributes];

			NSMutableDictionary* operation = [NSMutableDictionary new];
			addToDict(operation, operationType, @"operationType");
			addToDict(operation, path, @"path");

			return [execute(operation, error) objectForKey:@"return"];
		}
	}

	return [super attributesOfItemAtPath:path error:error];
}

- (BOOL)isWritableFileAtPath:(NSString *)path
{
	if(rocketBootstrapWorks && _isSandboxed)
	{
		if(![self isPathReadable:path])
		{
			NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_IsWritable];

			NSMutableDictionary* operation = [NSMutableDictionary new];
			addToDict(operation, operationType, @"operationType");
			addToDict(operation, path, @"path");

			return [[execute(operation, nil) objectForKey:@"return"] boolValue];
		}
	}

	return [super isWritableFileAtPath:path];
}

- (BOOL)fileExistsAtURL:(NSURL*)url error:(NSError**)error
{
	if(rocketBootstrapWorks && _isSandboxed)
	{
		if(![self isURLReadable:url])
		{
			NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_FileExists_URL];

			NSMutableDictionary* operation = [NSMutableDictionary new];
			addToDict(operation, operationType, @"operationType");
			addToDict(operation, url, @"url");

			return [[execute(operation, error) objectForKey:@"return"] boolValue];
		}
	}

	return [url checkResourceIsReachableAndReturnError:error];
}

- (BOOL)isDirectoryAtURL:(NSURL*)url error:(NSError**)error
{
	if(rocketBootstrapWorks && _isSandboxed)
	{
		if(![self isURLReadable:url])
		{
			NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_IsDirectory_URL];

			NSMutableDictionary* operation = [NSMutableDictionary new];
			addToDict(operation, operationType, @"operationType");
			addToDict(operation, url, @"url");

			return [[execute(operation, error) objectForKey:@"return"] boolValue];
		}
	}

	NSNumber* isDirectory;
	[url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:error];
	return [isDirectory boolValue];
}

- (BOOL)URLResourceValue:(id*)value forKey:(NSURLResourceKey)key forURL:(NSURL*)url error:(NSError**)error
{
	if(rocketBootstrapWorks && _isSandboxed)
	{
		if(![self isURLReadable:url])
		{
			NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_ResourceValue_URL];

			NSMutableDictionary* operation = [NSMutableDictionary new];
			addToDict(operation, operationType, @"operationType");
			addToDict(operation, key, @"key");
			addToDict(operation, url, @"url");

			NSDictionary* response = execute(operation, error);

			*value = [response objectForKey:@"value"];

			return [[response objectForKey:@"return"] boolValue];
		}
	}

	return [url getResourceValue:value forKey:key error:error];
}

- (NSString*)resolveSymlinkForPath:(NSString*)path
{
	NSString* resolvedPath;

	if(rocketBootstrapWorks && _isSandboxed)
	{
		if([self isPathReadable:path])
		{
			NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_ResolveSymlinks];

			NSMutableDictionary* operation = [NSMutableDictionary new];
			addToDict(operation, operationType, @"operationType");
			addToDict(operation, path, @"path");

			resolvedPath = [execute(operation, nil) objectForKey:@"return"];
		}
	}

	if(!resolvedPath)
	{
		resolvedPath = path.stringByResolvingSymlinksInPath;
	}

	//Fix up path (for some reason /var is not getting resolved correctly?)
	if([resolvedPath hasPrefix:@"/var"])
	{
		resolvedPath = [resolvedPath stringByReplacingCharactersInRange:NSMakeRange(1, 3) withString:@"private/var"];
	}

	return resolvedPath;
}

- (NSURL*)resolveSymlinkForURL:(NSURL*)url
{
	NSURL* resolvedURL;

	if(rocketBootstrapWorks && _isSandboxed)
	{
		if([self isURLReadable:url])
		{
			NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_ResolveSymlinks_URL];

			NSMutableDictionary* operation = [NSMutableDictionary new];
			addToDict(operation, operationType, @"operationType");
			addToDict(operation, url, @"url");

			resolvedURL = [execute(operation, nil) objectForKey:@"return"];
		}
	}

	if(!resolvedURL)
	{
		resolvedURL = url.URLByResolvingSymlinksInPath;
	}

	NSString* resolvedPath = resolvedURL.path;

	//Fix up path (for some reason /var is not getting resolved to /private/var correctly?)
	if([resolvedPath hasPrefix:@"/var"])
	{
		resolvedPath = [resolvedPath stringByReplacingCharactersInRange:NSMakeRange(1, 3) withString:@"private/var"];

		resolvedURL = [NSURL fileURLWithPath:resolvedPath];
	}

	return resolvedURL;
}

#else

- (BOOL)fileExistsAtURL:(NSURL*)url error:(NSError**)error
{
	return [url checkResourceIsReachableAndReturnError:error];
}

- (BOOL)isDirectoryAtURL:(NSURL*)url error:(NSError**)error
{
	NSNumber* isDirectory;
	[url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:error];
	return [isDirectory boolValue];
}

- (BOOL)URLResourceValue:(id*)value forKey:(NSURLResourceKey)key forURL:(NSURL*)url error:(NSError**)error
{
	return [url getResourceValue:value forKey:key error:error];
}

- (NSString*)resolveSymlinkForPath:(NSString*)path
{
	NSString* resolvedPath = path.stringByResolvingSymlinksInPath;

	//Fix up path (for some reason /var is not getting resolved correctly?)
	if([resolvedPath hasPrefix:@"/var"])
	{
		resolvedPath = [resolvedPath stringByReplacingCharactersInRange:NSMakeRange(1, 3) withString:@"private/var"];
	}

	return resolvedPath;
}

- (NSURL*)resolveSymlinkForURL:(NSURL*)url
{
	NSURL* resolvedURL = url.URLByResolvingSymlinksInPath;;

	NSString* resolvedPath = resolvedURL.path;

	//Fix up path (for some reason /var is not getting resolved to /private/var correctly?)
	if([resolvedPath hasPrefix:@"/var"])
	{
		resolvedPath = [resolvedPath stringByReplacingCharactersInRange:NSMakeRange(1, 3) withString:@"private/var"];

		resolvedURL = [NSURL fileURLWithPath:resolvedPath];
	}

	return resolvedURL;
}

#endif

#ifdef NO_ROCKETBOOTSTRAP

- (void)resetHardLinks { }
- (NSURL*)accessibleHardLinkForFileAtURL:(NSURL*)URL forced:(BOOL)forced { return URL; }
- (NSString*)applicationDisplayNameForURL:(NSURL*)URL { return nil; }

#endif

- (UIImage*)fileIcon
{
	if(!_fileIcon)
	{
		_fileIcon = [UIImage imageNamed:@"File.png" inBundle:SPBundle compatibleWithTraitCollection:nil];
	}

	return _fileIcon;
}

- (UIImage*)directoryIcon
{
	if(!_directoryIcon)
	{
		_directoryIcon = [UIImage imageNamed:@"Directory.png" inBundle:SPBundle compatibleWithTraitCollection:nil];
	}

	return _directoryIcon;
}

@end
