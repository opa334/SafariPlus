@interface SPPFileManager : NSFileManager

+ (instancetype)sharedInstance;
- (NSString*)resolveSymlinkForPath:(NSString*)path;

@end
