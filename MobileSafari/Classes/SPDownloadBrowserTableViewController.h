// SPDownloadBrowserTableViewController.h
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

#import "SPFileBrowserTableViewController.h"

@class SPDownload;

@interface UIApplication (iOS10)
- (void)openURL:(id)arg1 options:(id)arg2 completionHandler:(id)arg3;
@end

@interface SPDownloadBrowserTableViewController : SPFileBrowserTableViewController <UIDocumentInteractionControllerDelegate>
{
	BOOL _filzaInstalled;
}
@property (nonatomic) NSArray<SPDownload*>* downloadsAtCurrentURL;
@property (nonatomic) NSArray<SPDownload*>* displayedDownloads;
@property (nonatomic, strong) UIDocumentInteractionController* documentController;
- (void)unselectRow;
- (void)startPlayerWithMedia:(NSURL*)mediaURL;
- (void)openScheme:(NSString *)scheme;
- (UIAlertAction*)playActionForFile:(SPFile*)file;
- (UIAlertAction*)openInActionForFile:(SPFile*)file;
- (UIAlertAction*)importToMediaLibraryActionForImageWithURL:(NSURL*)URL;
- (UIAlertAction*)importToMediaLibraryActionForVideoWithURL:(NSURL*)URL;
//- (UIAlertAction*)importToMusicLibraryActionForFile:(SPFile*)file;
- (UIAlertAction*)showInFilzaActionForFile:(SPFile*)file;
- (UIAlertAction*)renameActionForFile:(SPFile*)file;
- (UIAlertAction*)deleteActionForFile:(SPFile*)file;
- (void)addButtonPressed;
@end
