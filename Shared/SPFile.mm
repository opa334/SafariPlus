// SPFile.mm
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

#import "SPFile.h"
#import "Extensions.h"
#import "NSFileManager+DirectorySize.h"

#if !SPRINGBOARD
#import "../MobileSafari/Util.h"
#import "../MobileSafari/Defines.h"
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

  #if !PREFERENCES && !SPRINGBOARD
	[self updateCellTitle];
	[self updateUTI];
	#endif

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

	#if !PREFERENCES && !SPRINGBOARD
	[self updateCellTitle];
	[self updateUTI];
	#endif

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
	NSError* xdError;
	NSArray<NSURL *> *URLs = [fileManager contentsOfDirectoryAtURL:URL includingPropertiesForKeys:@[NSURLIsRegularFileKey, NSURLFileSizeKey, NSURLIsWritableKey] options:nil error:&xdError];

	if(!xdError)
	{
		NSMutableArray* filesM = [NSMutableArray new];

		for(NSURL* URL in URLs)
		{
			SPFile* file = [[SPFile alloc] initWithFileURL:URL];
			[filesM addObject:file];
		}

		return [filesM copy];
	}

	*error = xdError;

	return nil;
}

- (BOOL)conformsTo:(CFStringRef)UTI
{
	return UTTypeConformsTo(_fileUTI, UTI);
}

- (BOOL)isHLSStream
{
	if(!NSClassFromString(@"AVAssetDownloadURLSession"))
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

#if !PREFERENCES && !SPRINGBOARD

- (void)updateCellTitle
{
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
		_cellTitle = [[NSAttributedString alloc] initWithString:_name];
	}
}

- (void)updateUTI
{
	CFStringRef fileExtension = (__bridge CFStringRef)[_fileURL pathExtension];
	_fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
}

#endif

@end
