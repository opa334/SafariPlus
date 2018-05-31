// SPDownloadTableViewCell.m
// (c) 2017 opa334

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

#import "../Shared.h"
#import "SPDownload.h"
#import "SPDownloadManager.h"
#import "SPFileTableViewCell.h"
#import "SPLocalizationManager.h"

//http://commandshift.co.uk/blog/2013/01/31/visual-format-language-for-autolayout/

@interface UIView (Autolayout)
+ (id)autolayoutView;
@end

@implementation UIView (Autolayout)
+ (id)autolayoutView
{
    UIView *view = [self new];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    return view;
}
@end

@implementation SPDownloadTableViewCell

- (id)initWithDownload:(SPDownload*)download
{
  self = [super init];

  //Create size label and set it to accessoryView
  UILabel* sizeLabel = [[UILabel alloc] init];
  if(download.filesize < 0)
  {
    sizeLabel.text = @"?";
  }
  else
  {
    sizeLabel.text = [NSByteCountFormatter stringFromByteCount:download.filesize
      countStyle:NSByteCountFormatterCountStyleFile];
  }
  sizeLabel.textColor = [UIColor lightGrayColor];
  sizeLabel.font = [sizeLabel.font fontWithSize:10];
  sizeLabel.textAlignment = NSTextAlignmentRight;
  sizeLabel.frame = CGRectMake(0,0, sizeLabel.intrinsicContentSize.width, 15);
  self.accessoryView = sizeLabel;

  //nil out default label and image just to be sure (Can't use them in constraints)
  self.textLabel.text = nil;
  self.imageView.image = nil;

  //Make cell unselectable
  self.selectionStyle = UITableViewCellSelectionStyleNone;

  //Set cell delegate to receive download updates (progress changes)
  download.cellDelegate = self;

  //Set download delegate to send actions (pause, resume, stop)
  _downloadDelegate = download;

  //Get contentView
  UIView* contentView = self.contentView;

  //Create imageView with file icon add add it to contentView
  _fileIcon = [UIImageView autolayoutView];
  _fileIcon.image = [UIImage imageNamed:@"File.png" inBundle:SPBundle compatibleWithTraitCollection:nil];
  [contentView addSubview:_fileIcon];

  //Create label with file name and add it to contentView
  _filenameLabel = [UILabel autolayoutView];
  _filenameLabel.text = download.filename;
  _filenameLabel.font = self.textLabel.font;
  _filenameLabel.textAlignment = NSTextAlignmentLeft;
  [contentView addSubview:_filenameLabel];

  //Create label with size progress and add it to contentView
  _sizeProgress = [UILabel autolayoutView];
  _sizeProgress.textAlignment = NSTextAlignmentRight;
  _sizeProgress.font = [_sizeProgress.font fontWithSize:8];
  [contentView addSubview:_sizeProgress];

  //Create label with seperator for size and speed (@ character) and add it to contentView
  _sizeSpeedSeperator = [UILabel autolayoutView];
  _sizeSpeedSeperator.textAlignment = NSTextAlignmentCenter;
  _sizeSpeedSeperator.font = [_sizeSpeedSeperator.font fontWithSize:8];
  _sizeSpeedSeperator.text = @"@";
  [contentView addSubview:_sizeSpeedSeperator];

  //Create label with downloadSpeed and add it to contentView
  _downloadSpeed = [UILabel autolayoutView];
  _downloadSpeed.textAlignment = NSTextAlignmentLeft;
  _downloadSpeed.font = [_downloadSpeed.font fontWithSize:8];
  [contentView addSubview:_downloadSpeed];

  //Create progress bar and add it to contentView
  _progressView = [UIProgressView autolayoutView];
  [contentView addSubview:_progressView];

  //Create label with percent progress and add it to contentView
  _percentProgress = [UILabel autolayoutView];
  _percentProgress.textAlignment = NSTextAlignmentCenter;
  _percentProgress.font = [_percentProgress.font fontWithSize:8];
  [contentView addSubview:_percentProgress];

  //Create pause/resume button and add it to contentView
  _pauseResumeButton = [UIButton buttonWithType:UIButtonTypeCustom];
  _pauseResumeButton.translatesAutoresizingMaskIntoConstraints = NO;
  _pauseResumeButton.adjustsImageWhenHighlighted = YES;
  [_pauseResumeButton addTarget:self action:@selector(pauseResumeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
  [_pauseResumeButton setImage:[UIImage imageNamed:@"PauseButton.png" inBundle:SPBundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
  [_pauseResumeButton setImage:[UIImage imageNamed:@"ResumeButton.png" inBundle:SPBundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
  [contentView addSubview:_pauseResumeButton];

  //Create stop button and add it to contentView
  _stopButton = [UIButton buttonWithType:UIButtonTypeCustom];
  _stopButton.translatesAutoresizingMaskIntoConstraints = NO;
  _stopButton.adjustsImageWhenHighlighted = YES;
  [_stopButton addTarget:self action:@selector(stopButtonPressed) forControlEvents:UIControlEventTouchUpInside];
  [_stopButton setImage:[UIImage imageNamed:@"StopButton.png" inBundle:SPBundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
  [contentView addSubview:_stopButton];

  //Create metrics and views for constraints
  NSDictionary *metrics = @{@"rightSpace":@43.5, @"smallSpace":@7.5, @"buttonSize":@28.0, @"iconSize":@30.0, @"topSpace":@6.0};
  NSDictionary *views = NSDictionaryOfVariableBindings(
    _progressView, _percentProgress,
    _sizeSpeedSeperator, _sizeProgress,
    _downloadSpeed, _pauseResumeButton,
    _stopButton, _filenameLabel,
    _fileIcon
  );

  //Add dynamic constraints so the cell looks good across all devices
  [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"|-[_sizeProgress(_downloadSpeed)]-smallSpace-[_sizeSpeedSeperator(8)]-smallSpace-[_downloadSpeed(_sizeProgress)]-rightSpace-|" options:0 metrics:metrics views:views]];

  [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"|-[_progressView]-smallSpace-[_stopButton(buttonSize)]-|" options:0 metrics:metrics views:views]];

  [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"|-[_percentProgress]-rightSpace-|" options:0 metrics:metrics views:views]];

  [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"|-[_fileIcon(iconSize)]-15-[_filenameLabel]-smallSpace-[_pauseResumeButton(buttonSize)]-8-|" options:0 metrics:metrics views:views]];

  [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"V:|-topSpace-[_fileIcon(iconSize)]" options:0 metrics:metrics views:views]];

  [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"V:|-topSpace-[_filenameLabel(iconSize)]" options:0 metrics:metrics views:views]];

  [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"V:|-4.0-[_pauseResumeButton(buttonSize)]-[_stopButton(buttonSize)]-4-|" options:0 metrics:metrics views:views]];

  [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"V:[_sizeProgress(8)]-19-|" options:0 metrics:metrics views:views]];

  [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"V:[_sizeSpeedSeperator(8)]-3-[_progressView(2.5)]-3-[_percentProgress(8)]-3-|" options:0 metrics:metrics views:views]];

  [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"V:[_downloadSpeed(8)]-19-|" options:0 metrics:metrics views:views]];

  //Update progress bar with current progress
  [self updateProgress:download.totalBytesWritten totalBytes:download.filesize animated:NO];

  //Update download speed
  [self updateDownloadSpeed:download.bytesPerSecond];

  //Check whether download is currently paused or not and update UI elements according to that
  [self setPaused:download.paused];
  _pauseResumeButton.selected = download.paused;

  return self;
}

- (void)setPaused:(BOOL)paused
{
  [_downloadDelegate setPaused:paused];

  if(paused)
  {
    UIColor* pausedColor = [UIColor grayColor];
    dispatch_async(dispatch_get_main_queue(),
    ^{
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
    ^{
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
  dispatch_async(dispatch_get_main_queue(),
  ^{
    //Round buttons
    _pauseResumeButton.imageView.layer.cornerRadius = _pauseResumeButton.imageView.frame.size.height / 2.0;
    _stopButton.imageView.layer.cornerRadius = _stopButton.imageView.frame.size.height / 2.0;
  });
}

- (void)pauseResumeButtonPressed
{
  //Invert button selection
  _pauseResumeButton.selected = !_pauseResumeButton.selected;

  if(_pauseResumeButton.selected)
  {
    //Pause download and update UI elements
    [self setPaused:YES];
  }
  else
  {
    //Resume download and update UI elements
    [self setPaused:NO];
  }
}

- (void)stopButtonPressed
{
  //Stop download
  [_downloadDelegate cancelDownload];
}

- (void)updateDownloadSpeed:(int64_t)bytesPerSecond
{
  //Create string for bytesPerSecond
  NSString* speedString = [NSString stringWithFormat:@"%@/s",
    [NSByteCountFormatter stringFromByteCount:bytesPerSecond
    countStyle:NSByteCountFormatterCountStyleFile]];

  dispatch_async(dispatch_get_main_queue(),
  ^{
    //Update download speed
    _downloadSpeed.text = speedString;
  });
}

- (void)updateProgress:(int64_t)currentBytes totalBytes:(int64_t)totalBytes animated:(BOOL)animated
{
  CGFloat progress;
  NSString* sizeString = [NSByteCountFormatter stringFromByteCount:currentBytes
    countStyle:NSByteCountFormatterCountStyleFile];
  NSString* percentProgressString;

  if(totalBytes < 0)
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

  dispatch_async(dispatch_get_main_queue(),
  ^{
    //Update cell components from progress
    [_progressView setProgress:progress animated:animated];
    _percentProgress.text = percentProgressString;
    _sizeProgress.text = sizeString;
  });
}

@end
