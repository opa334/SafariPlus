// SPDownload.m
// (c) 2017 opa334

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

#import "SPDownload.h"

#import "../Shared.h"
#import "SPDownloadInfo.h"
#import "SPPreferenceManager.h"

@implementation SPDownload

- (instancetype)initWithDownloadInfo:(SPDownloadInfo*)downloadInfo
{
  self = [super init];

  self.request = downloadInfo.request;
  self.filesize = downloadInfo.filesize;
  self.filename = downloadInfo.filename;
  self.targetPath = downloadInfo.targetPath;

  self.orgInfo = downloadInfo;

  return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];

  self.taskIdentifier = [decoder decodeIntegerForKey:@"taskIdentifier"];
  self.request = [decoder decodeObjectForKey:@"request"];
  self.filename = [decoder decodeObjectForKey:@"filename"];
  self.targetPath = [decoder decodeObjectForKey:@"targetPath"];
  self.filesize = [decoder decodeIntegerForKey:@"filesize"];
  self.totalBytesWritten = [decoder decodeIntegerForKey:@"totalBytesWritten"];
  self.paused = [decoder decodeBoolForKey:@"paused"];

  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [coder encodeInteger:self.taskIdentifier forKey:@"taskIdentifier"];
  [coder encodeObject:self.request forKey:@"request"];
  [coder encodeObject:self.filename forKey:@"filename"];
  [coder encodeObject:self.targetPath forKey:@"targetPath"];
  [coder encodeInteger:self.filesize forKey:@"filesize"];
  [coder encodeInteger:self.totalBytesWritten forKey:@"totalBytesWritten"];
  [coder encodeBool:self.paused forKey:@"paused"];
}

- (void)startDownload
{
  //Create and start download task from shared session with given request
  self.downloadTask = [[self.downloadManagerDelegate sharedDownloadSession]
    downloadTaskWithRequest:self.request];

  //Set taskIdentifier to make download resumable after Safari has been closed
  self.taskIdentifier = self.downloadTask.taskIdentifier;

  if(!self.paused)
  {
    //Start timer
    [self setTimerEnabled:YES];

    //Start downloading
    [self.downloadTask resume];
  }
}

- (void)startDownloadFromResumeData
{
  //Create downloadTask from resumeData
  self.downloadTask = [[self.downloadManagerDelegate sharedDownloadSession]
    downloadTaskWithResumeData:self.resumeData];

  //NSLog(@"SafariPlus - Got download task %@ for resume data %@", self.downloadTask, self.resumeData);

  //Get new identifier
  self.taskIdentifier = self.downloadTask.taskIdentifier;

  //Parse resumeData
  NSDictionary* resumeDataDict = [NSPropertyListSerialization
    propertyListWithData:self.resumeData options:NSPropertyListImmutable
    format:nil error:nil];

  //Get progress from resumeData
  NSNumber* progress = [resumeDataDict objectForKey:@"NSURLSessionResumeBytesReceived"];

  //Update totalBytesWritten
  self.totalBytesWritten = (int64_t)[progress longLongValue];

  if(!self.paused)
  {
    //Resume task
    [self.downloadTask resume];

    //Start timer
    [self setTimerEnabled:YES];
  }
}

- (void)setPaused:(BOOL)paused
{
  if(paused != _paused)
  {
    _paused = paused;
    if(paused)
    {
      //Suspend task
      [self.downloadTask suspend];

      //Stop timer
      [self setTimerEnabled:NO];
    }
    else
    {
      //Resume task
      [self.downloadTask resume];

      //Start timer
      [self setTimerEnabled:YES];
    }

    //Update data on disk
    [self.downloadManagerDelegate saveDownloadsToDisk];
  }
}

- (void)cancelDownload
{
  //Cancel task
  [self.downloadTask cancel];

  //Stop timer
  [self setTimerEnabled:NO];
}

- (void)setTimerEnabled:(BOOL)enabled
{
  if(enabled && !self.paused && ![self.speedTimer isValid])
  {
    dispatch_async(dispatch_get_main_queue(),
    ^{
      //Start timer that updates download speed every 0.5 seconds
      self.speedTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
        target:self selector:@selector(updateDownloadSpeed) userInfo:nil repeats:YES];

      //Set lastSpeedRefreshTime (of timer) to current time
      self.lastSpeedRefreshTime = [NSDate timeIntervalSinceReferenceDate];
    });
  }
  else if(!enabled && [self.speedTimer isValid])
  {
    dispatch_async(dispatch_get_main_queue(),
    ^{
      //Stop timer
      [self.speedTimer invalidate];
    });
  }
}

- (void)updateDownloadSpeed
{
  //Get current time
  NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];

  //Calculate bytes per second from last half a second
  self.bytesPerSecond = (self.totalBytesWritten - self.startBytes) / (currentTime - self.lastSpeedRefreshTime);

  //Set new values for next update
  self.startBytes = self.totalBytesWritten;
  self.lastSpeedRefreshTime = currentTime;

  //Update value on cell
  [self.cellDelegate updateDownloadSpeed:self.bytesPerSecond];
}

- (void)updateProgress:(int64_t)totalBytesWritten totalFilesize:(int64_t)filesize
{
  //Verify filesize
  if(self.filesize != filesize)
  {
    //Set filesize
    self.filesize = filesize;

    //Also update size of info
    self.orgInfo.filesize = filesize;

    //Check if enough space is left
    if(![self.downloadManagerDelegate enoughDiscspaceForDownloadInfo:self.orgInfo])
    {
      [self cancelDownload];

      [self.downloadManagerDelegate presentNotEnoughSpaceAlertWithDownloadInfo:self.orgInfo];
    }
  }

  //Update totalBytesWritten
  self.totalBytesWritten = totalBytesWritten;

  //Update cell
  [self.cellDelegate updateProgress:totalBytesWritten totalBytes:self.filesize animated:YES];
}

- (int64_t)remainingBytes
{
  return self.filesize - self.totalBytesWritten;
}

@end
