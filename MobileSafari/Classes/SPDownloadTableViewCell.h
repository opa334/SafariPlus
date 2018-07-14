// SPDownloadTableViewCell.h
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

#import "../Protocols.h"

@class SPFilePickerNavigationController;

@interface SPDownloadTableViewCell : UITableViewCell <DownloadCellDelegate>
{
  NSString* _filename;
  UIProgressView* _progressView;
  UILabel* _filenameLabel;
  UIImageView* _fileIcon;
  UILabel* _percentProgress;
  UILabel* _sizeProgress;
  UILabel* _sizeSpeedSeperator;
  UILabel* _downloadSpeed;
  UIButton* _pauseResumeButton;
  UIButton* _stopButton;
}
@property (nonatomic, weak) id<CellDownloadDelegate> downloadDelegate;

- (id)initWithDownload:(SPDownload*)download;
- (void)setPaused:(BOOL)paused;
- (void)pauseResumeButtonPressed;
- (void)stopButtonPressed;
@end
