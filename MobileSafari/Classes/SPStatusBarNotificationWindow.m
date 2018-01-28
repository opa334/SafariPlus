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
#import "SPStatusBarNotificationRootController.h"
#import "SPStatusBarNotification.h"
#import "SPStatusBarTextView.h"
#import "../Shared.h"

@implementation SPStatusBarNotificationWindow

- (instancetype)init
{
  self = [super init];

  self.windowLevel = UIWindowLevelAlert + 1;

  self.rootViewController = [[SPStatusBarNotificationRootController alloc] init];
  self.rootViewController.view = [[UIView alloc] init];

  _textView = [[SPStatusBarTextView alloc] init];
  _textView.translatesAutoresizingMaskIntoConstraints = NO;
  NSDictionary* views = NSDictionaryOfVariableBindings(_textView);

  [self.rootViewController.view addSubview:_textView];
  [self.rootViewController.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_textView(20)]-0-|" options:0 metrics:nil views:views]];
  [self.rootViewController.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[_textView]-0-|" options:0 metrics:nil views:views]];

  self.clipsToBounds = YES;

  [self makeKeyWindow];

  //Update frame once
  [self updateFrame];

  _textView.frame = self.rootViewController.view.frame;
  [_textView layoutSubviews];

  //Register for orientation changes
  [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
  [[NSNotificationCenter defaultCenter]
    addObserver:self
    selector:@selector(updateFrame)
    name:UIDeviceOrientationDidChangeNotification
    object:nil];

  return self;
}

- (void)updateFrame
{
  //NOTE: Sometimes UIDeviceOrientationUnknown is returned, even if it should be portrait. Workaround checks screen size
  //TODO(?): Better handling of upside down (check if app supports it?)
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
    self.frame = CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width, _barHeight);
  }
  else
  {
    self.frame = CGRectMake(0,-_barHeight,[UIScreen mainScreen].bounds.size.width, _barHeight);
  }

  self.rootViewController.view.frame = CGRectMake(0,_barHeight-20,self.frame.size.width,20);
}

- (void)dispatchNotification:(SPStatusBarNotification*)notification
{
  [self dispatchNotification:notification completion:nil];
}

- (void)dispatchNotification:(SPStatusBarNotification*)notification completion:(void(^)(void))completion
{
  if(!_isPresented && !_isBeingPresented && !_isBeingDismissed)
  {
    [_textView setCurrentNotification:notification];
    self.hidden = NO;
    [self updateFrame];

    self.backgroundColor = notification.backgroundColor;

    _isBeingPresented = YES;

    dispatch_async(dispatch_get_main_queue(),
    ^{
      [UIView animateWithDuration:.3 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:
      ^{
        self.frame  = CGRectMake(0, 0, self.frame.size.width,self.frame.size.height);
      }
      completion:^(BOOL finished)
      {
        _isBeingPresented = NO;
        _isPresented = YES;

        if(notification.dismissAfter)
        {
          _timer = [NSTimer scheduledTimerWithTimeInterval:notification.dismissAfter target:self selector:@selector(dismiss) userInfo:nil repeats:NO];
        }

        if(completion)
        {
          completion();
        }

        if(_shouldImmediatlyDismiss)
        {
          _shouldImmediatlyDismiss = NO;
          [self dismissWithCompletion:_savedBlock];
        }
      }];
    });
  }
  else if(_isBeingDismissed)
  {
    _shouldImmediatlyPresent = YES;
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
        self.frame  = CGRectMake(0, -_barHeight, self.frame.size.width,self.frame.size.height);
      } completion:^(BOOL finished)
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

        if(_shouldImmediatlyPresent)
        {
          _shouldImmediatlyPresent = NO;
          [self dispatchNotification:_savedNotification completion:_savedBlock];
        }
      }];
    });
  }
  else if(_isBeingPresented)
  {
    _shouldImmediatlyDismiss = YES;
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
