// Copyright (c) 2017-2022 Lars Fröder

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

#import "SPStatusBarNotificationWindow.h"
#import "SPStatusBarNotification.h"
#import "SPStatusBarTextView.h"
#import "../Util.h"
#import "../Defines.h"

#define DEGREES_TO_RADIANS(degrees)((M_PI * degrees)/180)

#define IS_PAD_OVER_8 (IS_PAD && kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0)

@interface UIWindow ()
- (BOOL)_canAffectStatusBarAppearance;
- (UIInterfaceOrientation)interfaceOrientation;
@end

@interface UIView ()
+ (double)_durationForRotationFromInterfaceOrientation:(UIInterfaceOrientation)arg1 toInterfaceOrientation:(UIInterfaceOrientation)arg2;
+ (int)_degreesToRotateFromInterfaceOrientation:(UIInterfaceOrientation)arg1 toInterfaceOrientation:(UIInterfaceOrientation)arg2;
@end

@implementation SPStatusBarNotificationWindow

- (instancetype)init
{
	self = [super init];

	self.currentDeviceOrientation = [self interfaceOrientation];

	self.windowLevel = 10000003; //video player on iOS 10 is on window level 10000002
	self.clipsToBounds = YES;

	//Init and add textView
	_textView = [[SPStatusBarTextView alloc] init];
	[self addSubview:_textView];

	//Register for orientation changes
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];

	return self;
}

- (UIWindowScene*)sceneToUse
{
	if(_currentWindowToPresentOn)
	{
		return _currentWindowToPresentOn.windowScene;
	}
	else
	{
		//Stolen from FLEX: https://github.com/Flipboard/FLEX/blob/master/Classes/Manager/FLEXManager.m#L78
		for(UIScene *scene in UIApplication.sharedApplication.connectedScenes)
		{
			if(scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]])
			{
				return (UIWindowScene*)scene;
			}
		}
	}
	
	return nil;
}

- (void)setHidden:(BOOL)hidden
{
	[super setHidden:hidden];

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0)
	{
		if(!hidden)
		{
			if(!self.windowScene || self.windowScene.activationState != UISceneActivationStateForegroundActive)
			{
				self.windowScene = [self sceneToUse];
			}
		}
		else
		{
			self.windowScene = nil;
		}
	}
}

- (BOOL)_canAffectStatusBarAppearance
{
	return NO;
}

- (void)updateFramesForTransform
{
	_barHeight = 20;

	if([[UIApplication sharedApplication].keyWindow respondsToSelector:@selector(safeAreaInsets)])
	{
		double safeTop = [UIApplication sharedApplication].keyWindow.safeAreaInsets.top;
		if(safeTop > 24)
		{
			_barHeight += (safeTop - 14);
		}
	}

	CGSize screenSize;
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0)
	{
		UIWindowScene* scene = [self sceneToUse];
		if(!scene)
		{
			return;
		}
		screenSize = scene.coordinateSpace.bounds.size;
	}
	else
	{
		screenSize = [UIScreen mainScreen].bounds.size;
	}

	CGFloat c = self.transform.c;

	//Normal
	if(c == 0 || IS_PAD_OVER_8)	//Yes, apparently iPads auto adjust to the orientation on iOS 9 and above (Why???)
	{
		if(_isPresented)
		{
			self.frame = CGRectMake(0,0,screenSize.width, _barHeight);
		}
		else
		{
			self.frame = CGRectMake(0,-_barHeight,screenSize.width, _barHeight);
		}
	}
	//Rotated to left
	else if(c == -1)
	{
		if(_isPresented)
		{
			self.frame = CGRectMake(screenSize.height-_barHeight,0,_barHeight,screenSize.width);
		}
		else
		{
			self.frame = CGRectMake(screenSize.height,0,_barHeight,screenSize.width);
		}
	}
	//Rotated to right
	else if(c == 1)
	{
		if(_isPresented)
		{
			self.frame = CGRectMake(0,0,_barHeight,screenSize.width);
		}
		else
		{
			self.frame = CGRectMake(-_barHeight,0,_barHeight,screenSize.width);
		}
	}
	//Upside down
	else
	{
		if(_isPresented)
		{
			self.frame = CGRectMake(0, screenSize.height - _barHeight, screenSize.width, _barHeight);
		}
		else
		{
			self.frame = CGRectMake(0, screenSize.height, screenSize.width, _barHeight);
		}
	}

	//All commentented display orientations are relative to the orientation that Safari was originally launched in
	//So for example, if you start Safari while being in landscape mode on a plus device, that is the 'normal' orientation
	//No need to thank me for that, go thank apple!

	_textView.frame = CGRectMake(0,-20+_barHeight,screenSize.width,20);
}

- (void)orientationDidChange
{
	self.currentDeviceOrientation = [UIApplication sharedApplication].statusBarOrientation;
}

- (void)setCurrentDeviceOrientation:(UIInterfaceOrientation)newOrientation
{
	UIInterfaceOrientation prevOrientation = _currentDeviceOrientation;

	_currentDeviceOrientation = newOrientation;

	// iPads handle everything different???
	if(prevOrientation && !IS_PAD_OVER_8)
	{
		int degrees = [UIView _degreesToRotateFromInterfaceOrientation:prevOrientation toInterfaceOrientation:newOrientation];
		self.transform = CGAffineTransformRotate(self.transform, DEGREES_TO_RADIANS(degrees));
	}

	[self updateFramesForTransform];
}

- (void)dispatchNotification:(SPStatusBarNotification*)notification
{
	[self dispatchNotification:notification completion:nil];
}

- (void)dispatchNotification:(SPStatusBarNotification*)notification completion:(void (^)(void))completion
{
	if(!_isPresented && !_isBeingPresented && !_isBeingDismissed)
	{
		_isBeingPresented = YES;

		dispatch_async(dispatch_get_main_queue(), ^
		{
			_currentWindowToPresentOn = notification.windowToPresentOn;
			[self updateFramesForTransform];

			self.hidden = NO;
			self.backgroundColor = notification.backgroundColor;

			[_textView setCurrentNotification:notification];

			[UIView animateWithDuration:.3 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^
			{
				_isPresented = YES;
				[self updateFramesForTransform];
			} completion:^(BOOL finished)
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

- (void)dismissWithCompletion:(void (^)(void))completion
{
	if(_isPresented && !_isBeingPresented && !_isBeingDismissed)
	{
		_isBeingDismissed = YES;
		dispatch_async(dispatch_get_main_queue(),^
		{
			[self updateFramesForTransform];

			[UIView animateWithDuration:.3 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^
			{
				_isPresented = NO;
				[self updateFramesForTransform];
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
