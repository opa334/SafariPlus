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

@class SPDownload, SPDownloadInfo, SPDownloadManager, SPFilePickerNavigationController, AVActivityButton, AVAssetDownloadURLSession;

@protocol filePickerDelegate<NSObject>
- (void)filePicker:(SPFilePickerNavigationController*)filePicker didSelectFiles:(NSArray*)URLs;
@end

@protocol DownloadNavigationControllerDelegate
@required
- (void)reloadBrowser;
- (void)reloadBrowserAnimated:(BOOL)animated;
- (void)reloadDownloadList;
- (void)reloadDownloadListAnimated:(BOOL)animated;
- (void)reloadEverything;
- (void)reloadEverythingAnimated:(BOOL)animated;
@end

@protocol DownloadObserverDelegate
@required
- (void)filesizeDidChangeForDownload:(SPDownload*)download;
- (void)expectedDurationDidChangeForDownload:(SPDownload*)download;
- (void)pauseStateDidChangeForDownload:(SPDownload*)download;
- (void)downloadSpeedDidChangeForDownload:(SPDownload*)download;
- (void)progressDidChangeForDownload:(SPDownload*)download shouldAnimateChange:(BOOL)shouldAnimate;
@end

@protocol DownloadsObserverDelegate
- (void)totalProgressDidChangeForDownloadManager:(SPDownloadManager*)downloadManager;
- (void)runningDownloadsCountDidChangeForDownloadManager:(SPDownloadManager*)downloadManager;
@end

@protocol DownloadManagerDelegate
@required
- (NSURLSession*)sharedDownloadSession;
- (AVAssetDownloadURLSession*)sharedAVDownloadSession;
- (void)forceCancelDownload:(SPDownload*)download;
- (void)saveDownloadsToDisk;
- (BOOL)enoughDiscspaceForDownloadInfo:(SPDownloadInfo*)downloadInfo;
- (void)presentNotEnoughSpaceAlertWithDownloadInfo:(SPDownloadInfo*)downloadInfo;
- (void)totalProgressDidChange;
- (void)runningDownloadsCountDidChange;
@end

@protocol SourceVideoDelegate
@required
@property (nonatomic,retain) AVActivityButton* downloadButton;
@end

@protocol SPDirectoryPickerDelegate
- (void)directoryPicker:(id)directoryPicker didSelectDirectoryAtURL:(NSURL*)selectedURL withFilename:(NSString*)filename;
@end

//iOS >=12.2
@protocol TabCollectionItem <NSObject>
@property (readonly, nonatomic) NSUUID *UUID;
@end
