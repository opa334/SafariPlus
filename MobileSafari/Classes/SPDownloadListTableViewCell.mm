// SPDownloadListTableViewCell.mm
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

#import "SPDownloadListTableViewCell.h"

#import "SPDownload.h"
#import "../Shared.h"

@implementation SPDownloadListTableViewCell

- (void)initContent
{
	[super initContent];

	_targetLabel = [UILabel autolayoutView];
	[self.contentView addSubview:_targetLabel];
}

- (void)setUpContent
{
	[super setUpContent];

	_targetLabel.font = [_targetLabel.font fontWithSize:10];
	_targetLabel.textAlignment = NSTextAlignmentCenter;
	_targetLabel.text = self.download.targetURL.path;
}

- (NSDictionary*)viewsForConstraints
{
	NSMutableDictionary* superViews = [[super viewsForConstraints] mutableCopy];

	[superViews addEntriesFromDictionary:NSDictionaryOfVariableBindings(_targetLabel)];

	return [superViews copy];
}

- (void)setUpConstraints
{
	//Get contentView
	UIView* contentView = self.contentView;

	//Create metrics and views for constraints
	NSDictionary *metrics = @{@"rightSpace" : @43.5, @"smallSpace" : @7.5, @"buttonSize" : @25.0, @"iconSize" : @30.0, @"topSpace" : @6.0};
	NSDictionary *views = [self viewsForConstraints];

	//Add dynamic constraints so the cell looks good across all devices
	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"|-[_sizeProgress(_downloadSpeed)]-smallSpace-[_sizeSpeedSeperator(8)]-smallSpace-[_downloadSpeed(_sizeProgress)]-rightSpace-|" options:0 metrics:metrics views:views]];

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"|-[_progressView]-smallSpace-[_stopButton(buttonSize)]-10-|" options:0 metrics:metrics views:views]];

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"|-[_percentProgress]-rightSpace-|" options:0 metrics:metrics views:views]];

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"|-[_iconView(iconSize)]-15-[_filenameLabel]-smallSpace-[_pauseResumeButton(buttonSize)]-10-|" options:0 metrics:metrics views:views]];

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"|-[_targetLabel]-smallSpace-[_stopButton(buttonSize)]-|" options:0 metrics:metrics views:views]];

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"V:|-topSpace-[_iconView(iconSize)]" options:0 metrics:metrics views:views]];

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"V:|-topSpace-[_filenameLabel(iconSize)]" options:0 metrics:metrics views:views]];

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"V:|-8-[_pauseResumeButton(buttonSize)]" options:0 metrics:metrics views:views]];

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"V:[_stopButton(buttonSize)]-8-|" options:0 metrics:metrics views:views]];

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"V:[_sizeProgress(8)]-41-|" options:0 metrics:metrics views:views]];

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"V:[_sizeSpeedSeperator(8)]-3-[_progressView(2.5)]-3-[_percentProgress(8)]-4-[_targetLabel(18)]-3-|" options:0 metrics:metrics views:views]];

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"V:[_downloadSpeed(8)]-41-|" options:0 metrics:metrics views:views]];
}

- (void)setUpDelegate
{
	self.download.listCellDelegate = self;
}

- (void)removeDelegate
{
	if([self isEqual:self.download.listCellDelegate])
	{
		self.download.listCellDelegate = nil;
	}
}

@end
