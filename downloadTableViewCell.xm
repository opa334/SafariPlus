//  downloadTableViewCell.xm
// (c) 2017 opa334

#import "downloadTableViewCell.h"

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



@implementation downloadTableViewCell

- (id)initWithDownload:(Download*)download
{
  self = [super initWithSize:download.fileSize];
  self.downloadDelegate = download;
  self.selectionStyle = UITableViewCellSelectionStyleNone;
  self.progressView = [UIProgressView autolayoutView];
  self.percentProgress = [UILabel autolayoutView];
  self.sizeProgress = [UILabel autolayoutView];
  self.sizeSpeedSeperator = [UILabel autolayoutView];
  self.downloadSpeed = [UILabel autolayoutView];
  [self.contentView addSubview:self.progressView];

  self.percentProgress.textAlignment = NSTextAlignmentCenter;
  self.percentProgress.font = [self.percentProgress.font fontWithSize:8];
  [self.contentView addSubview:self.percentProgress];

  self.sizeSpeedSeperator.textAlignment = NSTextAlignmentCenter;
  self.sizeSpeedSeperator.font = [self.percentProgress.font fontWithSize:8];
  self.sizeSpeedSeperator.text = @"@";
  [self.contentView addSubview:self.sizeSpeedSeperator];

  self.downloadSpeed.textAlignment = NSTextAlignmentLeft;
  self.downloadSpeed.font = [self.downloadSpeed.font fontWithSize:8];
  [self.contentView addSubview:self.downloadSpeed];

  self.sizeProgress.textAlignment = NSTextAlignmentRight;
  self.sizeProgress.font = [self.sizeProgress.font fontWithSize:8];
  [self.contentView addSubview:self.sizeProgress];

  self.pauseResumeButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.pauseResumeButton.translatesAutoresizingMaskIntoConstraints = NO;
  self.pauseResumeButton.adjustsImageWhenHighlighted = YES;
  [self.pauseResumeButton addTarget:self action:@selector(pauseResumeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
  [self.pauseResumeButton setImage:[UIImage imageNamed:@"PauseButton.png" inBundle:SPBundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
  [self.pauseResumeButton setImage:[UIImage imageNamed:@"ResumeButton.png" inBundle:SPBundle compatibleWithTraitCollection:nil] forState:UIControlStateSelected];
  [self.contentView addSubview:self.pauseResumeButton];

  self.stopButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.stopButton.translatesAutoresizingMaskIntoConstraints = NO;
  self.stopButton.adjustsImageWhenHighlighted = YES;
  [self.stopButton addTarget:self action:@selector(stopButtonPressed) forControlEvents:UIControlEventTouchUpInside];
  [self.stopButton setImage:[UIImage imageNamed:@"StopButton.png" inBundle:SPBundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
  [self.contentView addSubview:self.stopButton];

  NSDictionary *metrics = @{@"rightSpace":@43.5, @"smallSpace":@7.5, @"buttonSize":@28.0};
  NSDictionary *views = [NSDictionary dictionaryWithObjectsAndKeys:
                    self.progressView, @"progressView",
                    self.percentProgress, @"percentProgress",
                    self.sizeSpeedSeperator, @"sizeSpeedSeperator",
                    self.sizeProgress, @"sizeProgress",
                    self.downloadSpeed, @"downloadSpeed",
                    self.pauseResumeButton, @"pauseResumeButton",
                    self.stopButton, @"stopButton",
                    nil];

  [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"|-[sizeProgress(downloadSpeed)]-smallSpace-[sizeSpeedSeperator(8)]-smallSpace-[downloadSpeed(sizeProgress)]-rightSpace-|" options:0 metrics:metrics views:views]];

  [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"|-[progressView]-smallSpace-[stopButton(buttonSize)]-|" options:0 metrics:metrics views:views]];

  [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"|-[percentProgress]-rightSpace-|" options:0 metrics:metrics views:views]];

  [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"[pauseResumeButton(buttonSize)]-8-|" options:0 metrics:metrics views:views]];

  [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"V:|-4.0-[pauseResumeButton(buttonSize)]-[stopButton(buttonSize)]-4-|" options:0 metrics:metrics views:views]];

  [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"V:[sizeProgress(8)]-19-|" options:0 metrics:metrics views:views]];

  [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"V:[sizeSpeedSeperator(8)]-3-[progressView(2.5)]-3-[percentProgress(8)]-3-|" options:0 metrics:metrics views:views]];

  [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
      @"V:[downloadSpeed(8)]-19-|" options:0 metrics:metrics views:views]];

  if(download.totalBytesWritten > 0)
  {
    [self updateProgress:download.totalBytesWritten totalBytes:download.fileSize bytesPerSecond:0 animated:NO];
  }

  if(download.paused)
  {
    self.pauseResumeButton.selected = YES;
    self.percentProgress.textColor = [UIColor grayColor];
    self.progressView.progressTintColor = [UIColor grayColor];
    self.sizeProgress.textColor = [UIColor grayColor];
    self.sizeSpeedSeperator.textColor = [UIColor grayColor];
    self.downloadSpeed.textColor = [UIColor grayColor];
  }
  else
  {
    self.percentProgress.textColor = [UIColor colorWithRed:0.45 green:0.65 blue:0.95 alpha:1.0];
    self.progressView.progressTintColor = [UIColor colorWithRed:0.45 green:0.65 blue:0.95 alpha:1.0];
    self.sizeProgress.textColor = [UIColor colorWithRed:0.45 green:0.65 blue:0.95 alpha:1.0];
    self.sizeSpeedSeperator.textColor = [UIColor colorWithRed:0.45 green:0.65 blue:0.95 alpha:1.0];
    self.downloadSpeed.textColor = [UIColor colorWithRed:0.45 green:0.65 blue:0.95 alpha:1.0];
  }

  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  dispatch_async(dispatch_get_main_queue(), ^
  {
    self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x,self.textLabel.frame.origin.y - 11,self.textLabel.frame.size.width - 32.5,self.textLabel.frame.size.height);
    self.imageView.frame = CGRectMake(self.imageView.frame.origin.x,self.imageView.frame.origin.y - 11,self.imageView.frame.size.width,self.imageView.frame.size.height);
    self.pauseResumeButton.imageView.layer.cornerRadius = self.pauseResumeButton.imageView.frame.size.height / 2.0;
    self.stopButton.imageView.layer.cornerRadius = self.stopButton.imageView.frame.size.height / 2.0;
  });
}

- (void)pauseResumeButtonPressed
{
  dispatch_async(dispatch_get_main_queue(),
  ^{
    self.pauseResumeButton.selected = !self.pauseResumeButton.selected;

    if(self.pauseResumeButton.selected)
    {
      [self.downloadDelegate pauseDownload];
      self.percentProgress.textColor = [UIColor grayColor];
      self.progressView.progressTintColor = [UIColor grayColor];
      self.sizeProgress.textColor = [UIColor grayColor];
      self.sizeSpeedSeperator.textColor = [UIColor grayColor];
      self.downloadSpeed.textColor = [UIColor grayColor];
    }
    else
    {
      [self.downloadDelegate resumeDownload];
      self.percentProgress.textColor = [UIColor colorWithRed:0.45 green:0.65 blue:0.95 alpha:1.0];
      self.progressView.progressTintColor = [UIColor colorWithRed:0.45 green:0.65 blue:0.95 alpha:1.0];
      self.sizeProgress.textColor = [UIColor colorWithRed:0.45 green:0.65 blue:0.95 alpha:1.0];
      self.sizeSpeedSeperator.textColor = [UIColor colorWithRed:0.45 green:0.65 blue:0.95 alpha:1.0];
      self.downloadSpeed.textColor = [UIColor colorWithRed:0.45 green:0.65 blue:0.95 alpha:1.0];
    }
  });
}

- (void)stopButtonPressed
{
  [self.downloadDelegate cancelDownload];
}

- (void)updateProgress:(int64_t)currentBytes totalBytes:(int64_t)totalBytes bytesPerSecond:(int64_t)bytesPerSecond animated:(BOOL)animated
{
    float progress = (float)currentBytes / (float)totalBytes;
    NSString* percentProgressString = [NSString stringWithFormat:@"%.1f%%", progress * 100];
    NSString* sizeString = [NSByteCountFormatter stringFromByteCount:currentBytes countStyle:NSByteCountFormatterCountStyleFile];
    NSString* sizeSpeedSeperator = @"@";
    NSString* speedString = [NSString stringWithFormat:@"%@/s", [NSByteCountFormatter stringFromByteCount:bytesPerSecond countStyle:NSByteCountFormatterCountStyleFile]];
    dispatch_async(dispatch_get_main_queue(),
    ^{
      [self.progressView setProgress:progress animated:animated];
      self.percentProgress.text = percentProgressString;
      self.sizeProgress.text = sizeString;
      self.sizeSpeedSeperator.text = sizeSpeedSeperator;
      self.downloadSpeed.text = speedString;
    });
}

@end
