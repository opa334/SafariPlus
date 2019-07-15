// Protocols.h
// (c) 2017 - 2019 opa334

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

@class SPDownload, SPDownloadInfo, SPDownloadManager, SPFilePickerNavigationController, AVActivityButton;

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
- (void)setBackgroundPlaybackActiveWithCompletion:(void (^)(void))completion;
@end

@protocol SPDirectoryPickerDelegate
- (void)directoryPicker:(id)directoryPicker didSelectDirectoryAtURL:(NSURL*)selectedURL withFilename:(NSString*)filename;
@end

//iOS >=12.2
@protocol TabCollectionItem <NSObject>
@property (readonly, nonatomic) NSUUID *UUID;
@end
