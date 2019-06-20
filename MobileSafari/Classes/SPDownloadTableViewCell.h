// SPDownloadTableViewCell.h
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

#import "../Protocols.h"

@class SPFilePickerNavigationController, SPDownload, SPCellIconLabelView, SPCellDownloadProgressView, SPCellButtonsView;

@interface SPDownloadTableViewCell : UITableViewCell <DownloadObserverDelegate>
{
	NSString* _filename;
}

@property (nonatomic) SPCellIconLabelView* iconLabelView;
@property (nonatomic) SPCellDownloadProgressView* downloadProgressView;
@property (nonatomic) SPCellButtonsView* buttonsView;
@property (nonatomic) UILabel* sizeLabel;

@property (nonatomic) NSLayoutConstraint* bottomConstraint;

@property (nonatomic, weak) SPDownload* download;

- (void)applyDownload:(SPDownload*)download;
- (void)setUpContent;
- (void)setUpConstraints;
- (void)setUpDelegate;
- (void)removeDelegate;
- (void)pauseResumeButtonPressed;
- (void)stopButtonPressed;
@end
