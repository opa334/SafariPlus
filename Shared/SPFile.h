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

@interface SPFile : NSObject

@property (nonatomic, readonly) NSURL* fileURL;
@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) NSString* applicationDisplayName;
@property (nonatomic, readonly) NSAttributedString* cellTitle;
@property (nonatomic, readonly) BOOL isRegularFile;
@property (nonatomic, readonly) int64_t size;
@property (nonatomic, readonly) BOOL isHidden;
@property (nonatomic, readonly) BOOL isWritable;
@property (nonatomic, readonly) NSString* fileUTI;
@property (nonatomic, readonly) BOOL isPreviewable;

+ (NSArray<SPFile*>*)filesAtURL:(NSURL*)URL error:(NSError**)error;

- (instancetype)initWithFileURL:(NSURL*)fileURL;

- (BOOL)conformsTo:(CFStringRef)UTI;

- (BOOL)isHLSStream;
- (BOOL)displaysAsRegularFile;

- (void)updateCellTitle;
- (void)updateUTI;

@end
