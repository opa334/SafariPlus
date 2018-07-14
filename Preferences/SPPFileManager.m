#import "SPPFileManager.h"

@implementation SPPFileManager

+ (instancetype)sharedInstance
{
    static SPPFileManager* sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,
    ^{
      //Initialise instance
      sharedInstance = [[SPPFileManager alloc] init];
    });

    return sharedInstance;
}

- (NSString*)resolveSymlinkForPath:(NSString*)path
{
  return path.stringByResolvingSymlinksInPath;
}

@end
