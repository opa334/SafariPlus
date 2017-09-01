//  Download.xm
// (c) 2017 opa334

#import "Download.h"

@implementation Download

- (id)initWithRequest:(NSURLRequest*)request
{
  self = [super init];
  self.request = request;
  return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];

  self.identifier = [decoder decodeObjectForKey:@"identifier"];
  self.request = [decoder decodeObjectForKey:@"request"];
  self.fileName = [decoder decodeObjectForKey:@"fileName"];
  self.filePath = [decoder decodeObjectForKey:@"filePath"];
  self.fileSize = [decoder decodeIntegerForKey:@"fileSize"];
  self.shouldReplace = [decoder decodeBoolForKey:@"shouldReplace"];
  self.paused = [decoder decodeBoolForKey:@"paused"];

  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [coder encodeObject:self.identifier forKey:@"identifier"];
  [coder encodeObject:self.request forKey:@"request"];
  [coder encodeObject:self.fileName forKey:@"fileName"];
  [coder encodeObject:self.filePath forKey:@"filePath"];
  [coder encodeInteger:self.fileSize forKey:@"fileSize"];
  [coder encodeBool:self.shouldReplace forKey:@"shouldReplace"];
  [coder encodeBool:self.paused forKey:@"paused"];
}

- (void)resumeFromDiskLoad
{
  self.resumedFromResumeData = NO;

  //Create background session config and configure celluar access
  NSURLSessionConfiguration* config = [NSURLSessionConfiguration
    backgroundSessionConfigurationWithIdentifier:self.identifier];

  config.sessionSendsLaunchEvents = YES;
  config.allowsCellularAccess = !preferenceManager.onlyDownloadOnWifiEnabled;

  //Create session with configuration (This will get didCompleteWithError called)
  self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];

  //If Safari has not been closed properly (eg. through a respring), the downloadTask
  //will continue in background. If that's the case, we need to fetch the existing task.
  [NSTimer scheduledTimerWithTimeInterval:0.05
    target:[NSBlockOperation blockOperationWithBlock:^
    {
      //After 0.05 seconds, check if download was not started with resumeData
      //Kinda dirty workaround?
      if(!self.resumedFromResumeData)
      {
        //Fetch existing task
        [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks,
          NSArray *uploadTasks, NSArray *downloadTasks)
        {
          self.downloadTask = downloadTasks.firstObject;
        }];

        //Start timer
        [self setTimerEnabled:YES];
      }
    }]
    selector:@selector(main)
    userInfo:nil
    repeats:NO
    ];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
  if(error)
  {
    //Get resumeData
    NSData* resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];

    if(resumeData)
    {
      //Set resumeData property to YES
      self.resumedFromResumeData = YES;

      //Create downloadTask from resumeData
      self.downloadTask = [session downloadTaskWithResumeData:resumeData];

      //Parse resumeData
      NSDictionary* resumeDataDict = [NSPropertyListSerialization
        propertyListWithData:resumeData options:NSPropertyListImmutable
        format:nil error:nil];

      //Get progress from resumeData
      NSNumber* progress = [resumeDataDict objectForKey:@"NSURLSessionResumeBytesReceived"];
      self.totalBytesWritten = (int64_t)[progress longLongValue];

      if(!self.paused)
      {
        //Not paused -> resume download
        [self.downloadTask resume];

        //Start timer
        [self setTimerEnabled:YES];
      }
      return;
    }
  }
  //Cancel session (to avoid possible memory leaks)
  [session invalidateAndCancel];
}

- (void)startDownload
{
  //Create background session config and configure celluar access
  NSURLSessionConfiguration* config = [NSURLSessionConfiguration
    backgroundSessionConfigurationWithIdentifier:self.identifier];

  config.sessionSendsLaunchEvents = YES;
  config.allowsCellularAccess = !preferenceManager.onlyDownloadOnWifiEnabled;

  //Create session with configuration
  self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];

  //Create and start download task from session with given request
  self.downloadTask = [self.session downloadTaskWithRequest:self.request];
  [self.downloadTask resume];

  //Start timer
  [self setTimerEnabled:YES];
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

      //Set startTime (of timer) to current time
      self.startTime = [NSDate timeIntervalSinceReferenceDate];
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
  self.bytesPerSecond = (self.totalBytesWritten - self.startBytes) / (currentTime - self.startTime);

  //Set new values for next update
  self.startBytes = self.totalBytesWritten;
  self.startTime = currentTime;

  if(self.cellDelegate)
  {
    //Update value on cell
    [self.cellDelegate updateDownloadSpeed:self.bytesPerSecond];
  }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
  [self setTimerEnabled:NO];

  //Send location to download manager
  [self.downloadManagerDelegate downloadFinished:self withLocation:location];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten
totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
  //Update totalBytesWritten property
  self.totalBytesWritten = totalBytesWritten;

  if(self.cellDelegate)
  {
    //Update stuff in cell
    [self.cellDelegate updateProgress:totalBytesWritten totalBytes:totalBytesExpectedToWrite animated:YES];
  }
}

- (void)cancelDownload
{
  //Stop downloading
  [self.downloadTask cancel];

  //Tell download manager that download should be cancelled
  [self.downloadManagerDelegate downloadCancelled:self];

  //Stop timer
  [self setTimerEnabled:NO];
}

- (void)pauseDownload
{
  //Set paused state to YES
  self.paused = YES;

  //Pause download
  [self.downloadTask suspend];

  //Stop timer
  [self setTimerEnabled:NO];

  //Update data on disk
  [self.downloadManagerDelegate saveDownloadsToDisk];
}

- (void)resumeDownload
{
  //Set paused state to NO
  self.paused = NO;

  //Resume download
  [self.downloadTask resume];

  //Restart timer
  [self setTimerEnabled:YES];

  //Update data on disk
  [self.downloadManagerDelegate saveDownloadsToDisk];
}

@end
