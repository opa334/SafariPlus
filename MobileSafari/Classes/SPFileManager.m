#import "SPFileManager.h"

#import "SPCommunicationManager.h"
#import "../Shared.h"
#import "../Enums.h"

//Parse nil to empty string
id pN(id object)
{
  return object ?: @"";
}

@implementation SPFileManager

+ (instancetype)sharedInstance
{
    static SPFileManager* sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,
    ^{
      //Initialise instance
      sharedInstance = [[SPFileManager alloc] init];
    });

    return sharedInstance;
}

- (instancetype)init
{
	self = [super init];

	NSError* sandboxError;
	[super contentsOfDirectoryAtPath:@"/var/mobile" error:&sandboxError];
	_isSandboxed = sandboxError.code == 257;

  _hardLinkPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"hardLink"];

  [self resetHardLinks];

	return self;
}

- (void)resetHardLinks
{
	//Create hardLink directory if it does not exists
	if(![super fileExistsAtPath:_hardLinkPath])
	{
		[super createDirectoryAtPath:_hardLinkPath withIntermediateDirectories:NO attributes:0 error:nil];
	}

	//Delete all files inside hardLink directory
	NSDirectoryEnumerator *enumerator = [super enumeratorAtPath:_hardLinkPath];
	NSString *file;

	while(file = [enumerator nextObject])
	{
		[super removeItemAtPath:[_hardLinkPath stringByAppendingPathComponent:file] error:nil];
	}
}

- (NSString*)createHardLinkForFileAtPath:(NSString*)path onlyIfNeeded:(BOOL)needed
{
	if(_isSandboxed || !needed)
	{
		NSString* newPath = [_hardLinkPath stringByAppendingPathComponent:[path lastPathComponent]];

		[self linkItemAtPath:path toPath:newPath error:nil];

		return newPath;
	}
	else
	{
		return path;
	}
}

- (NSArray<NSString *> *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError * _Nullable *)error
{
	if(_isSandboxed)
	{
		NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_DirectoryContents];
		NSDictionary* operation =
    @{
      @"operationType" : operationType,
      @"path" : pN(path)
    };
		return [[communicationManager executeFileOperationOnSpringBoard:operation] objectForKey:@"return"];
	}
	else
	{
		return [super contentsOfDirectoryAtPath:path error:error];
	}
}

- (NSArray<NSURL *> *)contentsOfDirectoryAtURL:(NSURL *)url includingPropertiesForKeys:(NSArray<NSURLResourceKey> *)keys options:(NSDirectoryEnumerationOptions)mask error:(NSError * _Nullable *)error
{
	if(_isSandboxed)
	{
		NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_DirectoryContents_URL];
    NSNumber* maskN = [NSNumber numberWithInteger:mask];
    NSDictionary* operation =
    @{
      @"operationType" : operationType,
      @"url" : pN([url path]),
      @"keys" : pN(keys),
      @"mask" : pN(maskN)
    };

		NSArray* response = [[communicationManager executeFileOperationOnSpringBoard:operation] objectForKey:@"return"];
    NSMutableArray* URLResponse = [NSMutableArray new];

    for(NSString* path in response)
    {
      [URLResponse addObject:[NSURL fileURLWithPath:path]];
    }

    return [URLResponse copy];
	}
	else
	{
		return [super contentsOfDirectoryAtURL:url includingPropertiesForKeys:keys options:mask error:error];
	}
}

- (BOOL)createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)createIntermediates attributes:(NSDictionary<NSFileAttributeKey, id> *)attributes error:(NSError * _Nullable *)error
{
	if(_isSandboxed)
	{
		NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_CreateDirectory];
    NSNumber* createIntermediatesN = [NSNumber numberWithBool:createIntermediates];
    NSDictionary* operation =
    @{
      @"operationType" : operationType,
      @"path" : pN(path),
      @"createIntermediates" : pN(createIntermediatesN),
      @"attributes" : pN(attributes)
    };
		return [[[communicationManager executeFileOperationOnSpringBoard:operation] objectForKey:@"return"] boolValue];
	}
	else
	{
		return [super createDirectoryAtPath:path withIntermediateDirectories:createIntermediates attributes:attributes error:error];
	}
}

- (BOOL)createDirectoryAtURL:(NSURL *)url withIntermediateDirectories:(BOOL)createIntermediates attributes:(NSDictionary<NSFileAttributeKey, id> *)attributes error:(NSError * _Nullable *)error
{
	if(_isSandboxed)
	{
		NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_CreateDirectory_URL];
    NSNumber* createIntermediatesN = [NSNumber numberWithBool:createIntermediates];
    NSDictionary* operation =
    @{
      @"operationType" : operationType,
      @"url" : pN([url path]),
      @"createIntermediates" : pN(createIntermediatesN),
      @"attributes" : pN(attributes)
    };
		return [[[communicationManager executeFileOperationOnSpringBoard:operation] objectForKey:@"return"] boolValue];
	}
	else
	{
		return [super createDirectoryAtURL:url withIntermediateDirectories:createIntermediates attributes:attributes error:error];
	}
}

- (BOOL)moveItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError * _Nullable *)error
{
	if(_isSandboxed)
	{
		NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_MoveItem];
    NSDictionary* operation =
    @{
      @"operationType" : operationType,
      @"srcPath" : pN(srcPath),
      @"dstPath" : pN(dstPath)
    };
		return [[[communicationManager executeFileOperationOnSpringBoard:operation] objectForKey:@"return"] boolValue];
	}
	else
	{
		return [super moveItemAtPath:srcPath toPath:dstPath error:error];
	}
}

- (BOOL)moveItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL error:(NSError * _Nullable *)error
{
	if(_isSandboxed)
	{
		NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_MoveItem_URL];
    NSDictionary* operation =
    @{
      @"operationType" : operationType,
      @"srcURL" : pN([srcURL path]),
      @"dstURL" : pN([dstURL path])
    };
		return [[[communicationManager executeFileOperationOnSpringBoard:operation] objectForKey:@"return"] boolValue];
	}
	else
	{
		return [super moveItemAtURL:srcURL toURL:dstURL error:error];
	}
}

- (BOOL)removeItemAtPath:(NSString *)path error:(NSError * _Nullable *)error
{
	if(_isSandboxed)
	{
		NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_RemoveItem];
    NSDictionary* operation =
    @{
      @"operationType" : operationType,
      @"path" : pN(path)
    };
		return [[[communicationManager executeFileOperationOnSpringBoard:operation] objectForKey:@"return"] boolValue];
	}
	else
	{
		return [super removeItemAtPath:path error:error];
	}
}

- (BOOL)removeItemAtURL:(NSURL *)URL error:(NSError * _Nullable *)error
{
	if(_isSandboxed)
	{
		NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_RemoveItem_URL];
    NSDictionary* operation =
    @{
      @"operationType" : operationType,
      @"URL" : pN([URL path])
    };
		return [[[communicationManager executeFileOperationOnSpringBoard:operation] objectForKey:@"return"] boolValue];
	}
	else
	{
		return [super removeItemAtURL:URL error:error];
	}
}

- (BOOL)linkItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError * _Nullable *)error
{
	if(_isSandboxed)
	{
		NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_LinkItem];
    NSDictionary* operation =
    @{
      @"operationType" : operationType,
      @"srcPath" : pN(srcPath),
      @"dstPath" : pN(dstPath)
    };
		return [[[communicationManager executeFileOperationOnSpringBoard:operation] objectForKey:@"return"] boolValue];
	}
	else
	{
		return [super linkItemAtPath:srcPath toPath:dstPath error:error];
	}
}

- (BOOL)linkItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL error:(NSError * _Nullable *)error
{
	if(_isSandboxed)
	{
		NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_LinkItem_URL];
    NSDictionary* operation =
    @{
      @"operationType" : operationType,
      @"srcURL" : pN([srcURL path]),
      @"dstURL" : pN([dstURL path])
    };
		return [[[communicationManager executeFileOperationOnSpringBoard:operation] objectForKey:@"return"] boolValue];
	}
	else
	{
		return [super linkItemAtURL:srcURL toURL:dstURL error:error];
	}
}

- (BOOL)fileExistsAtPath:(NSString *)path
{
	if(_isSandboxed)
	{
		NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_FileExists];
    NSDictionary* operation =
    @{
      @"operationType" : operationType,
      @"path" : pN(path)
    };
		return [[[communicationManager executeFileOperationOnSpringBoard:operation] objectForKey:@"return"] boolValue];
	}
	else
	{
		return [super fileExistsAtPath:path];
	}
}

- (BOOL)fileExistsAtPath:(NSString *)path isDirectory:(BOOL *)isDirectory
{
	if(_isSandboxed)
	{
		NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_FileExists_isDirectory];
    NSDictionary* operation =
    @{
      @"operationType" : operationType,
      @"path" : pN(path)
    };
		NSDictionary* reply = [communicationManager executeFileOperationOnSpringBoard:operation];

		*isDirectory = [[reply objectForKey:@"isDirectory"] boolValue];
		return [[reply objectForKey:@"return"] boolValue];
	}
	else
	{
		return [super fileExistsAtPath:path isDirectory:isDirectory];
	}
}

- (NSDictionary<NSFileAttributeKey, id> *)attributesOfItemAtPath:(NSString *)path error:(NSError * _Nullable *)error;
{
	if(_isSandboxed)
	{
		NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_Attributes];
    NSDictionary* operation =
    @{
      @"operationType" : operationType,
      @"path" : pN(path)
    };
		return [[communicationManager executeFileOperationOnSpringBoard:operation] objectForKey:@"return"];
	}
	else
	{
		return [super attributesOfItemAtPath:path error:error];
	}
}

- (BOOL)isWritableFileAtPath:(NSString *)path
{
  if(_isSandboxed)
	{
		NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_IsWritable];
    NSDictionary* operation =
    @{
      @"operationType" : operationType,
      @"path" : pN(path)
    };
		return [[[communicationManager executeFileOperationOnSpringBoard:operation] objectForKey:@"return"] boolValue];
	}
	else
	{
		return [super isWritableFileAtPath:path];
	}
}

- (NSString*)resolveSymlinkForPath:(NSString*)path
{
  NSString* resolvedPath;

  if(_isSandboxed)
  {
    NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_ResolveSymlinks];
    NSDictionary* operation =
    @{
      @"operationType" : operationType,
      @"path" : pN(path)
    };

    resolvedPath = [[communicationManager executeFileOperationOnSpringBoard:operation] objectForKey:@"return"];
  }
  else
  {
    resolvedPath = path.stringByResolvingSymlinksInPath;
  }

  //Fix up path
  resolvedPath = [resolvedPath stringByReplacingOccurrencesOfString:@"/var" withString:@"/private/var"];

  return resolvedPath;
}

@end
