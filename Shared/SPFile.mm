// Copyright (c) 2017-2021 Lars Fröder

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

#import "SPFile.h"
#import "Extensions.h"
#import "NSFileManager+DirectorySize.h"

#import "../MobileSafari/Defines.h"

#if !SPRINGBOARD
#import "../MobileSafari/Util.h"
#import "../MobileSafari/Classes/SPFileManager.h"
#else
NSFileManager* fileManager = [NSFileManager defaultManager];
#endif

#import <MobileCoreServices/MobileCoreServices.h>
#import <QuickLook/QuickLook.h>

@implementation SPFile

- (instancetype)initWithFileURL:(NSURL*)fileURL
{
	self = [super init];

	_fileURL = fileURL;

	_name = [_fileURL lastPathComponent];

	[self updateCellTitle];
	[self updateUTI];

	NSNumber* isRegularFile;
	#if !PREFERENCES && !SPRINGBOARD
	[fileManager URLResourceValue:&isRegularFile forKey:NSURLIsRegularFileKey forURL:_fileURL error:nil];
	#else
	[fileURL getResourceValue:&isRegularFile forKey:NSURLIsRegularFileKey error:nil];
	#endif
	_isRegularFile = [isRegularFile boolValue];

	if([self displaysAsRegularFile] != _isRegularFile)
	{
		_size = [fileManager sizeOfDirectoryAtURL:fileURL];
	}
	else
	{
		NSNumber* size;
		#if !PREFERENCES && !SPRINGBOARD
		[fileManager URLResourceValue:&size forKey:NSURLFileSizeKey forURL:_fileURL error:nil];
		#else
		[fileURL getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
		#endif
		_size = [size longLongValue];
	}

	NSNumber* isWritable;
	#if !PREFERENCES && !SPRINGBOARD
	[fileManager URLResourceValue:&isWritable forKey:NSURLIsWritableKey forURL:_fileURL error:nil];
	#else
	[fileURL getResourceValue:&isWritable forKey:NSURLIsWritableKey error:nil];
	#endif
	_isWritable = [isWritable boolValue];

	_isHidden = [[fileURL lastPathComponent] hasPrefix:@"."];

	_isPreviewable = [QLPreviewController canPreviewItem:_fileURL];

	return self;
}


- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];

	_fileURL = [decoder decodeObjectForKey:@"fileURL"];
	_name = [decoder decodeObjectForKey:@"name"];
	_isRegularFile = [decoder decodeBoolForKey:@"isRegularFile"];
	_size = [decoder decodeIntegerForKey:@"size"];
	_isHidden = [decoder decodeBoolForKey:@"isHidden"];
	_isWritable = [decoder decodeBoolForKey:@"isWritable"];
	_isPreviewable = [decoder decodeBoolForKey:@"isPreviewable"];

	[self updateCellTitle];
	[self updateUTI];

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:_fileURL forKey:@"fileURL"];
	[coder encodeObject:_name forKey:@"name"];
	[coder encodeBool:_isRegularFile forKey:@"isRegularFile"];
	[coder encodeInteger:_size forKey:@"size"];
	[coder encodeBool:_isHidden forKey:@"isHidden"];
	[coder encodeBool:_isWritable forKey:@"isWritable"];
	[coder encodeBool:_isPreviewable forKey:@"isPreviewable"];
}

+ (NSArray<SPFile*>*)filesAtURL:(NSURL*)URL error:(NSError**)error
{
	NSError* tmpError;
	NSArray<NSURL *> *URLs = [fileManager contentsOfDirectoryAtURL:URL includingPropertiesForKeys:@[NSURLIsRegularFileKey, NSURLFileSizeKey, NSURLIsWritableKey] options:0 error:&tmpError];

	if(!tmpError)
	{
		NSMutableArray* filesM = [NSMutableArray new];

		for(NSURL* URL in URLs)
		{
			SPFile* file = [[SPFile alloc] initWithFileURL:URL];
			[filesM addObject:file];
		}

		return [filesM copy];
	}
	else 
	{
		// On arm64e iOS 14 unc0ver the contents of "/" does not load because of an issue with /Developer (at least on one of my devices), hacky workaround for that because contentsOfDirectoryAtPath is not affected
		if(tmpError.code == 256 && [URL.path isEqualToString:@"/"])
		{
			NSError* tmpError2;
			NSArray<NSString*>* rootFiles = [fileManager contentsOfDirectoryAtPath:URL.path error:&tmpError2];

			if(rootFiles && !tmpError2)
			{
				NSMutableArray* filesM = [NSMutableArray new];
				for(NSString* rootFile in rootFiles)
				{
					SPFile* file = [[SPFile alloc] initWithFileURL:[NSURL fileURLWithPath:[@"/" stringByAppendingPathComponent:rootFile]]];
					[filesM addObject:file];
				}
				return [filesM copy];
			}
		}
	}

	if(error)
	{
		*error = tmpError;
	}

	return nil;
}

- (BOOL)conformsTo:(CFStringRef)UTI
{
	return UTTypeConformsTo((__bridge CFStringRef)_fileUTI, UTI);
}

- (BOOL)isHLSStream
{
	if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_10_0)
	{
		return NO;
	}

	return [_name.pathExtension isEqualToString:@"movpkg"];
}

- (BOOL)displaysAsRegularFile
{
	return _isRegularFile || [self isHLSStream];
}

- (BOOL)isEqual:(id)object
{
	if([object isKindOfClass:[SPFile class]])
	{
		SPFile* file = (SPFile*)object;

		if([self hash] == [file hash])
		{
			return YES;
		}
	}

	return NO;
}

- (NSUInteger)hash
{
	return [[self description] hash];
}

- (NSString*)description
{
	return [NSString stringWithFormat:@"<SPFile: filename = %@, fileURL = %@, size = %llu>", self.name, self.fileURL, self.size];
}

- (void)updateCellTitle
{
	#if !PREFERENCES && !SPRINGBOARD
	if([_name isUUID])
	{
		_applicationDisplayName = [fileManager applicationDisplayNameForURL:_fileURL];
	}

	if(_applicationDisplayName)
	{
		NSMutableAttributedString* cellTitleM = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ (%@)", _applicationDisplayName, _name]];

		NSDictionary* appNameAttributes =
			@{
				NSForegroundColorAttributeName : [UIColor colorWithRed:50.0f/255.0f green:100.0f/255.0f blue:150.0f/255.0f alpha:1.0f]
		};

		NSRange range = NSMakeRange(0, [_applicationDisplayName length]);

		[cellTitleM setAttributes:appNameAttributes range:range];

		_cellTitle = [cellTitleM copy];
	}
	else
	{
	#endif
		_cellTitle = [[NSAttributedString alloc] initWithString:_name];
	#if !PREFERENCES && !SPRINGBOARD
	}
	#endif
}

- (void)updateUTI
{
	CFStringRef fileExtension = (__bridge CFStringRef)[_fileURL pathExtension];
	_fileUTI = CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL));
}

@end
