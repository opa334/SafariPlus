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

#import "SPFileManager.h"

#ifndef PREFERENCES
#import "SPPreferenceManager.h"
#endif

#import "../SafariPlus.h"
#import "../Defines.h"
#import "../Util.h"
#import "../Enums.h"
#import "../../Shared/SPFile.h"
#import "../../Shared/NSFileManager+DirectorySize.h"
#import "SPDownload.h"
#import <MobileCoreServices/LSApplicationWorkspace.h>
#import <MobileCoreServices/LSApplicationProxy.h>
#import <MobileCoreServices/LSBundleProxy.h>

@interface LSApplicationWorkspace ()
- (void)enumerateBundlesOfType:(NSUInteger)type usingBlock:(void (^)(LSBundleProxy* bundleProxy))block;
@end

#import <unistd.h>
#import <libSandy.h>

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


// Populate _displayNamesForPaths using MobileCoreServices
- (void)populateApplicationDisplayNamesForPath
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
	{
		NSMutableDictionary* displayNamesForPaths = [NSMutableDictionary new];

		LSApplicationWorkspace* workspace = [LSApplicationWorkspace defaultWorkspace];

		//TODO: iOS 8 support
		if([workspace respondsToSelector:@selector(enumerateBundlesOfType:usingBlock:)])
		{
			void (^enumerateBlock)(LSBundleProxy*) = ^(LSBundleProxy* bundleProxy)
			{
				NSLog(@"enum %@", bundleProxy);
				NSString* localizedName = [bundleProxy localizedName];
				if(localizedName)
				{
					NSString* dataContainerPath = bundleProxy.dataContainerURL.path;
					if(dataContainerPath)
					{
						displayNamesForPaths[dataContainerPath] = localizedName;
					}

					NSString* bundleContainerPath = bundleProxy.bundleContainerURL.path;
					if(bundleContainerPath)
					{
						displayNamesForPaths[bundleContainerPath] = localizedName;
					}

					[bundleProxy.groupContainerURLs enumerateKeysAndObjectsUsingBlock:^(NSString* groupID, NSURL* groupURL, BOOL *stop)
					{
						NSString* groupPath = groupURL.path;
						if(groupPath)
						{
							displayNamesForPaths[groupURL.path] = groupID;
						}
					}];
				}
			}; 

			[workspace enumerateBundlesOfType:0 usingBlock:enumerateBlock];
			[workspace enumerateBundlesOfType:1 usingBlock:enumerateBlock];
		}

		_displayNamesForPaths = displayNamesForPaths.copy;
	});
}

- (instancetype)init
{
	self = [super init];

#if !defined(PREFERENCES)

	// Get file access using libSandy
	// If disabled inside settings, libSandy will return do nothing and kLibSandyErrorRestricted
	libSandy_applyProfile("SafariPlus_FileAccess");

	// Set up hard linking (only needed on iOS 8)
	_hardLinkURL = [getSafariTmpURL() URLByAppendingPathComponent:@"hardLink"];
	[self resetHardLinks];
#endif

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

- (NSURL*)accessibleHardLinkForFileAtURL:(NSURL*)URL
{
	HBLogDebugWeak(@"accessibleHardLinkForFileAtURL:%@", URL);
	HBLogDebugWeak(@"isURLReadable:%i", [self isURLReadable:URL]);
	HBLogDebugWeak(@"isURLWritable:%i", [self isURLWritable:URL]);

	NSURL* hardLinkURL = [_hardLinkURL URLByAppendingPathComponent:URL.lastPathComponent];

	NSError* linkError;
	[self linkItemAtURL:URL toURL:hardLinkURL error:&linkError];
	HBLogDebugWeak(@"linkError:%@", linkError);
	if(linkError.code == 513 || linkError.code == 512)
	{
		[self removeItemAtURL:hardLinkURL error:nil];
		NSError* copyError;
		[self copyItemAtURL:URL toURL:hardLinkURL error:&copyError];
		HBLogDebugWeak(@"copyError:%@", copyError);
	}

	return hardLinkURL;
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
