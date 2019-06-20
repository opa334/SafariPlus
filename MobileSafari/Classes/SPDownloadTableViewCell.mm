// SPDownloadTableViewCell.mm
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

#import "SPDownloadTableViewCell.h"
#import "Extensions.h"

#import "../Util.h"
#import "SPDownload.h"
#import "SPDownloadManager.h"
#import "SPFileTableViewCell.h"
#import "SPLocalizationManager.h"
#import "SPCellIconLabelView.h"
#import "SPCellDownloadProgressView.h"
#import "SPCellButtonsView.h"
#import "SPFileManager.h"
#import "SPPreferenceManager.h"

@implementation SPDownloadTableViewCell

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

	[self setUpDelegate];

	_iconLabelView.label.text = download.filename;
	_iconLabelView.iconView.image = [fileManager iconForDownload:download];

	if(preferenceManager.privateModeDownloadHistoryDisabled)
	{
		if(download.startedFromPrivateBrowsingMode)
		{
			_iconLabelView.alpha = 0.5;
		}
		else
		{
			_iconLabelView.alpha = 1.0;
		}
	}
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

	_downloadProgressView = [[SPCellDownloadProgressView alloc] init];
	_downloadProgressView.translatesAutoresizingMaskIntoConstraints = NO;

	_buttonsView = [[SPCellButtonsView alloc] init];
	_buttonsView.translatesAutoresizingMaskIntoConstraints = NO;

	[self.contentView addSubview:_iconLabelView];
	[self.contentView addSubview:_downloadProgressView];
	[self.contentView addSubview:_buttonsView];

	//Set up buttons
	[_buttonsView.topButton addTarget:self action:@selector(pauseResumeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	[_buttonsView.topButton setImage:[[UIImage imageNamed:@"PauseButton.png" inBundle:SPBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
	[_buttonsView.topButton setImage:[[UIImage imageNamed:@"ResumeButton.png" inBundle:SPBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateSelected];

	[_buttonsView.bottomButton addTarget:self action:@selector(stopButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	[_buttonsView.bottomButton setImage:[[UIImage imageNamed:@"StopButton.png" inBundle:SPBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
}

- (void)setUpConstraints
{
	_bottomConstraint = [NSLayoutConstraint constraintWithItem:_downloadProgressView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
			     toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:0],

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
		 [NSLayoutConstraint constraintWithItem:_downloadProgressView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
		  toItem:self.contentView attribute:NSLayoutAttributeLeadingMargin multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_downloadProgressView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
		  toItem:_buttonsView attribute:NSLayoutAttributeLeading multiplier:1 constant:-7.5],
		//Vertical
		 [NSLayoutConstraint constraintWithItem:_iconLabelView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
		  toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_downloadProgressView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
		  toItem:_iconLabelView attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
		 _bottomConstraint,
		 [NSLayoutConstraint constraintWithItem:_buttonsView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
		  toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_buttonsView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
		  toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
	]];
}

- (void)setUpDelegate
{
	[_download addObserverDelegate:self];
}

- (void)removeDelegate
{
	[_download removeObserverDelegate:self];
}

- (void)prepareForReuse
{
	[super prepareForReuse];

	[self removeDelegate];
}

- (void)pauseResumeButtonPressed
{
	_download.paused = !_download.paused;
}

- (void)stopButtonPressed
{
	[_download cancelDownload];
}

- (void)filesizeDidChangeForDownload:(SPDownload*)download
{
	if(download.filesize <= 0)
	{
		_sizeLabel.text = @"?";
	}
	else
	{
		_sizeLabel.text = [NSByteCountFormatter stringFromByteCount:download.filesize countStyle:NSByteCountFormatterCountStyleFile];
	}
}

- (void)pauseStateDidChangeForDownload:(SPDownload*)download
{
	UIColor* colorToSet;

	if(download.paused)
	{
		colorToSet = [UIColor grayColor];
	}
	else
	{
		colorToSet = [UIColor colorWithRed:0.45 green:0.65 blue:0.95 alpha:1.0];
	}

	dispatch_async(dispatch_get_main_queue(), ^
	{
		[_downloadProgressView setColor:colorToSet];
		_buttonsView.topButton.selected = download.paused;
	});
}

- (void)downloadSpeedDidChangeForDownload:(SPDownload*)download
{
	//Create string for bytesPerSecond
	NSString* speedString = [NSString stringWithFormat:@"%@/s",
				 [NSByteCountFormatter stringFromByteCount:download.bytesPerSecond
				  countStyle:NSByteCountFormatterCountStyleFile]];

	dispatch_async(dispatch_get_main_queue(), ^
	{
		//Update _download speed
		_downloadProgressView.downloadSpeedLabel.text = speedString;
	});
}

- (void)progressDidChangeForDownload:(SPDownload*)download shouldAnimateChange:(BOOL)shouldAnimate
{
	CGFloat progress;
	NSString* sizeString = [NSByteCountFormatter stringFromByteCount:download.totalBytesWritten
				countStyle:NSByteCountFormatterCountStyleFile];
	NSString* percentProgressString;

	if(download.filesize <= 0)
	{
		progress = 0;
		percentProgressString = [localizationManager localizedSPStringForKey:@"SIZE_UNKNOWN"];
	}
	else
	{
		//Calculate progress and create strings for everything
		progress = (CGFloat)download.totalBytesWritten / (CGFloat)download.filesize;
		percentProgressString = [NSString stringWithFormat:@"%.1f%%", progress * 100];
	}

	dispatch_async(dispatch_get_main_queue(), ^
	{
		//Update cell components from progress
		[_downloadProgressView.progressView setProgress:progress animated:shouldAnimate];
		_downloadProgressView.percentProgressLabel.text = percentProgressString;
		_downloadProgressView.sizeProgressLabel.text = sizeString;
	});
}

@end
