// SPDownloadListTableViewCell.mm
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

#import "SPDownloadListFinishedTableViewCell.h"

#import "SPDownloadListTableViewController.h"
#import "SPDownloadNavigationController.h"
#import "SPDownload.h"
#import "../Shared.h"

@implementation SPDownloadListFinishedTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

	[self initContent];
	[self setUpConstraints];

	return self;
}

- (void)applyDownload:(SPDownload*)download
{
	_download = download;

	//Make cell unselectable
	self.selectionStyle = UITableViewCellSelectionStyleNone;

	[self setUpContent];
}

- (void)initContent
{
	//Get contentView
	UIView* contentView = self.contentView;

	_iconView = [UIImageView autolayoutView];
	[contentView addSubview:_iconView];

	_filenameLabel = [UILabel autolayoutView];
	[contentView addSubview:_filenameLabel];

	_restartButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_restartButton.translatesAutoresizingMaskIntoConstraints = NO;
	[contentView addSubview:_restartButton];

	_openDirectoryButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_openDirectoryButton.translatesAutoresizingMaskIntoConstraints = NO;
	[contentView addSubview:_openDirectoryButton];

	_targetLabel = [UILabel autolayoutView];
	[contentView addSubview:_targetLabel];

	//Enable seperators between imageViews
	[self setSeparatorInset:UIEdgeInsetsZero];
}

- (void)setUpContent
{
	//Create size label and set it to accessoryView
	UILabel* sizeLabel = [[UILabel alloc] init];

	sizeLabel.textColor = [UIColor lightGrayColor];
	sizeLabel.adjustsFontSizeToFitWidth = YES;
	sizeLabel.textAlignment = NSTextAlignmentCenter;
	sizeLabel.frame = CGRectMake(0,0, 45, 15);
	self.accessoryView = sizeLabel;

	[self setFilesize:_download.filesize];

	//nil out default label and image just to be sure (Can't use them in constraints)
	self.textLabel.text = nil;
	self.imageView.image = nil;

	//Set file icon
	_iconView.image = [UIImage imageNamed:@"File.png" inBundle:SPBundle compatibleWithTraitCollection:nil];

	//Set label text to file name
	_filenameLabel.text = _download.filename;
	_filenameLabel.font = self.textLabel.font;
	_filenameLabel.textAlignment = NSTextAlignmentLeft;
	if(_download.wasCancelled)
	{
		_filenameLabel.textColor = [UIColor redColor];
	}
	else
	{
		_filenameLabel.textColor = [UIColor blackColor];
	}

	//Configure restart button
	_restartButton.adjustsImageWhenHighlighted = YES;
	[_restartButton addTarget:self action:@selector(restartButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	[_restartButton setImage:[UIImage imageNamed:@"RestartButton.png" inBundle:SPBundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];

	//Create copy button and add it to contentView
	_openDirectoryButton.adjustsImageWhenHighlighted = YES;
	[_openDirectoryButton addTarget:self action:@selector(openDirectoryButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	[_openDirectoryButton setImage:[UIImage imageNamed:@"OpenDirectoryButton.png" inBundle:SPBundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];

	_targetLabel.font = [_targetLabel.font fontWithSize:10];
	_targetLabel.textAlignment = NSTextAlignmentCenter;
	_targetLabel.text = _download.targetURL.path;
}

- (void)setFilesize:(int64_t)filesize
{
	if(filesize <= 0)
	{
		((UILabel*)self.accessoryView).text = @"?";
	}
	else
	{
		((UILabel*)self.accessoryView).text = [NSByteCountFormatter stringFromByteCount:filesize countStyle:NSByteCountFormatterCountStyleFile];
	}
}

- (NSDictionary*)viewsForConstraints
{
	return NSDictionaryOfVariableBindings(_iconView, _filenameLabel, _restartButton, _openDirectoryButton, _targetLabel);
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
				     @"|-[_iconView(iconSize)]-15-[_filenameLabel]-smallSpace-[_restartButton(buttonSize)]-10-|" options:0 metrics:metrics views:views]];

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"|-[_targetLabel]-smallSpace-[_openDirectoryButton(buttonSize)]-10-|" options:0 metrics:metrics views:views]];

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"V:|-topSpace-[_iconView(iconSize)]" options:0 metrics:metrics views:views]];

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"V:|-topSpace-[_filenameLabel(iconSize)]" options:0 metrics:metrics views:views]];

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"V:|-4-[_restartButton(buttonSize)]" options:0 metrics:metrics views:views]];

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"V:[_openDirectoryButton(buttonSize)]-4-|" options:0 metrics:metrics views:views]];

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"V:[_targetLabel(19)]-3-|" options:0 metrics:metrics views:views]];
}

- (void)layoutSubviews
{
	[super layoutSubviews];

	//Round buttons
	_restartButton.imageView.layer.cornerRadius = _restartButton.imageView.frame.size.height / 2.0;
	_openDirectoryButton.imageView.layer.cornerRadius = _openDirectoryButton.imageView.frame.size.height / 2.0;
}

- (void)restartButtonPressed
{
	[self.tableViewController restartDownload:_download];
}

- (void)openDirectoryButtonPressed
{
	[(SPDownloadNavigationController*)self.tableViewController.navigationController openDirectoryInBrowser:_download.targetURL];
}

@end
