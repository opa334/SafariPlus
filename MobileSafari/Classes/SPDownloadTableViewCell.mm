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

@implementation SPDownloadTableViewCell

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

	[self setUpDelegate];

	[self setUpContent];

	//Update progress bar with current progress
	[self updateProgress:_download.totalBytesWritten totalBytes:_download.filesize animated:NO];

	//Update download speed
	[self updateDownloadSpeed:_download.bytesPerSecond];

	//Check whether _download is currently paused or not and update UI elements according to that
	[self setPaused:_download.paused];
	_pauseResumeButton.selected = _download.paused;
}

- (void)initContent
{
	//Get contentView
	UIView* contentView = self.contentView;

	_iconView = [UIImageView autolayoutView];
	[contentView addSubview:_iconView];

	_filenameLabel = [UILabel autolayoutView];
	[contentView addSubview:_filenameLabel];

	_sizeProgress = [UILabel autolayoutView];
	[contentView addSubview:_sizeProgress];

	_sizeSpeedSeperator = [UILabel autolayoutView];
	[contentView addSubview:_sizeSpeedSeperator];

	_downloadSpeed = [UILabel autolayoutView];
	[contentView addSubview:_downloadSpeed];

	_progressView = [UIProgressView autolayoutView];
	[contentView addSubview:_progressView];

	_percentProgress = [UILabel autolayoutView];
	[contentView addSubview:_percentProgress];

	_pauseResumeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_pauseResumeButton.translatesAutoresizingMaskIntoConstraints = NO;
	[contentView addSubview:_pauseResumeButton];

	_stopButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_stopButton.translatesAutoresizingMaskIntoConstraints = NO;
	[contentView addSubview:_stopButton];

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

	//Configure sizeProgress label
	_sizeProgress.textAlignment = NSTextAlignmentRight;
	_sizeProgress.font = [_sizeProgress.font fontWithSize:8];

	//Seperator for size and speed (@)
	_sizeSpeedSeperator.textAlignment = NSTextAlignmentCenter;
	_sizeSpeedSeperator.font = [_sizeSpeedSeperator.font fontWithSize:8];
	_sizeSpeedSeperator.text = @"@";

	//Configure downloadSpeed label
	_downloadSpeed.textAlignment = NSTextAlignmentLeft;
	_downloadSpeed.font = [_downloadSpeed.font fontWithSize:8];

	//Configure percentProgress label
	_percentProgress.textAlignment = NSTextAlignmentCenter;
	_percentProgress.font = [_percentProgress.font fontWithSize:8];

	//Configure pause / resume button
	_pauseResumeButton.adjustsImageWhenHighlighted = YES;
	[_pauseResumeButton addTarget:self action:@selector(pauseResumeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	[_pauseResumeButton setImage:[UIImage imageNamed:@"PauseButton.png" inBundle:SPBundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
	[_pauseResumeButton setImage:[UIImage imageNamed:@"ResumeButton.png" inBundle:SPBundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];

	//Configure stop button
	_stopButton.adjustsImageWhenHighlighted = YES;
	[_stopButton addTarget:self action:@selector(stopButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	[_stopButton setImage:[UIImage imageNamed:@"StopButton.png" inBundle:SPBundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
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
	return NSDictionaryOfVariableBindings(
		_progressView, _percentProgress,
		_sizeSpeedSeperator, _sizeProgress,
		_downloadSpeed, _pauseResumeButton,
		_stopButton, _filenameLabel,
		_iconView
		);
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
				     @"V:|-topSpace-[_iconView(iconSize)]" options:0 metrics:metrics views:views]];

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"V:|-topSpace-[_filenameLabel(iconSize)]" options:0 metrics:metrics views:views]];

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"V:|-5-[_pauseResumeButton(buttonSize)]" options:0 metrics:metrics views:views]];

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"V:[_stopButton(buttonSize)]-5-|" options:0 metrics:metrics views:views]];

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"V:[_sizeProgress(8)]-19-|" options:0 metrics:metrics views:views]];

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"V:[_sizeSpeedSeperator(8)]-3-[_progressView(2.5)]-3-[_percentProgress(8)]-3-|" options:0 metrics:metrics views:views]];

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"V:[_downloadSpeed(8)]-19-|" options:0 metrics:metrics views:views]];
}

- (void)setUpDelegate
{
	[_download addObserverDelegate:self];
}

- (void)removeDelegate
{
	[_download removeObserverDelegate:self];
}

- (void)setPaused:(BOOL)paused
{
	_paused = paused;

	_pauseResumeButton.selected = _paused;

	if(_paused)
	{
		UIColor* pausedColor = [UIColor grayColor];
		dispatch_async(dispatch_get_main_queue(), ^
		{
			//Grey out all elements
			_percentProgress.textColor = pausedColor;
			_progressView.progressTintColor = pausedColor;
			_sizeProgress.textColor = pausedColor;
			_sizeSpeedSeperator.textColor = pausedColor;
			_downloadSpeed.textColor = pausedColor;
		});
	}
	else
	{
		UIColor* nonPausedColor = [UIColor colorWithRed:0.45 green:0.65 blue:0.95 alpha:1.0];
		dispatch_async(dispatch_get_main_queue(),
			       ^
		{
			//Make all elements light blue
			_percentProgress.textColor = nonPausedColor;
			_progressView.progressTintColor = nonPausedColor;
			_sizeProgress.textColor = nonPausedColor;
			_sizeSpeedSeperator.textColor = nonPausedColor;
			_downloadSpeed.textColor = nonPausedColor;
		});
	}
}

- (void)layoutSubviews
{
	[super layoutSubviews];

	//Round buttons
	_pauseResumeButton.imageView.layer.cornerRadius = _pauseResumeButton.imageView.frame.size.height / 2.0;
	_stopButton.imageView.layer.cornerRadius = _stopButton.imageView.frame.size.height / 2.0;
}

//Pause / Resume
- (void)pauseResumeButtonPressed
{
	_download.paused = !_download.paused;
}

//Cancel
- (void)stopButtonPressed
{
	//Stop download
	[_download cancelDownload];
}

- (void)updateDownloadSpeed:(int64_t)bytesPerSecond
{
	//Create string for bytesPerSecond
	NSString* speedString = [NSString stringWithFormat:@"%@/s",
				 [NSByteCountFormatter stringFromByteCount:bytesPerSecond
				  countStyle:NSByteCountFormatterCountStyleFile]];

	dispatch_async(dispatch_get_main_queue(), ^
	{
		//Update _download speed
		_downloadSpeed.text = speedString;
	});
}

- (void)updateProgress:(int64_t)currentBytes totalBytes:(int64_t)totalBytes animated:(BOOL)animated
{
	CGFloat progress;
	NSString* sizeString = [NSByteCountFormatter stringFromByteCount:currentBytes
				countStyle:NSByteCountFormatterCountStyleFile];
	NSString* percentProgressString;

	if(totalBytes <= 0)
	{
		progress = 0;
		percentProgressString = [localizationManager localizedSPStringForKey:@"SIZE_UNKNOWN"];
	}
	else
	{
		//Calculate progress and create strings for everything
		progress = (CGFloat)currentBytes / (CGFloat)totalBytes;
		percentProgressString = [NSString
					 stringWithFormat:@"%.1f%%", progress * 100];
	}

	dispatch_async(dispatch_get_main_queue(), ^
	{
		//Update cell components from progress
		[_progressView setProgress:progress animated:animated];
		_percentProgress.text = percentProgressString;
		_sizeProgress.text = sizeString;
	});
}

- (void)prepareForReuse
{
	[super prepareForReuse];

	[self removeDelegate];
}

@end
