// SPStatusBarNotificationWindow.h
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

#import <UIKit/UIKit.h>

@class SPStatusBarNotification, SPStatusBarTextView;

@interface SPStatusBarNotificationWindow : UIWindow
{
  BOOL _isPresented;
  BOOL _isBeingPresented;
  BOOL _isBeingDismissed;
  BOOL _shouldImmediatlyDismiss;
  BOOL _shouldImmediatlyPresent;
  CGFloat _barHeight;
  SPStatusBarTextView* _textView;
  NSTimer* _timer;
  void (^_savedBlock)(void);
  SPStatusBarNotification* _savedNotification;
}

- (void)updateFrame;

- (void)dispatchNotification:(SPStatusBarNotification*)notification;
- (void)dispatchNotification:(SPStatusBarNotification*)notification completion:(void(^)(void))completion;

- (void)dismiss;
- (void)dismissWithCompletion:(void(^)(void))completion;

@end
