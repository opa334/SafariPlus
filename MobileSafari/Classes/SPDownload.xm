//  SPDownload.xm
// (c) 2017 opa334

#import "SPDownload.h"

@implementation SPDownload

- (instancetype)initWithDownloadInfo:(SPDownloadInfo*)downloadInfo
{
  self = [super init];

  self.request = downloadInfo.request;
  self.filesize = downloadInfo.filesize;
  self.filename = downloadInfo.filename;
  self.targetPath = downloadInfo.targetPath;

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

  //Set taskIdentifier to make downloade resumable after Safari has been closed
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
  //Set filesize
  self.filesize = filesize;

  //Update totalBytesWritten
  self.totalBytesWritten = totalBytesWritten;

  //Update cell
  [self.cellDelegate updateProgress:totalBytesWritten totalBytes:self.filesize animated:YES];
}

@end
