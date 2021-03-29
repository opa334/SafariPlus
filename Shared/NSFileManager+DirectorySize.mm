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

@implementation NSFileManager (DirectorySize)

- (NSUInteger)sizeOfDirectoryAtURL:(NSURL*)directoryURL
{
	NSDirectoryEnumerator* enumerator = [[NSFileManager defaultManager] enumeratorAtURL:directoryURL
					     includingPropertiesForKeys:@[NSURLIsRegularFileKey,NSURLFileAllocatedSizeKey,NSURLTotalFileAllocatedSizeKey]
					     options:0
					     errorHandler:nil];

	NSUInteger size = 0;

	for(NSURL* itemURL in enumerator)
	{
		NSNumber* isRegularFile;
		NSError* error;
		[itemURL getResourceValue:&isRegularFile forKey:NSURLIsRegularFileKey error:&error];

		if(isRegularFile.boolValue)
		{
			NSNumber* totalFileAllocatedSize;
			[itemURL getResourceValue:&totalFileAllocatedSize forKey:NSURLTotalFileAllocatedSizeKey error:nil];
			if(totalFileAllocatedSize)
			{
				size += totalFileAllocatedSize.unsignedIntegerValue;
			}
			else
			{
				NSNumber* fileAllocatedSize;
				[itemURL getResourceValue:&fileAllocatedSize forKey:NSURLFileAllocatedSizeKey error:nil];
				if(fileAllocatedSize)
				{
					size += fileAllocatedSize.unsignedIntegerValue;
				}
			}
		}
	}

	return size;
}

@end
