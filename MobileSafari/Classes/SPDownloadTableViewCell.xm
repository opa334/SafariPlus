//  SPDownloadTableViewCell.xm
// (c) 2017 opa334

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
  self.downloadDelegate = download;

  //Create imageView with file icon add add it to contentView
  self.fileIcon = [UIImageView autolayoutView];
  self.fileIcon.image = [UIImage imageNamed:@"File.png" inBundle:SPBundle compatibleWithTraitCollection:nil];
  [self.contentView addSubview:self.fileIcon];

  //Create label with file name and add it to contentView
  self.filenameLabel = [UILabel autolayoutView];
  self.filenameLabel.text = download.filename;
  self.filenameLabel.font = self.textLabel.font;
  self.filenameLabel.textAlignment = NSTextAlignmentLeft;
  [self.contentView addSubview:self.filenameLabel];

  //Create label with size progress and add it to contentView
  self.sizeProgress = [UILabel autolayoutView];
  self.sizeProgress.textAlignment = NSTextAlignmentRight;
  self.sizeProgress.font = [self.sizeProgress.font fontWithSize:8];
  [self.contentView addSubview:self.sizeProgress];

  //Create label with seperator for size and speed (@ character) and add it to contentView
  self.sizeSpeedSeperator = [UILabel autolayoutView];
  self.sizeSpeedSeperator.textAlignment = NSTextAlignmentCenter;
  self.sizeSpeedSeperator.font = [self.sizeSpeedSeperator.font fontWithSize:8];
  self.sizeSpeedSeperator.text = @"@";
  [self.contentView addSubview:self.sizeSpeedSeperator];

  //Create label with downloadSpeed and add it to contentView
  self.downloadSpeed = [UILabel autolayoutView];
  self.downloadSpeed.textAlignment = NSTextAlignmentLeft;
  self.downloadSpeed.font = [self.downloadSpeed.font fontWithSize:8];
  [self.contentView addSubview:self.downloadSpeed];

  //Create progress bar and add it to contentView
  self.progressView = [UIProgressView autolayoutView];
  [self.contentView addSubview:self.progressView];

  //Create label with percent progress and add it to contentView
  self.percentProgress = [UILabel autolayoutView];
  self.percentProgress.textAlignment = NSTextAlignmentCenter;
  self.percentProgress.font = [self.percentProgress.font fontWithSize:8];
  [self.contentView addSubview:self.percentProgress];

  //Create pause/resume button and add it to contentView
  self.pauseResumeButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.pauseResumeButton.translatesAutoresizingMaskIntoConstraints = NO;
  self.pauseResumeButton.adjustsImageWhenHighlighted = YES;
  [self.pauseResumeButton addTarget:self action:@selector(pauseResumeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
  [self.pauseResumeButton setImage:[UIImage imageNamed:@"PauseButton.png" inBundle:SPBundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
  [self.pauseResumeButton setImage:[UIImage imageNamed:@"ResumeButton.png" inBundle:SPBundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
  [self.contentView addSubview:self.pauseResumeButton];

  //Create stop button and add it to contentView
  self.stopButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.stopButton.translatesAutoresizingMaskIntoConstraints = NO;
  self.stopButton.adjustsImageWhenHighlighted = YES;
  [self.stopButton addTarget:self action:@selector(stopButtonPressed) forControlEvents:UIControlEventTouchUpInside];
  [self.stopButton setImage:[UIImage imageNamed:@"StopButton.png" inBundle:SPBundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
  [self.contentView addSubview:self.stopButton];

  //Create metrics and views for constraints
  NSDictionary *metrics = @{@"rightSpace":@43.5, @"smallSpace":@7.5, @"buttonSize":@28.0, @"iconSize":@30.0, @"topSpace":@6.0};
  NSDictionary *views = [NSDictionary dictionaryWithObjectsAndKeys:
                    self.progressView, @"progressView",
                    self.percentProgress, @"percentProgress",
                    self.sizeSpeedSeperator, @"sizeSpeedSeperator",
                    self.sizeProgress, @"sizeProgress",
                    self.downloadSpeed, @"downloadSpeed",
                    self.pauseResumeButton, @"pauseResumeButton",
                    self.stopButton, @"stopButton",
                    self.filenameLabel, @"filenameLabel",
                    self.fileIcon, @"fileIcon",
                    nil];

  //Add dynamic constraints so the cell looks good across all devices
  [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"|-[sizeProgress(downloadSpeed)]-smallSpace-[sizeSpeedSeperator(8)]-smallSpace-[downloadSpeed(sizeProgress)]-rightSpace-|" options:0 metrics:metrics views:views]];

  [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"|-[progressView]-smallSpace-[stopButton(buttonSize)]-|" options:0 metrics:metrics views:views]];

  [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"|-[percentProgress]-rightSpace-|" options:0 metrics:metrics views:views]];

  [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"|-[fileIcon(iconSize)]-15-[filenameLabel]-smallSpace-[pauseResumeButton(buttonSize)]-8-|" options:0 metrics:metrics views:views]];

  [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"V:|-topSpace-[fileIcon(iconSize)]" options:0 metrics:metrics views:views]];

  [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"V:|-topSpace-[filenameLabel(iconSize)]" options:0 metrics:metrics views:views]];

  [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"V:|-4.0-[pauseResumeButton(buttonSize)]-[stopButton(buttonSize)]-4-|" options:0 metrics:metrics views:views]];

  [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"V:[sizeProgress(8)]-19-|" options:0 metrics:metrics views:views]];

  [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"V:[sizeSpeedSeperator(8)]-3-[progressView(2.5)]-3-[percentProgress(8)]-3-|" options:0 metrics:metrics views:views]];

  [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"V:[downloadSpeed(8)]-19-|" options:0 metrics:metrics views:views]];

  //Update progress bar with current progress
  [self updateProgress:download.totalBytesWritten totalBytes:download.filesize animated:NO];

  //Update download speed
  [self updateDownloadSpeed:download.bytesPerSecond];

  //Check whether download is currently paused or not and update UI elements according to that
  [self setPaused:download.paused];
  self.pauseResumeButton.selected = download.paused;

  return self;
}

- (void)setPaused:(BOOL)paused
{
  [self.downloadDelegate setPaused:paused];

  if(paused)
  {
    dispatch_async(dispatch_get_main_queue(),
    ^{
      //Grey out all elements
      UIColor* pausedColor = [UIColor grayColor];
      self.percentProgress.textColor = pausedColor;
      self.progressView.progressTintColor = pausedColor;
      self.sizeProgress.textColor = pausedColor;
      self.sizeSpeedSeperator.textColor = pausedColor;
      self.downloadSpeed.textColor = pausedColor;
    });
  }
  else
  {
    dispatch_async(dispatch_get_main_queue(),
    ^{
      //Make all elements light blue
      UIColor* nonPausedColor = [UIColor colorWithRed:0.45 green:0.65 blue:0.95 alpha:1.0];
      self.percentProgress.textColor = nonPausedColor;
      self.progressView.progressTintColor = nonPausedColor;
      self.sizeProgress.textColor = nonPausedColor;
      self.sizeSpeedSeperator.textColor = nonPausedColor;
      self.downloadSpeed.textColor = nonPausedColor;
    });
  }
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  dispatch_async(dispatch_get_main_queue(),
  ^{
    //Make buttons round
    self.pauseResumeButton.imageView.layer.cornerRadius = self.pauseResumeButton.imageView.frame.size.height / 2.0;
    self.stopButton.imageView.layer.cornerRadius = self.stopButton.imageView.frame.size.height / 2.0;
  });
}

- (void)pauseResumeButtonPressed
{
  //Invert button selection
  self.pauseResumeButton.selected = !self.pauseResumeButton.selected;

  if(self.pauseResumeButton.selected)
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
  [self.downloadDelegate cancelDownload];
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
    self.downloadSpeed.text = speedString;
  });
}

- (void)updateProgress:(int64_t)currentBytes totalBytes:(int64_t)totalBytes animated:(BOOL)animated
{
  float progress;
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
    progress = (float)currentBytes / (float)totalBytes;
    percentProgressString = [NSString
      stringWithFormat:@"%.1f%%", progress * 100];
  }

  dispatch_async(dispatch_get_main_queue(),
  ^{
    //Update cell components from progress
    [self.progressView setProgress:progress animated:animated];
    self.percentProgress.text = percentProgressString;
    self.sizeProgress.text = sizeString;
  });
}

@end
