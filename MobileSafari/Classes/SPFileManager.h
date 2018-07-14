@interface SPFileManager : NSFileManager
{
	NSString* _hardLinkPath;
}

@property(nonatomic) BOOL isSandboxed;

+ (instancetype)sharedInstance;
- (void)resetHardLinks;
- (NSString*)createHardLinkForFileAtPath:(NSString*)path onlyIfNeeded:(BOOL)needed;
- (NSString*)resolveSymlinkForPath:(NSString*)path;

@end
