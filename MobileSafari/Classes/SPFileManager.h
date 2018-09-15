// SPFileManager.h
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

#ifdef SIMJECT
typedef NSString *NSURLResourceKey;
typedef NSString *NSFileAttributeKey;
#endif

@interface SPFileManager : NSFileManager
{
	NSURL* _hardLinkURL;
	UIImage* _fileIcon;
	UIImage* _directoryIcon;
	NSDictionary* _displayNamesForPaths;
}

@property(nonatomic) BOOL isSandboxed;

+ (instancetype)sharedInstance;
#ifndef PREFERENCES
- (void)resetHardLinks;
- (NSURL*)createHardLinkForFileAtURL:(NSURL*)url onlyIfNeeded:(BOOL)needed;
- (BOOL)isSandboxedPath:(NSString*)path;
- (BOOL)isSandboxedURL:(NSURL*)url;
- (NSString*)applicationDisplayNameForURL:(NSURL*)URL;
#endif
- (BOOL)fileExistsAtURL:(NSURL*)url error:(NSError**)error;
- (BOOL)isDirectoryAtURL:(NSURL*)url error:(NSError**)error;
- (BOOL)URLResourceValue:(id*)value forKey:(NSURLResourceKey)key forURL:(NSURL*)url error:(NSError**)error;
- (NSString*)resolveSymlinkForPath:(NSString*)path;
- (NSURL*)resolveSymlinkForURL:(NSURL*)url;
- (UIImage*)fileIcon;
- (UIImage*)directoryIcon;

@end
