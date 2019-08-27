@interface SPMediaFetcher : NSObject

+ (void)getURLForCurrentlyPlayingMediaWithCompletionHandler:(void (^)(NSURL* URL))completionHandler;

@end
