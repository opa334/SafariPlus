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

@class SPFilePickerNavigationController, SPDownload;

@interface SPDownloadTableViewCell : UITableViewCell <DownloadCellDelegate>
{
  NSString* _filename;
}

@property (nonatomic) UIProgressView* progressView;
@property (nonatomic) UIImageView* iconView;
@property (nonatomic) UILabel* filenameLabel;
@property (nonatomic) UILabel* percentProgress;
@property (nonatomic) UILabel* sizeProgress;
@property (nonatomic) UILabel* sizeSpeedSeperator;
@property (nonatomic) UILabel* downloadSpeed;
@property (nonatomic) UIButton* pauseResumeButton;
@property (nonatomic) UIButton* stopButton;
@property (nonatomic) BOOL paused;

@property (nonatomic, weak) SPDownload* download;

- (void)applyDownload:(SPDownload*)download;
- (void)initContent;
- (void)setUpContent;
- (void)setFilesize:(int64_t)filesize;
- (NSDictionary*)viewsForConstraints;
- (void)setUpConstraints;
- (void)setUpDelegate;
- (void)removeDelegate;
- (void)setPaused:(BOOL)paused;
- (void)pauseResumeButtonPressed;
- (void)stopButtonPressed;
@end
