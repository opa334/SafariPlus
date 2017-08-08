//  directoryPickerNavigationController.h
// (c) 2017 opa334

#import "directoryPickerTableViewController.h"
#import "fileBrowserNavigationController.h"
#import "downloadManager.h"

@interface directoryPickerNavigationController : fileBrowserNavigationController {}
@property (nonatomic) NSURLRequest* request;
@property (nonatomic) int64_t size;
@property (nonatomic) NSURL* path;
@property (nonatomic) NSString* fileName;
@property (nonatomic) BOOL imageDownload;
@property (nonatomic) UIImage* image;
- (id)initWithRequest:(NSURLRequest*)request size:(int64_t)size path:(NSURL*)path fileName:(NSString*)fileName;
- (id)initWithImage:(UIImage*)image fileName:(NSString*)fileName;
@end
