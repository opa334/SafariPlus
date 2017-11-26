//  SPDownloadsTableViewController.h
// (c) 2017 opa334

#import "SPFileBrowserTableViewController.h"

@class SPDownload;

@interface UIApplication(iOS10)
- (void)openURL:(id)arg1 options:(id)arg2 completionHandler:(id)arg3;
@end

@interface SPDownloadsTableViewController : SPFileBrowserTableViewController <UIDocumentInteractionControllerDelegate> {}
@property (nonatomic) NSMutableArray* downloadsAtCurrentPath;
@property (nonatomic, strong) UIDocumentInteractionController* documentController;
@property (nonatomic) NSURL* tmpSymlinkURL;
@property (nonatomic) BOOL didSelectOptionFromDocumentController;
- (id)newCellWithDownload:(SPDownload*)download;
- (void)startPlayerWithMedia:(NSURL*)mediaURL;
- (void)openScheme:(NSString *)scheme;
@end
