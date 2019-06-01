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

@implementation SPDownloadListFinishedTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

	_showsOpenButton = YES;

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

	//nil out default label and image just to be sure (Can't use them in constraints)
	self.textLabel.text = nil;
	self.imageView.image = nil;

	_iconView = [UIImageView autolayoutView];
	_iconView.image = [UIImage imageNamed:@"File.png" inBundle:SPBundle compatibleWithTraitCollection:nil];
	[contentView addSubview:_iconView];

	_filenameLabel = [UILabel autolayoutView];
	_filenameLabel.font = self.textLabel.font;
	_filenameLabel.textAlignment = NSTextAlignmentLeft;
	[contentView addSubview:_filenameLabel];

	_restartButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_restartButton.translatesAutoresizingMaskIntoConstraints = NO;
	_restartButton.adjustsImageWhenHighlighted = YES;
	[_restartButton addTarget:self action:@selector(restartButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	[_restartButton setImage:[UIImage imageNamed:@"RestartButton.png" inBundle:SPBundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
	[contentView addSubview:_restartButton];

	_openDirectoryButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_openDirectoryButton.translatesAutoresizingMaskIntoConstraints = NO;
	_openDirectoryButton.adjustsImageWhenHighlighted = YES;
	[_openDirectoryButton addTarget:self action:@selector(openDirectoryButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	[_openDirectoryButton setImage:[UIImage imageNamed:@"OpenDirectoryButton.png" inBundle:SPBundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
	[contentView addSubview:_openDirectoryButton];

	_targetLabel = [UILabel autolayoutView];
	_targetLabel.font = [_targetLabel.font fontWithSize:10];
	_targetLabel.textAlignment = NSTextAlignmentCenter;
	[contentView addSubview:_targetLabel];

	//Enable seperators between imageViews
	[self setSeparatorInset:UIEdgeInsetsZero];

	//Create size label and set it to accessoryView
	UILabel* sizeLabel = [[UILabel alloc] init];

	sizeLabel.textColor = [UIColor lightGrayColor];
	sizeLabel.adjustsFontSizeToFitWidth = YES;
	sizeLabel.textAlignment = NSTextAlignmentCenter;
	sizeLabel.frame = CGRectMake(0,0, 45, 15);
	self.accessoryView = sizeLabel;
}

- (void)setUpContent
{
	[self setFilesize:_download.filesize];

	//Set label text to file name
	_filenameLabel.text = _download.filename;
	if(_download.wasCancelled)
	{
		_filenameLabel.textColor = [UIColor redColor];
	}
	else
	{
		_filenameLabel.textColor = [UIColor blackColor];
	}

	_targetLabel.text = _download.targetURL.path;

	BOOL fileExists = [fileManager fileExistsAtURL:[_download.targetURL URLByAppendingPathComponent:_download.filename] error:nil];

	self.showsOpenButton = (fileExists && !_download.wasCancelled);
}

- (void)setShowsOpenButton:(BOOL)showsOpenButton
{
	if(_showsOpenButton != showsOpenButton)
	{
		_showsOpenButton = showsOpenButton;

		[self.contentView setNeedsLayout];

		_openDirectoryButton.enabled = _showsOpenButton;
		_openDirectoryButton.hidden = !_showsOpenButton;

		//This is pretty dirty but trust me, activating / deactivating constraints on demand really did not want to work
		[self.contentView removeConstraints:_allConstraints];
		[self setUpConstraints];

		[self.contentView setNeedsLayout];
	}
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

	_allConstraints = [NSMutableArray new];

	//Add dynamic constraints so the cell looks good across all devices

	if(_showsOpenButton)
	{
		[_allConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:
						      @"|-[_targetLabel]-smallSpace-[_openDirectoryButton(buttonSize)]-10-|" options:0 metrics:metrics views:views]];

		[_allConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:
						      @"V:|-4-[_restartButton(buttonSize)]-[_openDirectoryButton(buttonSize)]-4-|" options:0 metrics:metrics views:views]];
	}
	else
	{
		[_allConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:
						      @"|-[_targetLabel]-42.5-|" options:0 metrics:metrics views:views]];

		[_allConstraints addObject:[NSLayoutConstraint constraintWithItem:_restartButton
					    attribute:NSLayoutAttributeHeight
					    relatedBy:NSLayoutRelationEqual
					    toItem:nil
					    attribute:NSLayoutAttributeNotAnAttribute
					    multiplier:1
					    constant:25]];

		[_allConstraints addObject:[NSLayoutConstraint constraintWithItem:_restartButton
					    attribute:NSLayoutAttributeCenterY
					    relatedBy:NSLayoutRelationEqual
					    toItem:self.contentView
					    attribute:NSLayoutAttributeCenterY
					    multiplier:1
					    constant:0]];
	}

	[_allConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:
					      @"|-[_iconView(iconSize)]-15-[_filenameLabel]-smallSpace-[_restartButton(buttonSize)]-10-|" options:0 metrics:metrics views:views]];

	[_allConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:
					      @"V:|-topSpace-[_iconView(iconSize)]" options:0 metrics:metrics views:views]];

	[_allConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:
					      @"V:|-topSpace-[_filenameLabel(iconSize)]" options:0 metrics:metrics views:views]];

	[_allConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:
					      @"V:[_targetLabel(19)]-3-|" options:0 metrics:metrics views:views]];

	[contentView addConstraints:_allConstraints];
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
	[self.tableViewController restartDownload:_download forCell:self];
}

- (void)openDirectoryButtonPressed
{
	[(SPDownloadNavigationController*)self.tableViewController.navigationController showFileInBrowser:[_download.targetURL URLByAppendingPathComponent:_download.filename]];
}

@end
