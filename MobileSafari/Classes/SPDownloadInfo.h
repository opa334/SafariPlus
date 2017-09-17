//  SPDownloadInfo.h
// (c) 2017 opa334

@interface SPDownloadInfo : NSObject
@property (nonatomic) NSURLRequest* request;
@property (nonatomic) UIImage* image;
@property (nonatomic) int64_t filesize;
@property (nonatomic) NSString* filename;
@property (nonatomic) NSURL* targetPath;
@property (nonatomic) BOOL customPath;

- (SPDownloadInfo*)initWithRequest:(NSURLRequest*)request;
- (SPDownloadInfo*)initWithImage:(UIImage*)image;

- (NSURL*)pathURL;
- (NSString*)pathString;
- (BOOL)fileExists;
- (void)removeExistingFile;
@end
