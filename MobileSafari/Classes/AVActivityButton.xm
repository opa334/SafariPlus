#import "AVActivityButton.h"
#import "../Defines.h"

%subclass AVActivityButton: AVButton

%property(nonatomic,retain) UIActivityIndicatorView *activityIndicatorView;

+ (instancetype)buttonWithType:(UIButtonType)buttonType
{
  AVActivityButton* button = %orig;

  [button setUpSpinner];

  return button;
}

%new
- (void)setUpSpinner
{
  if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0)
  {
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
  }
  else
  {
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
  }

  self.activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
  self.activityIndicatorView.hidden = YES;
  [self addSubview:self.activityIndicatorView];

  NSDictionary* views = @{@"activityIndicatorView" : self.activityIndicatorView};

  [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[activityIndicatorView]-0-|" options:0 metrics:nil views:views]];
  [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[activityIndicatorView]-0-|" options:0 metrics:nil views:views]];
}

%new
- (BOOL)spinning
{
  return [objc_getAssociatedObject(self, "spinning") boolValue];
}

%new
- (void)setSpinning:(BOOL)spinning
{
  BOOL _spinning = [self spinning];

  if(spinning != _spinning)
  {
    objc_setAssociatedObject(self, "spinning", [NSNumber numberWithBool:spinning], OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    dispatch_async(dispatch_get_main_queue(),
    ^{
      if(spinning)
      {
        [self.activityIndicatorView startAnimating];
        self.activityIndicatorView.hidden = NO;
      }
      else
      {
        self.activityIndicatorView.hidden = YES;
        [self.activityIndicatorView stopAnimating];
      }
    });
  }
}

%end
