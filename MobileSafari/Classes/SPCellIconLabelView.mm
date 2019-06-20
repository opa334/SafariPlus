// SPCellIconLabelView.mm
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
