// SPStatusBarNotificationWindow.m
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

#import "SPStatusBarNotificationWindow.h"
#import "SPStatusBarNotification.h"
#import "SPStatusBarTextView.h"
#import "../Shared.h"

#define DEGREES_TO_RADIANS(degrees)((M_PI * degrees)/180)

@interface UIWindow (private)
- (id)_initWithOrientation:(UIInterfaceOrientation)arg1;
- (BOOL)_canAffectStatusBarAppearance;
@end

@interface UIView (private)
+ (double)_durationForRotationFromInterfaceOrientation:(UIInterfaceOrientation)arg1 toInterfaceOrientation:(UIInterfaceOrientation)arg2;
+ (int)_degreesToRotateFromInterfaceOrientation:(UIInterfaceOrientation)arg1 toInterfaceOrientation:(UIInterfaceOrientation)arg2;
@end

@implementation SPStatusBarNotificationWindow

- (instancetype)init
{
  //Force portrait initialization to solve an issue that occurs when this window gets initialized in landscape mode
  self = [super _initWithOrientation:UIInterfaceOrientationPortrait];
  _currentDeviceOrientation = UIInterfaceOrientationPortrait;

  self.windowLevel = UIWindowLevelAlert + 1;
  self.clipsToBounds = YES;

  //Init and add textView
  _textView = [[SPStatusBarTextView alloc] init];
  [self addSubview:_textView];

  //Register for orientation changes
  [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
  [[NSNotificationCenter defaultCenter]
    addObserver:self
    selector:@selector(orientationDidChange)
    name:UIDeviceOrientationDidChangeNotification
    object:nil];

  return self;
}

- (BOOL)_canAffectStatusBarAppearance
{
  return NO;
}

- (void)updateFramesForOrientation:(UIInterfaceOrientation)orientation
{
  //NOTE: Sometimes UIDeviceOrientationUnknown is passed, even if it should be portrait. Workaround checks screen size
  if(iPhoneX && (UIDevice.currentDevice.orientation == UIDeviceOrientationPortrait || (UIDevice.currentDevice.orientation == UIDeviceOrientationUnknown && [[UIScreen mainScreen] bounds].size.width == 375 && [[UIScreen mainScreen] bounds].size.height == 812)))
  {
    _barHeight = 50;
  }
  else
  {
    _barHeight = 20;
  }

  if(_isPresented)
  {
    switch (orientation)
    {
      case UIInterfaceOrientationPortrait:
      self.frame = CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width, _barHeight);
      break;

      case UIInterfaceOrientationLandscapeLeft:
      self.frame = CGRectMake(0,0,_barHeight,[UIScreen mainScreen].bounds.size.width);
      break;

      case UIInterfaceOrientationLandscapeRight:
      self.frame = CGRectMake([UIScreen mainScreen].bounds.size.height-_barHeight,0,_barHeight,[UIScreen mainScreen].bounds.size.width);
      break;

      default:
      break;
    }
  }
  else
  {
    switch (orientation)
    {
      case UIInterfaceOrientationPortrait:
      self.frame = CGRectMake(0,-_barHeight,[UIScreen mainScreen].bounds.size.width, _barHeight);
      break;

      case UIInterfaceOrientationLandscapeLeft:
      self.frame = CGRectMake(-_barHeight,0,_barHeight,[UIScreen mainScreen].bounds.size.width);
      break;

      case UIInterfaceOrientationLandscapeRight:
      self.frame = CGRectMake([UIScreen mainScreen].bounds.size.height,0,_barHeight,[UIScreen mainScreen].bounds.size.width);
      break;

      default:
      break;
    }
  }

  if(orientation == UIInterfaceOrientationPortrait)
  {
    _textView.frame = CGRectMake(0,-20+_barHeight,self.frame.size.width,20);
  }
  else
  {
    _textView.frame = CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,20);
  }
}

- (void)orientationDidChange
{
  self.currentDeviceOrientation = [UIApplication sharedApplication].statusBarOrientation;
}

- (void)setCurrentDeviceOrientation:(UIInterfaceOrientation)newOrientation
{
  void (^rotation)(void) =
  ^{
    int degrees = [UIView _degreesToRotateFromInterfaceOrientation:_currentDeviceOrientation toInterfaceOrientation:newOrientation];
    self.transform = CGAffineTransformRotate(self.transform, DEGREES_TO_RADIANS(degrees));
    [self updateFramesForOrientation:newOrientation];
  };

  if(self.hidden)
  {
    rotation();
  }
  else
  {
    double duration = [UIView _durationForRotationFromInterfaceOrientation:_currentDeviceOrientation toInterfaceOrientation:newOrientation];
    [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionCurveLinear animations:rotation completion:nil];
  }

  _currentDeviceOrientation = newOrientation;
}

- (void)dispatchNotification:(SPStatusBarNotification*)notification
{
  [self dispatchNotification:notification completion:nil];
}

- (void)dispatchNotification:(SPStatusBarNotification*)notification completion:(void(^)(void))completion
{
  if(!_isPresented && !_isBeingPresented && !_isBeingDismissed)
  {
    _isBeingPresented = YES;

    dispatch_async(dispatch_get_main_queue(),
    ^{
      self.hidden = NO;
      self.backgroundColor = notification.backgroundColor;

      [_textView setCurrentNotification:notification];

      [UIView animateWithDuration:.3 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:
      ^{
        _isPresented = YES;
        [self updateFramesForOrientation:_currentDeviceOrientation];
      }
      completion:^(BOOL finished)
      {
        _isBeingPresented = NO;

        if(notification.dismissAfter)
        {
          _timer = [NSTimer scheduledTimerWithTimeInterval:notification.dismissAfter target:self selector:@selector(dismiss) userInfo:nil repeats:NO];
        }

        if(completion)
        {
          completion();
        }

        if(_shouldImmediatelyDismiss)
        {
          _shouldImmediatelyDismiss = NO;
          [self dismissWithCompletion:_savedBlock];
        }
      }];
    });
  }
  else if(_isBeingDismissed)
  {
    _shouldImmediatelyPresent = YES;
    _savedBlock = completion;
    _savedNotification = notification;
  }
}

- (void)dismiss
{
  [self dismissWithCompletion:nil];
}

- (void)dismissWithCompletion:(void(^)(void))completion
{
  if(_isPresented && !_isBeingPresented && !_isBeingDismissed)
  {
    _isBeingDismissed = YES;
    dispatch_async(dispatch_get_main_queue(),
    ^{
      [UIView animateWithDuration:.3 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:
      ^{
        _isPresented = NO;
        [self updateFramesForOrientation:_currentDeviceOrientation];
      }
      completion:^(BOOL finished)
      {
        self.hidden = YES;
        _isBeingDismissed = NO;
        _isPresented = NO;
        if(completion)
        {
          completion();
        }

        if(_timer.isValid)
        {
          [_timer invalidate];
        }

        if(_shouldImmediatelyPresent)
        {
          _shouldImmediatelyPresent = NO;
          [self dispatchNotification:_savedNotification completion:_savedBlock];
        }
      }];
    });
  }
  else if(_isBeingPresented)
  {
    _shouldImmediatelyDismiss = YES;
    _savedBlock = completion;
  }
  else if(!_isPresented)
  {
    if(completion)
    {
      completion();
    }
  }
}

@end
