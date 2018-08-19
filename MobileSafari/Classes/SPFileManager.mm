// SPFileManager.mm
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

#import "SPFileManager.h"

#ifndef PREFERENCES
#import "SPCommunicationManager.h"
#endif

#import "../Shared.h"
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
  dispatch_once(&onceToken,
  ^{
    //Initialise instance
    sharedInstance = [[SPFileManager alloc] init];
  });

  return sharedInstance;
}

#ifndef PREFERENCES

- (instancetype)init
{
  self = [super init];

  NSError* sandboxError;
  [super contentsOfDirectoryAtPath:@"/var/mobile" error:&sandboxError];
  _isSandboxed = sandboxError.code == 257;

  _hardLinkURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"hardLink"]];

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

- (NSURL*)createHardLinkForFileAtURL:(NSURL*)url onlyIfNeeded:(BOOL)needed
{
  if(_isSandboxed || !needed)
  {
    if(![self isSandboxedURL:url])
    {
      NSURL* newURL = [_hardLinkURL URLByAppendingPathComponent:url.lastPathComponent];

      [self linkItemAtURL:url toURL:newURL error:nil];

      return newURL;
    }
  }

  return url;
}

- (BOOL)isSandboxedPath:(NSString*)path
{
  NSString* resolvedPath = path.stringByStandardizingPath;
  return [resolvedPath hasPrefix:NSHomeDirectory().stringByStandardizingPath];
  /*NSString* resolvedPath = [self resolveSymlinkForPath:path.stringByStandardizingPath];
  return [resolvedPath hasPrefix:[self resolveSymlinkForPath:NSHomeDirectory().stringByStandardizingPath]];*/
}

- (BOOL)isSandboxedURL:(NSURL*)url
{
  NSString* resolvedPath = url.URLByStandardizingPath.path;
  return [resolvedPath hasPrefix:NSHomeDirectory().stringByStandardizingPath];
  /*NSString* resolvedPath = [self resolveSymlinkForPath:url.URLByStandardizingPath.path];
  return [resolvedPath hasPrefix:[self resolveSymlinkForPath:NSHomeDirectory().stringByStandardizingPath]];*/
}

#endif

- (NSArray<NSString*>*)contentsOfDirectoryAtPath:(NSString*)path error:(NSError**)error
{
  #ifndef PREFERENCES
  if(_isSandboxed)
  {
    if(![self isSandboxedPath:path])
    {
      NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_DirectoryContents];

      NSMutableDictionary* operation = [NSMutableDictionary new];
      addToDict(operation, operationType, @"operationType");
      addToDict(operation, path, @"path");

      return [execute(operation, error) objectForKey:@"return"];
    }
  }
  #endif

  return [super contentsOfDirectoryAtPath:path error:error];
}

- (NSArray<NSURL*>*)contentsOfDirectoryAtURL:(NSURL*)url includingPropertiesForKeys:(NSArray<NSURLResourceKey>*)keys options:(NSDirectoryEnumerationOptions)mask error:(NSError**)error
{
  #ifndef PREFERENCES
  if(_isSandboxed)
  {
    if(![self isSandboxedURL:url])
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
  #endif

  return [super contentsOfDirectoryAtURL:url includingPropertiesForKeys:keys options:mask error:error];
}

- (BOOL)createDirectoryAtPath:(NSString*)path withIntermediateDirectories:(BOOL)createIntermediates attributes:(NSDictionary<NSFileAttributeKey, id>*)attributes error:(NSError**)error
{
  #ifndef PREFERENCES
  if(_isSandboxed)
  {
    if(![self isSandboxedPath:path])
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
  #endif

  return [super createDirectoryAtPath:path withIntermediateDirectories:createIntermediates attributes:attributes error:error];
}

- (BOOL)createDirectoryAtURL:(NSURL *)url withIntermediateDirectories:(BOOL)createIntermediates attributes:(NSDictionary<NSFileAttributeKey, id> *)attributes error:(NSError**)error
{
  #ifndef PREFERENCES
  if(_isSandboxed)
  {
    if(![self isSandboxedURL:url])
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
  #endif

  return [super createDirectoryAtURL:url withIntermediateDirectories:createIntermediates attributes:attributes error:error];
}

- (BOOL)moveItemAtPath:(NSString*)srcPath toPath:(NSString*)dstPath error:(NSError**)error
{
  #ifndef PREFERENCES
  if(_isSandboxed)
  {
    if(![self isSandboxedPath:srcPath] || ![self isSandboxedPath:dstPath])
    {
      NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_MoveItem];

      NSMutableDictionary* operation = [NSMutableDictionary new];
      addToDict(operation, operationType, @"operationType");
      addToDict(operation, srcPath, @"srcPath");
      addToDict(operation, dstPath, @"dstPath");

      return [[execute(operation, error) objectForKey:@"return"] boolValue];
    }
  }
  #endif

  return [super moveItemAtPath:srcPath toPath:dstPath error:error];
}

- (BOOL)moveItemAtURL:(NSURL*)srcURL toURL:(NSURL*)dstURL error:(NSError**)error
{
  #ifndef PREFERENCES
  if(_isSandboxed)
  {
    if(![self isSandboxedURL:srcURL] || ![self isSandboxedURL:dstURL])
    {
      NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_MoveItem_URL];

      NSMutableDictionary* operation = [NSMutableDictionary new];
      addToDict(operation, operationType, @"operationType");
      addToDict(operation, srcURL, @"srcURL");
      addToDict(operation, dstURL, @"dstURL");

      return [[execute(operation, error) objectForKey:@"return"] boolValue];
    }
  }
  #endif

  return [super moveItemAtURL:srcURL toURL:dstURL error:error];
}

- (BOOL)removeItemAtPath:(NSString*)path error:(NSError**)error
{
  #ifndef PREFERENCES
  if(_isSandboxed)
  {
    if(![self isSandboxedPath:path])
    {
      NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_RemoveItem];

      NSMutableDictionary* operation = [NSMutableDictionary new];
      addToDict(operation, operationType, @"operationType");
      addToDict(operation, path, @"path");

      return [[execute(operation, error) objectForKey:@"return"] boolValue];
    }
  }
  #endif

  return [super removeItemAtPath:path error:error];
}

- (BOOL)removeItemAtURL:(NSURL*)URL error:(NSError**)error
{
  #ifndef PREFERENCES
  if(_isSandboxed)
  {
    if(![self isSandboxedURL:URL])
    {
      NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_RemoveItem_URL];

      NSMutableDictionary* operation = [NSMutableDictionary new];
      addToDict(operation, operationType, @"operationType");
      addToDict(operation, URL, @"URL");

      return [[execute(operation, error) objectForKey:@"return"] boolValue];
    }
  }
  #endif

  return [super removeItemAtURL:URL error:error];
}

- (BOOL)linkItemAtPath:(NSString*)srcPath toPath:(NSString*)dstPath error:(NSError**)error
{
  #ifndef PREFERENCES
  if(_isSandboxed)
  {
    if(![self isSandboxedPath:srcPath] || ![self isSandboxedPath:dstPath])
    {
      NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_LinkItem];

      NSMutableDictionary* operation = [NSMutableDictionary new];
      addToDict(operation, operationType, @"operationType");
      addToDict(operation, srcPath, @"srcPath");
      addToDict(operation, dstPath, @"dstPath");

      return [[execute(operation, error) objectForKey:@"return"] boolValue];
    }
  }
  #endif

  return [super linkItemAtPath:srcPath toPath:dstPath error:error];
}

- (BOOL)linkItemAtURL:(NSURL*)srcURL toURL:(NSURL*)dstURL error:(NSError**)error
{
  #ifndef PREFERENCES
  if(_isSandboxed)
  {
    if(![self isSandboxedURL:srcURL] || ![self isSandboxedURL:dstURL])
    {
      NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_LinkItem_URL];

      NSMutableDictionary* operation = [NSMutableDictionary new];
      addToDict(operation, operationType, @"operationType");
      addToDict(operation, srcURL, @"srcURL");
      addToDict(operation, dstURL, @"dstURL");

      return [[execute(operation, error) objectForKey:@"return"] boolValue];
    }
  }
  #endif

  return [super linkItemAtURL:srcURL toURL:dstURL error:error];
}

- (BOOL)fileExistsAtPath:(NSString*)path
{
  #ifndef PREFERENCES
  if(_isSandboxed)
  {
    if(![self isSandboxedPath:path])
    {
      NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_FileExists];

      NSMutableDictionary* operation = [NSMutableDictionary new];
      addToDict(operation, operationType, @"operationType");
      addToDict(operation, path, @"path");

      return [[execute(operation, nil) objectForKey:@"return"] boolValue];
    }
  }
  #endif

  return [super fileExistsAtPath:path];
}

- (BOOL)fileExistsAtURL:(NSURL*)url error:(NSError**)error
{
  #ifndef PREFERENCES
  if(_isSandboxed)
  {
    if(![self isSandboxedURL:url])
    {
      NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_FileExists_URL];

      NSMutableDictionary* operation = [NSMutableDictionary new];
      addToDict(operation, operationType, @"operationType");
      addToDict(operation, url, @"url");

      return [[execute(operation, error) objectForKey:@"return"] boolValue];
    }
  }
  #endif

  return [url checkResourceIsReachableAndReturnError:error];
}

- (BOOL)fileExistsAtPath:(NSString*)path isDirectory:(BOOL*)isDirectory
{
  #ifndef PREFERENCES
  if(_isSandboxed)
  {
    if(![self isSandboxedPath:path])
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
  #endif

  return [super fileExistsAtPath:path isDirectory:isDirectory];
}

- (BOOL)isDirectoryAtURL:(NSURL*)url error:(NSError**)error
{
  #ifndef PREFERENCES
  if(_isSandboxed)
  {
    if(![self isSandboxedURL:url])
    {
      NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_IsDirectory_URL];

      NSMutableDictionary* operation = [NSMutableDictionary new];
      addToDict(operation, operationType, @"operationType");
      addToDict(operation, url, @"url");

      return [[execute(operation, error) objectForKey:@"return"] boolValue];
    }
  }
  #endif

  NSNumber* isDirectory;
  [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:error];
  return [isDirectory boolValue];
}

- (NSDictionary<NSFileAttributeKey, id> *)attributesOfItemAtPath:(NSString *)path error:(NSError**)error;
{
  #ifndef PREFERENCES
  if(_isSandboxed)
  {
    if(![self isSandboxedPath:path])
    {
      NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_Attributes];

      NSMutableDictionary* operation = [NSMutableDictionary new];
      addToDict(operation, operationType, @"operationType");
      addToDict(operation, path, @"path");

      return [execute(operation, error) objectForKey:@"return"];
    }
  }
  #endif

  return [super attributesOfItemAtPath:path error:error];
}

- (BOOL)URLResourceValue:(id*)value forKey:(NSURLResourceKey)key forURL:(NSURL*)url error:(NSError**)error
{
  #ifndef PREFERENCES
  if(_isSandboxed)
  {
    if(![self isSandboxedURL:url])
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
  #endif

  return [url getResourceValue:value forKey:key error:error];
}

- (BOOL)isWritableFileAtPath:(NSString *)path
{
  #ifndef PREFERENCES
  if(_isSandboxed)
  {
    if(![self isSandboxedPath:path])
    {
      NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_IsWritable];

      NSMutableDictionary* operation = [NSMutableDictionary new];
      addToDict(operation, operationType, @"operationType");
      addToDict(operation, path, @"path");

      return [[execute(operation, nil) objectForKey:@"return"] boolValue];
    }
  }
  #endif

  return [super isWritableFileAtPath:path];
}

- (NSString*)resolveSymlinkForPath:(NSString*)path
{
  NSString* resolvedPath;

  #ifndef PREFERENCES
  if(_isSandboxed)
  {
    NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_ResolveSymlinks];

    NSMutableDictionary* operation = [NSMutableDictionary new];
    addToDict(operation, operationType, @"operationType");
    addToDict(operation, path, @"path");

    resolvedPath = [execute(operation, nil) objectForKey:@"return"];
  }
  else
  {
    #endif
    resolvedPath = path.stringByResolvingSymlinksInPath;
    #ifndef PREFERENCES
  }
  #endif

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

  #ifndef PREFERENCES
  if(_isSandboxed)
  {
    NSNumber* operationType = [NSNumber numberWithInteger:FileOperation_ResolveSymlinks_URL];

    NSMutableDictionary* operation = [NSMutableDictionary new];
    addToDict(operation, operationType, @"operationType");
    addToDict(operation, url, @"url");

    resolvedURL = [execute(operation, nil) objectForKey:@"return"];
  }
  else
  {
    #endif
    resolvedURL = url.URLByResolvingSymlinksInPath;
    #ifndef PREFERENCES
  }
  #endif

  NSString* resolvedPath = resolvedURL.path;

  //Fix up path (for some reason /var is not getting resolved to /private/var correctly?)
  if([resolvedPath hasPrefix:@"/var"])
  {
    resolvedPath = [resolvedPath stringByReplacingCharactersInRange:NSMakeRange(1, 3) withString:@"private/var"];

    resolvedURL = [NSURL fileURLWithPath:resolvedPath];
  }

  return resolvedURL;
}

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
