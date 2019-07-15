// SPDownloadsBarButtonItemView.mm
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

#import "SPDownloadsBarButtonItemView.h"
#import "SPDownloadsBarButtonItem.h"
#import "../Util.h"

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

	[_downloadsButton addTarget:_item.target action:_item.action forControlEvents:UIControlEventTouchUpInside];
	[_downloadsButton setImage:[UIImage imageNamed:@"DownloadsButton" inBundle:SPBundle compatibleWithTraitCollection:nil] forState:UIControlStateNormal];

	[self addSubview:_progressView];
	[self addSubview:_downloadsButton];

	[self setUpConstraints];

	return self;
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
