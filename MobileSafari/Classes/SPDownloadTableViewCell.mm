// Copyright (c) 2017-2020 Lars Fröder

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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

	_downloadProgressView.showsDownloadSpeed = ![download isHLSDownload];

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
	//Enable separators between imageViews
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
	[_buttonsView.topButton setImage:[[UIImage imageNamed:@"PauseButton" inBundle:SPBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
	[_buttonsView.topButton setImage:[[UIImage imageNamed:@"ResumeButton" inBundle:SPBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateSelected];

	[_buttonsView.bottomButton addTarget:self action:@selector(stopButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	[_buttonsView.bottomButton setImage:[[UIImage imageNamed:@"StopButton" inBundle:SPBundle compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
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
	if(!download.isHLSDownload)
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
}

- (void)expectedDurationDidChangeForDownload:(SPDownload*)download
{
	if(download.isHLSDownload)
	{
		NSDateComponentsFormatter *formatter = [[NSDateComponentsFormatter alloc] init];
		formatter.unitsStyle = NSDateComponentsFormatterUnitsStylePositional;
		formatter.includesApproximationPhrase = NO;
		formatter.includesTimeRemainingPhrase = NO;
		formatter.allowedUnits = NSCalendarUnitMinute | NSCalendarUnitSecond;
		formatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;

		_sizeLabel.text = [formatter stringFromTimeInterval:download.expectedDuration];
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
	CGFloat progress = 0;
	NSString* sizeString;
	NSString* percentProgressString;

	if(download.isHLSDownload)
	{
		NSDateComponentsFormatter *formatter = [[NSDateComponentsFormatter alloc] init];
		formatter.unitsStyle = NSDateComponentsFormatterUnitsStylePositional;
		formatter.includesApproximationPhrase = NO;
		formatter.includesTimeRemainingPhrase = NO;
		formatter.allowedUnits = NSCalendarUnitMinute | NSCalendarUnitSecond;
		formatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;

		sizeString = [formatter stringFromTimeInterval:download.secondsLoaded];

		if(download.expectedDuration > 0)
		{
			progress = download.secondsLoaded / download.expectedDuration;
			percentProgressString = [NSString stringWithFormat:@"%.1f%%", progress * 100];
		}
		else
		{
			percentProgressString = [localizationManager localizedSPStringForKey:@"DURATION_UNKNOWN"];
		}
	}
	else
	{
		sizeString = [NSByteCountFormatter stringFromByteCount:download.totalBytesWritten
			      countStyle:NSByteCountFormatterCountStyleFile];

		if(download.filesize > 0)
		{
			//Calculate progress and create strings for everything
			progress = (CGFloat)download.totalBytesWritten / (CGFloat)download.filesize;
			percentProgressString = [NSString stringWithFormat:@"%.1f%%", progress * 100];
		}
		else
		{
			percentProgressString = [localizationManager localizedSPStringForKey:@"SIZE_UNKNOWN"];
		}
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
