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

#import "SPDownloadInfo.h"

#import "SPDownload.h"
#import "../Util.h"
#import "SPFileManager.h"
#import "SPDownloadManager.h"

#import <MobileCoreServices/MobileCoreServices.h>

@implementation SPDownloadInfo

- (SPDownloadInfo*)initWithRequest:(NSURLRequest*)request
{
	self = [super init];

	_request = request;

	return self;
}

- (SPDownloadInfo*)initWithImage:(UIImage*)image
{
	self = [super init];

	_image = image;

	return self;
}

- (SPDownloadInfo*)initWithDownload:(SPDownload*)download
{
	self = [super init];

	_request = download.request;
	_filesize = download.filesize;
	_filename = download.filename;
	_targetURL = download.targetURL;

	return self;
}

- (NSURL*)pathURL
{
	return [_targetURL URLByAppendingPathComponent:_filename];
}

- (BOOL)fileExists
{
	return [fileManager fileExistsAtURL:[self pathURL] error:nil];
}

- (void)removeExistingFile
{
	if([self fileExists])
	{
		[fileManager removeItemAtURL:[self pathURL] error:nil];
	}
}

- (NSURL*)targetDirectoryURL
{
	return [self pathURL].URLByDeletingLastPathComponent;
}

- (BOOL)targetDirectoryExists
{
	NSURL* targetDirectoryURL = [self targetDirectoryURL];

	BOOL exists = [fileManager fileExistsAtURL:targetDirectoryURL error:nil];
	BOOL isDirectory = [fileManager isDirectoryAtURL:targetDirectoryURL error:nil];

	return exists && isDirectory;
}

- (BOOL)tryToCreateTargetDirectoryIfNotExist
{
	if(![self targetDirectoryExists])
	{
		BOOL created = [fileManager createDirectoryAtURL:[self targetDirectoryURL] withIntermediateDirectories:YES attributes:nil error:nil];
		return created;
	}

	return YES;
}

- (int64_t)filesize
{
	if(self.isHLSDownload)
	{
		return 0;
	}
	else
	{
		return _filesize;
	}
}

- (void)setFilename:(NSString*)filename
{
	if(self.isHLSDownload && ![filename.pathExtension isEqualToString:@"movpkg"])
	{
		_playlistExtension = filename.pathExtension;
		_filename = [[filename stringByDeletingPathExtension] stringByAppendingPathExtension:@"movpkg"];
	}
	else
	{
		_filename = filename;
	}
}

- (void)updateHLSForSuggestedFilename:(NSString*)suggestedFilename
{
	if(!downloadManager.HLSSupported)
	{
		self.isHLSDownload = NO;
		return;
	}

	CFStringRef suggestedFileExtension = (__bridge CFStringRef)[suggestedFilename pathExtension];
	CFStringRef suggestedFileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, suggestedFileExtension, NULL);
	if(UTTypeConformsTo(suggestedFileUTI, kUTTypePlaylist))
	{
		self.isHLSDownload = YES;
	}
	else
	{
		self.isHLSDownload = NO;
	}

	if(suggestedFileUTI) CFRelease(suggestedFileUTI);

	if(self.isHLSDownload)
	{
		self.filesize = 0;
	}
}

- (NSString*)filenameForTitle
{
	if([self.filename pathExtension])
	{
		NSMutableCharacterSet* invalidCharacters = [NSMutableCharacterSet characterSetWithCharactersInString:@":/"];
		[invalidCharacters formUnionWithCharacterSet:[NSCharacterSet newlineCharacterSet]];
		[invalidCharacters formUnionWithCharacterSet:[NSCharacterSet illegalCharacterSet]];
		[invalidCharacters formUnionWithCharacterSet:[NSCharacterSet controlCharacterSet]];

		return [[[self.title componentsSeparatedByCharactersInSet:invalidCharacters] componentsJoinedByString:@""] stringByAppendingPathExtension:[self.filename pathExtension]];
	}

	return self.filename;
}

@end
