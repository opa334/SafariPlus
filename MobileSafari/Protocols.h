// Protocols.h
// (c) 2018 opa334

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

@class SPDownload, SPDownloadInfo, AVActivityButton;

@protocol filePickerDelegate<NSObject>
- (void)didSelectFiles:(NSArray*)URLs;
@end

@protocol DownloadNavigationControllerDelegate
@required
- (void)reloadBrowser;
- (void)reloadDownloadList;
- (void)reloadEverything;
@end

@protocol DownloadCellDelegate
@required
@property(nonatomic) BOOL paused;
- (void)updateDownloadSpeed:(int64_t)bytesPerSecond;
- (void)updateProgress:(int64_t)currentBytes totalBytes:(int64_t)totalBytes animated:(BOOL)animated;
- (void)setFilesize:(int64_t)filesize;
@end

@protocol DownloadManagerDelegate
@required
- (NSURLSession*)sharedDownloadSession;
- (void)forceCancelDownload:(SPDownload*)download;
- (void)saveDownloadsToDisk;
- (BOOL)enoughDiscspaceForDownloadInfo:(SPDownloadInfo*)downloadInfo;
- (void)presentNotEnoughSpaceAlertWithDownloadInfo:(SPDownloadInfo*)downloadInfo;
@end

@protocol CellDownloadDelegate
@required
- (void)setPaused:(BOOL)paused;
- (void)cancelDownload;
@optional
- (void)setBrowserCellDelegate:(id<DownloadCellDelegate>)cellDelegate;
- (void)setListCellDelegate:(id<DownloadCellDelegate>)listDelegate;
@end

@protocol SourceVideoDelegate
@required
@property(nonatomic,retain) AVActivityButton* downloadButton;
- (void)setBackgroundPlaybackActiveWithCompletion:(void (^)(void))completion;
@end
