// Copyright (c) 2017-2019 Lars Fröder

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import "SPFileBrowserTableViewController.h"
#import <QuickLook/QuickLook.h>

@class SPDownload, SPFile;

@interface UIApplication (iOS10)
- (void)openURL:(id)arg1 options:(id)arg2 completionHandler:(id)arg3;
@end

@interface SPDownloadBrowserTableViewController : SPFileBrowserTableViewController <UIDocumentInteractionControllerDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate>
{
	BOOL _filzaInstalled;
	NSArray<SPFile*>* _previewFiles;
}
@property (nonatomic) NSArray<SPDownload*>* downloadsAtCurrentURL;
@property (nonatomic) NSArray<SPDownload*>* displayedDownloads;
@property (nonatomic, strong) UIDocumentInteractionController* documentController;
@property (nonatomic, strong) QLPreviewController* previewController;
- (void)unselectRow;
- (void)startPlayerWithMedia:(NSURL*)mediaURL;
- (void)openScheme:(NSString *)scheme;
- (UIAlertAction*)previewActionForFile:(SPFile*)file;
- (UIAlertAction*)playActionForFile:(SPFile*)file;
- (UIAlertAction*)showContentActionForFile:(SPFile*)file withIndexPath:(NSIndexPath*)indexPath;
- (UIAlertAction*)openInActionForFile:(SPFile*)file;
- (UIAlertAction*)importToMediaLibraryActionForImageWithURL:(NSURL*)URL;
- (UIAlertAction*)importToMediaLibraryActionForVideoWithURL:(NSURL*)URL;
- (UIAlertAction*)showInFilzaActionForFile:(SPFile*)file;
- (UIAlertAction*)renameActionForFile:(SPFile*)file;
- (UIAlertAction*)deleteActionForFile:(SPFile*)file;
- (void)addButtonPressed;
@end
