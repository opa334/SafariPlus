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

#import "SPCellIconLabelView.h"

@implementation SPCellIconLabelView

- (instancetype)init
{
	self = [super init];

	_iconView = [[UIImageView alloc] init];
	_iconView.translatesAutoresizingMaskIntoConstraints = NO;
	_iconView.contentMode = UIViewContentModeScaleAspectFit;

	_label = [[UILabel alloc] init];
	_label.translatesAutoresizingMaskIntoConstraints = NO;

	_label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	if([_label respondsToSelector:@selector(setAdjustsFontForContentSizeCategory:)])
	{
		_label.adjustsFontForContentSizeCategory = YES;
	}

	[self addSubview:_iconView];
	[self addSubview:_label];

	[self setUpConstraints];

	return self;
}

- (void)setUpConstraints
{
	[NSLayoutConstraint activateConstraints:@[
		//Horizontal
		 [NSLayoutConstraint constraintWithItem:_iconView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
		  toItem:self attribute:NSLayoutAttributeLeading multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_iconView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
		  toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:30],
		 [NSLayoutConstraint constraintWithItem:_label attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
		  toItem:_iconView attribute:NSLayoutAttributeTrailing multiplier:1 constant:15],
		 [NSLayoutConstraint constraintWithItem:_label attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
		  toItem:self attribute:NSLayoutAttributeTrailing multiplier:1 constant:0],

		//Vertical
		 [NSLayoutConstraint constraintWithItem:_iconView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
		  toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:32],
		 [NSLayoutConstraint constraintWithItem:_iconView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
		  toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:6],
		 [NSLayoutConstraint constraintWithItem:_iconView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
		  toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:-6],
		 [NSLayoutConstraint constraintWithItem:_label attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual
		  toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:30],
		 [NSLayoutConstraint constraintWithItem:_label attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
		  toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:7],
		 [NSLayoutConstraint constraintWithItem:_label attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
		  toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:-7],
	]];
}

@end
