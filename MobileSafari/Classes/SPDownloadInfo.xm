//  SPDownloadInfo.xm
// (c) 2017 opa334

#import "SPDownloadInfo.h"

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
