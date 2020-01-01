// Copyright (c) 2017-2020 Lars Fröder

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

#import "SPTabManagerTableViewCell.h"

#import "../Util.h"
#import "SPPreferenceManager.h"
#import "../SafariPlus.h"
#import "Extensions.h"

@implementation SPTabManagerTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

	_showsTabIcon = NO;
	_showsLockIcon = NO;
	_showsURLLabel = YES;

	[self initContent];

	[self setUpConstraints];

	return self;
}

- (void)applyTabDocument:(TabDocument*)tabDocument
{
	_tabDocument = tabDocument;
	_tabDocument.tabManagerViewCell = self;

	[self updateContentAnimated:NO];
}

- (void)updateContent
{
	[self updateContentAnimated:YES];
}

- (void)updateContentAnimated:(BOOL)animated
{
	_titleLabel.text = [_tabDocument title];

	if([_tabDocument URL])
	{
		_URLLabel.text = [_tabDocument URL].absoluteString;
		self.showsURLLabel = YES;
	}
	else
	{
		_URLLabel.text = nil;
		self.showsURLLabel = NO;
	}

	if(preferenceManager.lockedTabsEnabled)
	{
		[self setShowsLockIcon:_tabDocument.locked animated:animated];
	}
	else
	{
		self.showsLockIcon = NO;
	}

	if(_tabDocument.currentTabIcon)
	{
		_tabIconImageView.image = _tabDocument.currentTabIcon;
		self.showsTabIcon = YES;
	}
	else
	{
		_tabIconImageView.image = nil;
		self.showsTabIcon = NO;
	}
}

- (void)prepareForReuse
{
	[super prepareForReuse];

	if(_tabDocument.tabManagerViewCell == self)
	{
		_tabDocument.tabManagerViewCell = nil;
	}
}

- (void)initContent
{
	_titleLockView = [UIView autolayoutView];

	_titleLabel = [UILabel autolayoutView];
	_titleLabel.textAlignment = NSTextAlignmentLeft;
	_titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	if([_titleLabel respondsToSelector:@selector(setAdjustsFontForContentSizeCategory:)])
	{
		_titleLabel.adjustsFontForContentSizeCategory = YES;
	}

	_lockIconView = [UIImageView autolayoutView];
	_lockIconView.image = [[UIImage imageNamed:@"LockButton_Closed" inBundle:SPBundle compatibleWithTraitCollection:nil] _flatImageWithColor:_titleLabel.textColor];
	_lockIconView.contentMode = UIViewContentModeCenter;
	_lockIconView.hidden = !_showsLockIcon;

	[_titleLockView addSubview:_titleLabel];
	[_titleLockView addSubview:_lockIconView];

	_URLLabel = [UILabel autolayoutView];
	_URLLabel.textAlignment = NSTextAlignmentLeft;
	_URLLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
	if([_URLLabel respondsToSelector:@selector(setAdjustsFontForContentSizeCategory:)])
	{
		_URLLabel.adjustsFontForContentSizeCategory = YES;
	}
	_URLLabel.hidden = !_showsURLLabel;

	_tabIconImageView = [UIImageView autolayoutView];
	_tabIconImageView.hidden = !_showsTabIcon;

	[self.contentView addSubview:_titleLockView];
	[self.contentView addSubview:_URLLabel];
	[self.contentView addSubview:_tabIconImageView];
}

- (void)setShowsTabIcon:(BOOL)showsTabIcon
{
	if(_showsTabIcon != showsTabIcon)
	{
		_showsTabIcon = showsTabIcon;

		if(_showsTabIcon)
		{
			_tabIconImageView.hidden = NO;
			[NSLayoutConstraint deactivateConstraints:_noTabIconConstraints];
			[NSLayoutConstraint activateConstraints:_tabIconConstraints];
		}
		else
		{
			_tabIconImageView.hidden = YES;
			[NSLayoutConstraint deactivateConstraints:_tabIconConstraints];
			[NSLayoutConstraint activateConstraints:_noTabIconConstraints];
		}
	}
}

- (void)setShowsURLLabel:(BOOL)showsURLLabel
{
	if(_showsURLLabel != showsURLLabel)
	{
		_showsURLLabel = showsURLLabel;

		if(_showsURLLabel)
		{
			_URLLabel.hidden = NO;
			[NSLayoutConstraint deactivateConstraints:_noURLLabelConstraints];
			[NSLayoutConstraint activateConstraints:_URLLabelConstraints];
		}
		else
		{
			_URLLabel.hidden = YES;
			[NSLayoutConstraint deactivateConstraints:_URLLabelConstraints];
			[NSLayoutConstraint activateConstraints:_noURLLabelConstraints];
		}
	}
}

- (void)setShowsLockIcon:(BOOL)showsLockIcon
{
	[self setShowsLockIcon:showsLockIcon animated:NO];
}

- (void)setShowsLockIcon:(BOOL)showsLockIcon animated:(BOOL)animated
{
	if(_showsLockIcon != showsLockIcon)
	{
		_showsLockIcon = showsLockIcon;

		if(animated)
		{
			[self layoutIfNeeded];

			[UIView animateWithDuration:0.5 animations:^
			{
				if(_showsLockIcon)
				{
					[NSLayoutConstraint deactivateConstraints:_noLockViewConstraints];
					[NSLayoutConstraint activateConstraints:_lockViewConstraints];
					_lockIconView.hidden = NO;
					_lockIconView.alpha = 0.0;
					_lockIconView.alpha = 1.0;
				}
				else
				{
					[NSLayoutConstraint deactivateConstraints:_lockViewConstraints];
					[NSLayoutConstraint activateConstraints:_noLockViewConstraints];
					_lockIconView.alpha = 1.0;
					_lockIconView.alpha = 0.0;
				}

				[self layoutIfNeeded];
			} completion:^(BOOL finished)
			{
				if(!_showsLockIcon)
				{
					_lockIconView.hidden = YES;
				}
			}];
		}
		else
		{
			if(_showsLockIcon)
			{
				_lockIconView.hidden = NO;
				_lockIconView.alpha = 1.0;
				[NSLayoutConstraint deactivateConstraints:_noLockViewConstraints];
				[NSLayoutConstraint activateConstraints:_lockViewConstraints];
			}
			else
			{
				_lockIconView.hidden = YES;
				_lockIconView.alpha = 0.0;
				[NSLayoutConstraint deactivateConstraints:_lockViewConstraints];
				[NSLayoutConstraint activateConstraints:_noLockViewConstraints];
			}
		}
	}
}

- (void)setUpConstraints
{
	_tabIconConstraints = @[
		//Horizontal
		[NSLayoutConstraint constraintWithItem:_tabIconImageView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
		 toItem:self.contentView attribute:NSLayoutAttributeLeadingMargin multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:_tabIconImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
		 toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:30],
		[NSLayoutConstraint constraintWithItem:_titleLockView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
		 toItem:_tabIconImageView attribute:NSLayoutAttributeTrailing multiplier:1 constant:8],
		[NSLayoutConstraint constraintWithItem:_URLLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
		 toItem:_tabIconImageView attribute:NSLayoutAttributeTrailing multiplier:1 constant:8],

		//Vertical
		[NSLayoutConstraint constraintWithItem:_tabIconImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
		 toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:_tabIconImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
		 toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:30],
	];

	_noTabIconConstraints = @[
		//Horizontal
		[NSLayoutConstraint constraintWithItem:_titleLockView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
		 toItem:self.contentView attribute:NSLayoutAttributeLeadingMargin multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:_URLLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
		 toItem:self.contentView attribute:NSLayoutAttributeLeadingMargin multiplier:1 constant:0],
	];

	_URLLabelConstraints = @[
		//Vertical
		[NSLayoutConstraint constraintWithItem:_titleLockView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
		 toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1 constant:5],
		[NSLayoutConstraint constraintWithItem:_titleLockView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual
		 toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:_URLLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
		 toItem:_titleLockView attribute:NSLayoutAttributeBottom multiplier:1 constant:2.5],
		[NSLayoutConstraint constraintWithItem:_URLLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual
		 toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:_URLLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
		 toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:-5],
	];

	_noURLLabelConstraints = @[
		//Vertical
		[NSLayoutConstraint constraintWithItem:_titleLockView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
		 toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0],
	];

	_lockViewConstraints = @[
		//Horizontal
		[NSLayoutConstraint constraintWithItem:_lockIconView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
		 toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:11],
		[NSLayoutConstraint constraintWithItem:_lockIconView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
		 toItem:_titleLabel attribute:NSLayoutAttributeLeading multiplier:1 constant:-5],
	];

	_noLockViewConstraints = @[
		//Horizontal
		[NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
		 toItem:_titleLockView attribute:NSLayoutAttributeLeading multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:_lockIconView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
		 toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:0],
	];

	[NSLayoutConstraint activateConstraints:@[
		//Horizontal
		 [NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
		  toItem:_titleLockView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_lockIconView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
		  toItem:_titleLockView attribute:NSLayoutAttributeLeading multiplier:1 constant:0],

		 [NSLayoutConstraint constraintWithItem:_titleLockView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
		  toItem:self.contentView attribute:NSLayoutAttributeTrailingMargin multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_URLLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
		  toItem:self.contentView attribute:NSLayoutAttributeTrailingMargin multiplier:1 constant:0],

		//Vertical
		 [NSLayoutConstraint constraintWithItem:_lockIconView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
		  toItem:_titleLockView attribute:NSLayoutAttributeTop multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_lockIconView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
		  toItem:_titleLockView attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
		  toItem:_titleLockView attribute:NSLayoutAttributeTop multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
		  toItem:_titleLockView attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
	]];

	if(_showsTabIcon)
	{
		[NSLayoutConstraint activateConstraints:_tabIconConstraints];
	}
	else
	{
		[NSLayoutConstraint activateConstraints:_noTabIconConstraints];
	}

	if(_showsURLLabel)
	{
		[NSLayoutConstraint activateConstraints:_URLLabelConstraints];
	}
	else
	{
		[NSLayoutConstraint activateConstraints:_noURLLabelConstraints];
	}

	if(_showsLockIcon)
	{
		[NSLayoutConstraint activateConstraints:_lockViewConstraints];
	}
	else
	{
		[NSLayoutConstraint activateConstraints:_noLockViewConstraints];
	}
}

//Minimum height of 44

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority verticalFittingPriority:(UILayoutPriority)verticalFittingPriority
{
	CGSize size = [super systemLayoutSizeFittingSize:targetSize withHorizontalFittingPriority:horizontalFittingPriority verticalFittingPriority:verticalFittingPriority];
	if(size.height < 44)
	{
		return CGSizeMake(targetSize.width, 44);
	}
	return size;
}

@end
