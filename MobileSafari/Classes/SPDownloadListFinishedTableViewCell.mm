// SPDownloadListTableViewCell.mm
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

#import "SPDownloadListFinishedTableViewCell.h"
#import "Extensions.h"

#import "SPDownloadListTableViewController.h"
#import "SPDownloadNavigationController.h"
#import "SPDownload.h"
#import "SPFileManager.h"
#import "../Util.h"

#import "SPCellButtonsView.h"
#import "SPCellIconLabelView.h"

@implementation SPDownloadListFinishedTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

	[self setUpContent];
	[self setUpConstraints];

	return self;
}

- (void)applyDownload:(SPDownload*)download
{
	_download = download;

	[self setFilesize:_download.filesize];

	_iconLabelView.label.text = download.filename;
	_iconLabelView.iconView.image = [fileManager iconForDownload:download];
	if(_download.wasCancelled)
	{
		_iconLabelView.label.textColor = [UIColor redColor];
	}
	else
	{
		_iconLabelView.label.textColor = [UIColor blackColor];
	}

	_targetLabel.text = _download.targetURL.path;

	[self updateButtons];
}

- (void)setUpContent
{
	//Enable seperators between imageViews
	[self setSeparatorInset:UIEdgeInsetsZero];

	//Make cell unselectable
	self.selectionStyle = UITableViewCellSelectionStyleNone;

	//Create size label for accessoryView
	_sizeLabel = [[UILabel alloc] init];

	_sizeLabel.textColor = [UIColor lightGrayColor];
	_sizeLabel.adjustsFontSizeToFitWidth = YES;
	_sizeLabel.textAlignment = NSTextAlignmentCenter;
	_sizeLabel.frame = CGRectMake(0,0, 45, 15);
	_sizeLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
	self.accessoryView = _sizeLabel;

	//Init custom views
	_iconLabelView = [[SPCellIconLabelView alloc] init];
	_iconLabelView.translatesAutoresizingMaskIntoConstraints = NO;

	_buttonsView = [[SPCellButtonsView alloc] init];
	_buttonsView.translatesAutoresizingMaskIntoConstraints = NO;

	_targetLabel = [[UILabel alloc] init];
	_targetLabel.translatesAutoresizingMaskIntoConstraints = NO;
	_targetLabel.font = [_targetLabel.font fontWithSize:10];
	_targetLabel.textAlignment = NSTextAlignmentCenter;

	[self.contentView addSubview:_iconLabelView];
	[self.contentView addSubview:_buttonsView];
	[self.contentView addSubview:_targetLabel];

	//Set up buttons
	[_buttonsView.topButton addTarget:self action:@selector(restartButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	[_buttonsView.topButton setImage:[[UIImage imageNamed:@"RestartButton" inBundle:SPBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];

	[_buttonsView.bottomButton addTarget:self action:@selector(openDirectoryButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	[_buttonsView.bottomButton setImage:[[UIImage imageNamed:@"OpenDirectoryButton" inBundle:SPBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
}

- (void)setUpConstraints
{
	[NSLayoutConstraint activateConstraints:@[
		//Horizontal
		 [NSLayoutConstraint constraintWithItem:_iconLabelView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
		  toItem:self.contentView attribute:NSLayoutAttributeLeadingMargin multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_iconLabelView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
		  toItem:_buttonsView attribute:NSLayoutAttributeLeading multiplier:1 constant:-7.5],
		 [NSLayoutConstraint constraintWithItem:_buttonsView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
		  toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:25],
		 [NSLayoutConstraint constraintWithItem:_buttonsView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
		  toItem:self.contentView attribute:NSLayoutAttributeTrailingMargin multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_targetLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
		  toItem:self.contentView attribute:NSLayoutAttributeLeadingMargin multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_targetLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
		  toItem:_buttonsView attribute:NSLayoutAttributeLeading multiplier:1 constant:-7.5],
		//Vertical
		 [NSLayoutConstraint constraintWithItem:_iconLabelView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
		  toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_targetLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
		  toItem:_iconLabelView attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_targetLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
		  toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:18],
		 [NSLayoutConstraint constraintWithItem:_targetLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
		  toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_buttonsView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
		  toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_buttonsView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
		  toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
	]];
}

- (void)updateButtons
{
	BOOL fileExists = [fileManager fileExistsAtURL:[_download.targetURL URLByAppendingPathComponent:_download.filename] error:nil];

	_buttonsView.displaysBottomButton = (fileExists && !_download.wasCancelled);
}

- (void)setFilesize:(int64_t)filesize
{
	if(filesize <= 0)
	{
		_sizeLabel.text = @"?";
	}
	else
	{
		_sizeLabel.text = [NSByteCountFormatter stringFromByteCount:filesize countStyle:NSByteCountFormatterCountStyleFile];
	}
}

- (void)restartButtonPressed
{
	[self.tableViewController restartDownload:_download forCell:self];
}

- (void)openDirectoryButtonPressed
{
	[(SPDownloadNavigationController*)self.tableViewController.navigationController showFileInBrowser:[_download.targetURL URLByAppendingPathComponent:_download.filename]];
}

@end
