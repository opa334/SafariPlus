//  SPDownloadInfo.xm
// (c) 2017 opa334

#import "SPDownloadInfo.h"
#import "SPDownload.h"

@implementation SPDownloadInfo

- (SPDownloadInfo*)initWithRequest:(NSURLRequest*)request
{
  self = [super init];

  self.request = request;

  return self;
}

- (SPDownloadInfo*)initWithImage:(UIImage*)image
{
  self = [super init];

  self.image = image;

  return self;
}

- (SPDownloadInfo*)initWithDownload:(SPDownload*)download
{
  self = [super init];

  self.request = download.request;
  self.filesize = download.filesize;
  self.filename = download.filename;
  self.targetPath = download.targetPath;

  return self;
}

- (NSURL*)pathURL
{
  return [self.targetPath URLByAppendingPathComponent:self.filename];
}

- (NSString*)pathString
{
  return [self pathURL].path;
}

- (BOOL)fileExists
{
  return [[NSFileManager defaultManager] fileExistsAtPath:[self pathString]];
}

- (void)removeExistingFile
{
  if([self fileExists])
  {
    [[NSFileManager defaultManager] removeItemAtPath:[self pathString] error:nil];
  }
}
@end
