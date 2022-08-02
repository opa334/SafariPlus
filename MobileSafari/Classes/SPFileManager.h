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

#ifdef SIMJECT
typedef NSString *NSURLResourceKey;
typedef NSString *NSFileAttributeKey;
#endif

@class SPFile, SPDownload, LSDocumentProxy;

@interface SPFileManager : NSFileManager
{
	NSURL* _hardLinkURL;
	UIImage* _genericFileIcon;
	UIImage* _genericDirectoryIcon;
	NSDictionary* _displayNamesForPaths;
}

+ (instancetype)sharedInstance;
#ifndef PREFERENCES
- (void)resetHardLinks;
- (NSURL*)accessibleHardLinkForFileAtURL:(NSURL*)URL;
- (NSString*)applicationDisplayNameForURL:(NSURL*)URL;
- (BOOL)_isReadable:(const char*)str;
- (BOOL)_isWritable:(const char*)str;
- (BOOL)isPathReadable:(NSString*)path;
- (BOOL)isURLReadable:(NSURL*)URL;
- (BOOL)isPathWritable:(NSString*)path;
- (BOOL)isURLWritable:(NSURL*)URL;
#endif
- (void)populateApplicationDisplayNamesForPath;
- (NSArray<SPFile*>*)filesAtURL:(NSURL*)URL error:(NSError**)error;
- (BOOL)fileExistsAtURL:(NSURL*)url error:(NSError**)error;
- (BOOL)isDirectoryAtURL:(NSURL*)url error:(NSError**)error;
- (BOOL)URLResourceValue:(id*)value forKey:(NSURLResourceKey)key forURL:(NSURL*)url error:(NSError**)error;
- (NSString*)resolveSymlinkForPath:(NSString*)path;
- (NSURL*)resolveSymlinkForURL:(NSURL*)url;
- (UIImage*)iconForDownload:(SPDownload*)download;
- (UIImage*)iconForFile:(SPFile*)file;
- (UIImage*)fileIconForDocumentProxy:(LSDocumentProxy*)documentProxy;
- (UIImage*)genericFileIcon;
- (UIImage*)genericDirectoryIcon;

@end
