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

#import "../Protocols.h"

@class AVURLAsset;

@interface SPDownload : NSObject
@property (nonatomic) SPDownloadInfo* orgInfo;
@property (nonatomic) NSURLRequest* request;
@property (nonatomic) UIImage* image;
@property (nonatomic) int64_t filesize;
@property (nonatomic) NSString* filename;
@property (nonatomic) NSURL* targetURL;
@property (nonatomic) BOOL paused;
@property (nonatomic) NSTimeInterval lastSpeedRefreshTime;
@property (nonatomic) NSTimer* speedTimer;
@property (nonatomic) int64_t startBytes;
@property (nonatomic) int64_t totalBytesWritten;
@property (nonatomic) int64_t bytesPerSecond;
@property (nonatomic) BOOL startedFromPrivateBrowsingMode;
@property (nonatomic) BOOL isHLSDownload;
@property (nonatomic) CGFloat expectedDuration;
@property (nonatomic) CGFloat secondsLoaded;

@property (nonatomic) NSData* resumeData;
@property (nonatomic) NSUInteger taskIdentifier;
@property (nonatomic) __kindof NSURLSessionTask* downloadTask;

@property (nonatomic) BOOL wasCancelled;

@property (nonatomic, weak) id<DownloadManagerDelegate> downloadManagerDelegate;
@property (nonatomic) NSHashTable<id<DownloadObserverDelegate>>* observerDelegates;

- (instancetype)initWithDownloadInfo:(SPDownloadInfo*)downloadInfo;

- (void)startDownload;
- (void)parseResumeData;
- (void)setPaused:(BOOL)paused;
- (void)cancelDownload;
- (void)setPaused:(BOOL)paused forced:(BOOL)forced;
- (void)pauseStateChanged;

- (void)setTimerEnabled:(BOOL)enabled;
- (void)updateDownloadSpeed;
- (void)updateProgressForSecondsLoaded:(CGFloat)secondsLoaded expectedDuration:(CGFloat)expectedDuration;
- (void)updateProgressForTotalBytesWritten:(int64_t)totalBytesWritten totalFilesize:(int64_t)filesize;
- (void)updateProgress;

- (int64_t)remainingBytes;

- (void)runBlockOnObserverDelegates:(void (^)(id<DownloadObserverDelegate> receiverDelegate))block onMainThread:(BOOL)mainThread;
- (void)addObserverDelegate:(id<DownloadObserverDelegate>)observerDelegate;
- (void)removeObserverDelegate:(id<DownloadObserverDelegate>)observerDelegate;
@end
