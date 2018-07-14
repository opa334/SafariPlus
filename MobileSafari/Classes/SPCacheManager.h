@interface SPCacheManager : NSObject
{
	NSURL* _cacheURL;
	NSMutableDictionary* _miscPlist;
	NSMutableDictionary* _desktopButtonStates;
}

+ (instancetype)sharedInstance;

- (void)updateExcludedFromBackup;

- (void)loadMiscPlist;
- (void)saveMiscPlist;
- (BOOL)firstStart;
- (void)firstStartDidSucceed;

- (NSMutableArray*)loadCachedDownloads;
- (void)saveCachedDownloads:(NSMutableArray*)cachedDownloads;
- (void)clearDownloadCache;

- (void)loadDesktopButtonStates;
- (void)saveDesktopButtonStates;
- (void)setDesktopButtonState:(BOOL)state forUUID:(NSUUID*)UUID;
- (BOOL)desktopButtonStateForUUID:(NSUUID*)UUID;

@end
