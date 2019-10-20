// Copyright (c) 2017-2019 Lars Fröder

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

#import "../Protocols.h"

@class SPDownload, TabDocument;

@interface SPDownloadInfo : NSObject
@property (nonatomic) NSURLRequest* request;
@property (nonatomic) UIImage* image;
@property (nonatomic) int64_t filesize;
@property (nonatomic) NSString* filename;
@property (nonatomic) NSString* title;
@property (nonatomic) NSURL* targetURL;
@property (nonatomic) BOOL customPath;
@property (nonatomic) id<SourceVideoDelegate> sourceVideo;
@property (nonatomic) TabDocument* sourceDocument;
@property (nonatomic) UIViewController* presentationController;
@property (nonatomic) CGRect sourceRect;
@property (nonatomic) BOOL isHLSDownload;
@property (nonatomic) NSString* playlistExtension;

- (SPDownloadInfo*)initWithRequest:(NSURLRequest*)request;
- (SPDownloadInfo*)initWithImage:(UIImage*)image;
- (SPDownloadInfo*)initWithDownload:(SPDownload*)download;

- (NSURL*)pathURL;
- (BOOL)fileExists;
- (void)removeExistingFile;

- (void)updateHLSForSuggestedFilename:(NSString*)suggestedFilename;
- (NSString*)filenameForTitle;
@end
