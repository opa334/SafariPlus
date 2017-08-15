//  Download.xm
// (c) 2017 opa334

#import "Download.h"

@implementation Download

- (void)startDownloadFromRequest:(NSURLRequest*)request
{
  //Create background session config and configure celluar access
  NSURLSessionConfiguration* config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:self.identifier];
  config.sessionSendsLaunchEvents = YES;
  config.allowsCellularAccess = !preferenceManager.onlyDownloadOnWifiEnabled;

  //Create session with configuration
  self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];

  //Create and start download task from session with given request
  self.downloadTask = [self.session downloadTaskWithRequest:request];
  [self.downloadTask resume];

  //Start timer that updates download speed every 0.5 seconds
  self.speedTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
    target:self selector:@selector(updateDownloadSpeed) userInfo:nil repeats:YES];

  //Set startTime (of timer) to current time
  self.startTime = [NSDate timeIntervalSinceReferenceDate];
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
  //Cancel session (to avoid possible memory leaks)
  [session invalidateAndCancel];

  //Stop timer
  [self.speedTimer invalidate];

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

//Problem: Files fail to download from some sites (e.g. dropbox) and the method below gets called, my implementation changes nothing

/*
- (void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
  NSLog(@"didReceiveChallenge %@", challenge.protectionSpace.authenticationMethod);

  if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
  {
    NSLog(@"Equal");
    SecTrustResultType result;
    SecTrustEvaluate(challenge.protectionSpace.serverTrust, &result);
    NSURLCredential* credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
  }
  else
  {
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
  }
  //https://stackoverflow.com/questions/5044477/determining-trust-with-nsurlconnection-and-nsurlprotectionspace
}
*/

- (void)cancelDownload
{
  //Stop downloading
  [self.downloadTask cancel];

  //Tell download manager that download should be cancelled
  [self.downloadManagerDelegate downloadCancelled:self];

  //Stop timer
  [self.speedTimer invalidate];
}

- (void)pauseDownload
{
  //Set paused state to YES
  self.paused = YES;

  //Pause download
  [self.downloadTask suspend];

  //Stop timer
  [self.speedTimer invalidate];
}

- (void)resumeDownload
{
  //Set paused state to NO
  self.paused = NO;

  //Resume download
  [self.downloadTask resume];

  //Restart timer
  self.speedTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
    target:self selector:@selector(updateDownloadSpeed) userInfo:nil repeats:YES];
}

@end
