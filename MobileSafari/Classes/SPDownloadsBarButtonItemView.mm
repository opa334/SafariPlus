// Copyright (c) 2017-2021 Lars Fröder

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

#import "SPDownloadsBarButtonItemView.h"
#import "SPDownloadsBarButtonItem.h"
#import "../Util.h"
#import "../SafariPlus.h"
#import "../Defines.h"

@implementation SPDownloadsBarButtonItemView

- (instancetype)initWithItem:(SPDownloadsBarButtonItem*)item progressViewHidden:(BOOL)progressViewHidden initialProgress:(float)initialProgress;
{
	self = [super init];

	_item = item;

	_progressViewHidden = progressViewHidden;

	_progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
	_progressView.translatesAutoresizingMaskIntoConstraints = NO;
	[_progressView setProgress:initialProgress animated:NO];
	_progressView.hidden = _progressViewHidden;

	_downloadsButton = [UIButton buttonWithType:UIButtonTypeSystem];
	_downloadsButton.translatesAutoresizingMaskIntoConstraints = NO;

	[_downloadsButton addTarget:self action:@selector(sendTouchUpInsideEvent) forControlEvents:UIControlEventTouchUpInside];

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0)
	{
		UIImageSymbolConfiguration* symbolConfiguration = [NSClassFromString(@"UIImageSymbolConfiguration") configurationWithTextStyle:UIFontTextStyleBody scale:UIImageSymbolScaleLarge];
        symbolConfiguration = [symbolConfiguration configurationWithTraitCollection:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:UIContentSizeCategoryMedium]];
        [_downloadsButton setImage:[UIImage systemImageNamed:@"arrow.down.circle" withConfiguration:symbolConfiguration] forState:UIControlStateNormal];
	}
	else
	{
		[_downloadsButton setImage:[UIImage imageNamed:@"DownloadsButton" inBundle:SPBundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];
	}

	[self addSubview:_progressView];
	[self addSubview:_downloadsButton];

	[self setUpConstraints];

	return self;
}

- (void)sendTouchUpInsideEvent
{
	[[UIApplication sharedApplication] sendAction:_item.action to:_item.target from:_item forEvent:nil];
}

- (void)setUpConstraints
{
	_progressViewHiddenConstraints = @[
		//Horizontal
		[NSLayoutConstraint constraintWithItem:_downloadsButton attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
		 toItem:self attribute:NSLayoutAttributeLeading multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:_downloadsButton attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
		 toItem:self attribute:NSLayoutAttributeTrailing multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
		 toItem:self attribute:NSLayoutAttributeLeading multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
		 toItem:self attribute:NSLayoutAttributeTrailing multiplier:1 constant:0],
		//Vertical
		[NSLayoutConstraint constraintWithItem:_downloadsButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
		 toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:_downloadsButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
		 toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
		 toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:2],
		[NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
		 toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
	];

	_progressViewShownConstraints = @[
		//Horizontal
		[NSLayoutConstraint constraintWithItem:_downloadsButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual
		 toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:_downloadsButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
		 toItem:_downloadsButton attribute:NSLayoutAttributeHeight multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
		 toItem:self attribute:NSLayoutAttributeLeading multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
		 toItem:self attribute:NSLayoutAttributeTrailing multiplier:1 constant:0],
		//Vertical
		[NSLayoutConstraint constraintWithItem:_downloadsButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
		 toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:_downloadsButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
		 toItem:_progressView attribute:NSLayoutAttributeTop multiplier:1 constant:-2],
		[NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
		 toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:2],
		[NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
		 toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
	];

	if(_progressViewHidden)
	{
		[NSLayoutConstraint activateConstraints:_progressViewHiddenConstraints];
	}
	else
	{
		[NSLayoutConstraint activateConstraints:_progressViewShownConstraints];
	}
}

- (void)setProgressViewHidden:(BOOL)progressViewHidden
{
	if(_progressViewHidden != progressViewHidden)
	{
		_progressViewHidden = progressViewHidden;

		[self layoutIfNeeded];

		[UIView animateWithDuration:0.5 animations:^
		{
			if(_progressViewHidden)
			{
				[NSLayoutConstraint deactivateConstraints:_progressViewShownConstraints];
				[NSLayoutConstraint activateConstraints:_progressViewHiddenConstraints];
				_progressView.alpha = 1.0;
				_progressView.alpha = 0.0;
			}
			else
			{
				[NSLayoutConstraint deactivateConstraints:_progressViewHiddenConstraints];
				[NSLayoutConstraint activateConstraints:_progressViewShownConstraints];
				_progressView.hidden = NO;
				_progressView.alpha = 0.0;
				_progressView.alpha = 1.0;
			}

			[self layoutIfNeeded];
		} completion:^(BOOL finished)
		{
			if(_progressViewHidden)
			{
				_progressView.hidden = YES;
			}
		}];
	}
}

- (void)updateProgress:(float)progress animated:(BOOL)animated
{
	[_progressView setProgress:progress animated:animated];
}

- (UIButton*)downloadsButton
{
	return _downloadsButton;
}

@end
