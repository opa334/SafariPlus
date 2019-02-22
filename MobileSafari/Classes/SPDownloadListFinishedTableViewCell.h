// SPDownloadListTableViewCell.h
// (c) 2019 opa334

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

#import "SPDownloadTableViewCell.h"

@class SPDownload, SPDownloadListTableViewController;

@interface SPDownloadListFinishedTableViewCell : UITableViewCell
{
	SPDownload* _download;
}

@property (nonatomic) UIImageView* iconView;
@property (nonatomic) UILabel* filenameLabel;
@property (nonatomic) UIButton* restartButton;
@property (nonatomic) UIButton* openDirectoryButton;
@property (nonatomic) UILabel* targetLabel;

@property (nonatomic, weak) SPDownloadListTableViewController* tableViewController;

- (void)initContent;
- (void)applyDownload:(SPDownload*)download;
- (void)setUpContent;
- (NSDictionary*)viewsForConstraints;
- (void)setUpConstraints;
- (void)restartButtonPressed;
- (void)openDirectoryButtonPressed;
@end
