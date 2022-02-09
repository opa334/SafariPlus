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

#import "SPCellDownloadProgressView.h"

@implementation SPCellDownloadProgressView

- (instancetype)init
{
	self = [super init];

	_sizeProgressLabel = [[UILabel alloc] init];
	_sizeProgressLabel.translatesAutoresizingMaskIntoConstraints = NO;
	_sizeProgressLabel.textAlignment = NSTextAlignmentRight;
	_sizeProgressLabel.font = [_sizeProgressLabel.font fontWithSize:8];

	_sizeSpeedSeparatorLabel = [[UILabel alloc] init];
	_sizeSpeedSeparatorLabel.translatesAutoresizingMaskIntoConstraints = NO;
	_sizeSpeedSeparatorLabel.textAlignment = NSTextAlignmentCenter;
	_sizeSpeedSeparatorLabel.font = [_sizeSpeedSeparatorLabel.font fontWithSize:8];
	_sizeSpeedSeparatorLabel.text = @"@";

	_downloadSpeedLabel = [[UILabel alloc] init];
	_downloadSpeedLabel.translatesAutoresizingMaskIntoConstraints = NO;
	_downloadSpeedLabel.textAlignment = NSTextAlignmentLeft;
	_downloadSpeedLabel.font = [_downloadSpeedLabel.font fontWithSize:8];

	_progressView = [[UIProgressView alloc] init];
	_progressView.translatesAutoresizingMaskIntoConstraints = NO;

	_percentProgressLabel = [[UILabel alloc] init];
	_percentProgressLabel.translatesAutoresizingMaskIntoConstraints = NO;
	_percentProgressLabel.textAlignment = NSTextAlignmentCenter;
	_percentProgressLabel.font = [_percentProgressLabel.font fontWithSize:8];

	[self addSubview:_sizeProgressLabel];
	[self addSubview:_sizeSpeedSeparatorLabel];
	[self addSubview:_downloadSpeedLabel];
	[self addSubview:_progressView];
	[self addSubview:_percentProgressLabel];

	[self setUpConstraints];
	self.showsDownloadSpeed = YES;

	return self;
}

- (void)setUpConstraints
{
	_downloadSpeedShownConstraints = @[
		//Horizontal

		//First row
		[NSLayoutConstraint constraintWithItem:_sizeSpeedSeparatorLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
		 toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:8],
		[NSLayoutConstraint constraintWithItem:_sizeSpeedSeparatorLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual
		 toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:_sizeProgressLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
		 toItem:self attribute:NSLayoutAttributeLeading multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:_sizeProgressLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
		 toItem:_sizeSpeedSeparatorLabel attribute:NSLayoutAttributeLeading multiplier:1 constant:-7.5],
		[NSLayoutConstraint constraintWithItem:_downloadSpeedLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
		 toItem:_sizeSpeedSeparatorLabel attribute:NSLayoutAttributeTrailing multiplier:1 constant:7.5],
		[NSLayoutConstraint constraintWithItem:_downloadSpeedLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
		 toItem:self attribute:NSLayoutAttributeTrailing multiplier:1 constant:0],

		//Vertical

		//First row
		[NSLayoutConstraint constraintWithItem:_sizeSpeedSeparatorLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
		 toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:8],
		[NSLayoutConstraint constraintWithItem:_downloadSpeedLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
		 toItem:_sizeSpeedSeparatorLabel attribute:NSLayoutAttributeHeight multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:_sizeSpeedSeparatorLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
		 toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:_downloadSpeedLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
		 toItem:_sizeSpeedSeparatorLabel attribute:NSLayoutAttributeTop multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:_sizeProgressLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
		 toItem:_sizeSpeedSeparatorLabel attribute:NSLayoutAttributeHeight multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:_sizeProgressLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
		 toItem:_sizeSpeedSeparatorLabel attribute:NSLayoutAttributeTop multiplier:1 constant:0],
	];

	_downloadSpeedNotShownConstraints = @[
		//Horizontal

		//First row
		[NSLayoutConstraint constraintWithItem:_sizeProgressLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual
		 toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0],

		//Vertical

		//First row
		[NSLayoutConstraint constraintWithItem:_sizeProgressLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
		 toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:_sizeProgressLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
		 toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:8],

	];


	[NSLayoutConstraint activateConstraints:@[
		//Horizontal

		//Second row
		 [NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
		  toItem:self attribute:NSLayoutAttributeLeading multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
		  toItem:self attribute:NSLayoutAttributeTrailing multiplier:1 constant:0],
		//Third row
		 [NSLayoutConstraint constraintWithItem:_percentProgressLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
		  toItem:self attribute:NSLayoutAttributeLeading multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_percentProgressLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
		  toItem:self attribute:NSLayoutAttributeTrailing multiplier:1 constant:0],

		//Vertical

		//Second row
		 [NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
		  toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:3],
		 [NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
		  toItem:_sizeProgressLabel attribute:NSLayoutAttributeBottom multiplier:1 constant:2.5],
		//Third row
		 [NSLayoutConstraint constraintWithItem:_percentProgressLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
		  toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:8],
		 [NSLayoutConstraint constraintWithItem:_percentProgressLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
		  toItem:_progressView attribute:NSLayoutAttributeBottom multiplier:1 constant:2.5],
		 [NSLayoutConstraint constraintWithItem:_percentProgressLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
		  toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:-2.5],
	]];
}

- (void)setColor:(UIColor*)color
{
	_sizeProgressLabel.textColor = color;
	_sizeSpeedSeparatorLabel.textColor = color;
	_downloadSpeedLabel.textColor = color;
	_progressView.progressTintColor = color;
	_percentProgressLabel.textColor = color;
}

- (void)setShowsDownloadSpeed:(BOOL)showsDownloadSpeed
{
	if(_showsDownloadSpeed != showsDownloadSpeed)
	{
		_showsDownloadSpeed = showsDownloadSpeed;

		if(_showsDownloadSpeed)
		{
			[NSLayoutConstraint activateConstraints:_downloadSpeedShownConstraints];
			[NSLayoutConstraint deactivateConstraints:_downloadSpeedNotShownConstraints];
		}
		else
		{
			[NSLayoutConstraint activateConstraints:_downloadSpeedNotShownConstraints];
			[NSLayoutConstraint deactivateConstraints:_downloadSpeedShownConstraints];
		}

		_sizeSpeedSeparatorLabel.hidden = !_showsDownloadSpeed;
		_downloadSpeedLabel.hidden = !_showsDownloadSpeed;
	}
}

@end
