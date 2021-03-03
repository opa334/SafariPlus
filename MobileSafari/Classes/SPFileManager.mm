// Copyright (c) 2017-2020 Lars Fröder

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

#import "SPFileManager.h"

#ifndef PREFERENCES
#import "SPCommunicationManager.h"
#endif

#import "../SafariPlus.h"
#import "../Defines.h"
#import "../Util.h"
#import "../Enums.h"
#import "../../Shared/SPFile.h"
#import "../../Shared/NSFileManager+DirectorySize.h"
#import "SPDownload.h"

#import <unistd.h>
/*
#import <QuickLook/QuickLook.h>
@interface QLThumbnail : NSObject
- (id)initWithURL:(id)arg1;
- (id)imageForUseMode:(NSUInteger)arg1 descriptor:(id)arg2 generateIfNeeded:(BOOL)arg3 contentRect:(CGRect*)arg4 error:(id*)arg5;
@end

@interface QLThumbnailGenerator : NSObject
+ (void)generateThumbnailOfMaximumSize:(CGSize)arg1 scale:(double)arg2 forURL:(id)arg3 completionHandler:(void (^)(id arg1))completion;
@end
*/
#ifndef PREFERENCES

//Wrapper around executeFileOperationOnSpringBoard that simplifies error handling
NSDictionary* execute(NSMutableDictionary* mutDict, NSError** error)
{
	NSDictionary* dict = [mutDict copy];

	NSDictionary* response = [communicationManager executeFileOperationOnSpringBoard:dict];

	NSException* exception = [response objectForKey:@"exception"];
	if(exception)
	{
		//Redirect SpringBoard crashes to Safari
		@throw(exception);
	}

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

	_hardLinkURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"hardLink"]];

	_isSandboxed = access("/var/mobile", W_OK) != 0;
	HBLogDebug(@"_isSandboxed:%i", _isSandboxed);

	BOOL isCheckra1n = access("/var/checkra1n.dmg", F_OK) == 0;
	HBLogDebug(@"isCheckra1n:%i", isCheckra1n);

	if(isCheckra1n)
	{
		//Checkra1n seems to have incomplete sandbox patches
		//So we just assume we're sandboxed if on checkra1n
		_isSandboxed = YES;
	}

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
	HBLogDebug(@"accessibleHardLinkForFileAtURL:%@", URL);
	HBLogDebug(@"isURLReadable:%i", [self isURLReadable:URL]);
	HBLogDebug(@"isURLWritable:%i", [self isURLWritable:URL]);

	if((rocketBootstrapWorks && _isSandboxed) || forced)
	{
		if(![self isURLReadable:URL] || ![self isURLWritable:URL] || forced)
		{
			NSURL* hardLinkURL = [_hardLinkURL URLByAppendingPathComponent:URL.lastPathComponent];

			NSError* linkError;
			[self linkItemAtURL:URL toURL:hardLinkURL error:&linkError];
			HBLogDebug(@"linkError:%@", linkError);
			if(linkError.code == 513 || linkError.code == 512)
			{
				//[self resetHardLinks];
				NSError* copyError;
				[self copyItemAtURL:URL toURL:hardLinkURL error:&copyError];
				HBLogDebug(@"copyError:%@", copyError);
			}

			return hardLinkURL;
		}
	}

	return URL;
}

- (BOOL)_isReadable:(const char*)str
{
	int denied = sandbox_check(getpid(), "file-read-data", SANDBOX_FILTER_PATH | SANDBOX_CHECK_NO_REPORT, str);
	return !denied;
}

- (BOOL)_isWritable:(const char*)str
{
	int denied = sandbox_check(getpid(), "file-write-data", SANDBOX_FILTER_PATH | SANDBOX_CHECK_NO_REPORT, str);
	return !denied;
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

- (NSArray<SPFile*>*)filesAtURL:(NSURL*)URL error:(NSError**)error
{
	if(rocketBootstrapWorks && _isSandboxed)
	{
		if(![self isURLReadable:URL])
		{
			NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_DirectoryContents_SPFile];

			NSMutableDictionary* operation = [NSMutableDictionary new];
			addToDict(operation, operationType, @"operationType");
			addToDict(operation, URL, @"url");

			return [execute(operation, error) objectForKey:@"return"];
		}
	}

	return [SPFile filesAtURL:URL error:error];
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
		NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_IsWritable];

		NSMutableDictionary* operation = [NSMutableDictionary new];
		addToDict(operation, operationType, @"operationType");
		addToDict(operation, path, @"path");

		return [[execute(operation, nil) objectForKey:@"return"] boolValue];
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
		NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_ResourceValue_URL];

		NSMutableDictionary* operation = [NSMutableDictionary new];
		addToDict(operation, operationType, @"operationType");
		addToDict(operation, key, @"key");
		addToDict(operation, url, @"url");

		NSDictionary* response = execute(operation, error);

		*value = [response objectForKey:@"value"];

		return [[response objectForKey:@"return"] boolValue];
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
		if(![self isURLReadable:url])
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

- (NSUInteger)sizeOfDirectoryAtURL:(NSURL*)directoryURL
{
	if(rocketBootstrapWorks && _isSandboxed)
	{
		if(![self isURLReadable:directoryURL])
		{
			NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_DirectorySize_URL];

			NSMutableDictionary* operation = [NSMutableDictionary new];
			addToDict(operation, operationType, @"operationType");
			addToDict(operation, directoryURL, @"url");

			return [(NSNumber*)[execute(operation, nil) objectForKey:@"return"] unsignedIntegerValue];
		}
	}

	return [super sizeOfDirectoryAtURL:directoryURL];
}

#else

- (NSArray<SPFile*>*)filesAtURL:(NSURL*)URL error:(NSError**)error
{
	return [SPFile filesAtURL:URL error:error];
}

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

- (UIImage*)iconForDownload:(SPDownload*)download
{
	NSString* filename = download.filename;
	if([filename.pathExtension isEqualToString:@"movpkg"])
	{
		filename = @"a.mp4";
	}
	LSDocumentProxy* documentProxy = [LSDocumentProxy documentProxyForName:filename type:nil MIMEType:nil];

	return [self fileIconForDocumentProxy:documentProxy];
}

- (UIImage*)iconForFile:(SPFile*)file
{
	LSDocumentProxy* documentProxy;

	if([file isHLSStream])
	{
		documentProxy = [LSDocumentProxy documentProxyForName:@"a.mp4" type:nil MIMEType:nil];
	}
	else
	{
		documentProxy = [LSDocumentProxy documentProxyForName:nil type:file.fileUTI MIMEType:nil];
	}

	return [self fileIconForDocumentProxy:documentProxy];
}

- (UIImage*)fileIconForDocumentProxy:(LSDocumentProxy*)documentProxy
{
	//A little bit bigger but has an annoying mega icon on all files without an other icon
	//UIImage* icon = [UIImage _iconForResourceProxy:documentProxy format:13 options:0];

	UIImage* icon = [UIImage _iconForResourceProxy:documentProxy variant:19 variantsScale:[UIScreen mainScreen].scale];
	//26 and 36 are also possible variants

	if(!icon)
	{
		return [self genericFileIcon];
	}

	return icon;
}

- (UIImage*)genericFileIcon
{
	static dispatch_once_t fileOnceToken;

	dispatch_once(&fileOnceToken, ^
	{
		CGSize size = CGSizeMake(1,1);
		UIGraphicsBeginImageContextWithOptions(size, NO, 0);
		[[UIColor clearColor] setFill];
		UIRectFill(CGRectMake(0, 0, size.width, size.height));
		UIImage* clearImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();

		CGImageRef iconCG = LICreateIconForImage(clearImage.CGImage, 19, 0);
		_genericFileIcon = [[UIImage alloc] initWithCGImage:iconCG scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
	});

	return _genericFileIcon;
}

- (UIImage*)genericDirectoryIcon
{
	static dispatch_once_t directoryOnceToken;

	dispatch_once(&directoryOnceToken, ^
	{
		NSBundle* bundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/DocumentManager.framework"];

		if(bundle)
		{
			_genericDirectoryIcon = [UIImage imageNamed:@"Folder-Light-29" inBundle:bundle];

			if(!_genericDirectoryIcon)
			{
				_genericDirectoryIcon = [UIImage imageNamed:@"Folder29pt" inBundle:bundle]; //iOS 13
			}
		}
		else
		{
			_genericDirectoryIcon = [UIImage imageNamed:@"Directory" inBundle:SPBundle compatibleWithTraitCollection:nil];
		}
	});

	return _genericDirectoryIcon;
}

@end
