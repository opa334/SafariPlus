// NSFileManager+DirectorySize.mm
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
