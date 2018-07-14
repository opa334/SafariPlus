// SPDownload.h
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

#import "../Protocols.h"

@protocol CellDownloadDelegate;

@interface SPDownload : NSObject <CellDownloadDelegate>
@property (nonatomic) SPDownloadInfo* orgInfo;
@property (nonatomic) NSURLRequest* request;
@property (nonatomic) UIImage* image;
@property (nonatomic) int64_t filesize;
@property (nonatomic) NSString* filename;
@property (nonatomic) NSString* targetPath;
@property (nonatomic) BOOL paused;
@property (nonatomic) NSTimeInterval lastSpeedRefreshTime;
@property (nonatomic) NSTimer* speedTimer;
@property (nonatomic) int64_t startBytes;
@property (nonatomic) int64_t totalBytesWritten;
@property (nonatomic) int64_t bytesPerSecond;

@property (nonatomic) NSData* resumeData;
@property (nonatomic) NSUInteger taskIdentifier;
@property (nonatomic) NSURLSessionDownloadTask* downloadTask;

@property (nonatomic, weak) id<DownloadManagerDelegate> downloadManagerDelegate;
@property (nonatomic, weak) id<DownloadCellDelegate> cellDelegate;

- (instancetype)initWithDownloadInfo:(SPDownloadInfo*)downloadInfo;

- (void)startDownload;
- (void)startDownloadFromResumeData;
- (void)setPaused:(BOOL)paused;
- (void)cancelDownload;

- (void)setTimerEnabled:(BOOL)enabled;
- (void)updateDownloadSpeed;
- (void)updateProgress:(int64_t)totalBytesWritten totalFilesize:(int64_t)filesize;

- (int64_t)remainingBytes;
@end
