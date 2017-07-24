//  directoryPicker.h
//  Headers for directoryPicker

// (c) 2017 opa334

#import "fileBrowser.h"
#import "downloadManager.h"

@interface directoryPickerNavigationController : fileBrowserNavigationController {}
@property (nonatomic) NSURLRequest* request;
@property (nonatomic) int64_t size;
@property (nonatomic) NSURL* path;
@property (nonatomic) NSString* fileName;
- (id)initWithRequest:(NSURLRequest*)request size:(int64_t)size path:(NSURL*)path fileName:(NSString*)fileName;
@end

@interface directoryPickerTableViewController : fileBrowserTableViewController {}
- (BOOL)canDownloadToPath:(NSURL*)pathURL;
- (void)chooseButtonPressed;
@end
