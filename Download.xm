//  Download.xm
// (c) 2017 opa334

#import "Download.h"

@implementation Download

- (void)startDownloadFromRequest:(NSURLRequest*)request
{
  NSURLSessionConfiguration* config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:self.identifier];
  config.sessionSendsLaunchEvents = YES;
  config.allowsCellularAccess = !preferenceManager.onlyDownloadOnWifiEnabled;

  self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];

  self.downloadTask = [self.session downloadTaskWithRequest:request];
  [self.downloadTask resume];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
  [session invalidateAndCancel];
  [self.downloadManagerDelegate downloadFinished:self withLocation:location];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten
totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
  self.updateCount++;
  self.totalBytesWritten = totalBytesWritten;
  int64_t bytesPerSecond = (totalBytesWritten - self.startBytes) / ([NSDate timeIntervalSinceReferenceDate] - self.startTime);

  if(self.cellDelegate)
  {
    [self.cellDelegate updateProgress:totalBytesWritten totalBytes:totalBytesExpectedToWrite bytesPerSecond:bytesPerSecond animated:YES];
  }

  if(self.updateCount >= 40) //refreshing speed every 40 calls
  {
    self.startTime = [NSDate timeIntervalSinceReferenceDate];
    self.startBytes = totalBytesWritten;
    self.updateCount = 0;
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
  [self.downloadTask cancel];
  [self.downloadManagerDelegate downloadCancelled:self];
}

- (void)pauseDownload
{
  self.paused = YES;
  [self.downloadTask suspend];
}

- (void)resumeDownload
{
  self.paused = NO;
  self.updateCount = 40;
  [self.downloadTask resume];
}

@end
