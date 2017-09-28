//  SPDownloadInfo.h
// (c) 2017 opa334

@class SPDownload;

@interface SPDownloadInfo : NSObject
@property (nonatomic) NSURLRequest* request;
@property (nonatomic) UIImage* image;
@property (nonatomic) int64_t filesize;
@property (nonatomic) NSString* filename;
@property (nonatomic) NSURL* targetPath;
@property (nonatomic) BOOL customPath;
@property (nonatomic) BOOL isVideo;
@property (nonatomic) UIViewController* alternatePresentationController;

- (SPDownloadInfo*)initWithRequest:(NSURLRequest*)request;
- (SPDownloadInfo*)initWithImage:(UIImage*)image;
- (SPDownloadInfo*)initWithDownload:(SPDownload*)download;

- (NSURL*)pathURL;
- (NSString*)pathString;
- (BOOL)fileExists;
- (void)removeExistingFile;
@end
