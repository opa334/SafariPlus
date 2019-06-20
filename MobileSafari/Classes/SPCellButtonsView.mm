// SPCellButtonsView.mm
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

#import "SPCellButtonsView.h"

@implementation SPCellButtonsView

- (instancetype)init
{
	self = [super init];

	//Init with default values
	_displaysBottomButton = YES;

	_topButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_topButton.adjustsImageWhenHighlighted = YES;

	_bottomButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_bottomButton.adjustsImageWhenHighlighted = YES;

	_topButton.backgroundColor = [UIColor colorWithRed:0 green:(55.0 / 255.0) blue:(194.0 / 255.0) alpha:1];
	_topButton.tintColor = [UIColor whiteColor];

	_bottomButton.backgroundColor = [UIColor colorWithRed:0 green:(55.0 / 255.0) blue:(194.0 / 255.0) alpha:1];
	_bottomButton.tintColor = [UIColor whiteColor];

	[self addSubview:_topButton];
	[self addSubview:_bottomButton];

	return self;
}

- (void)setDisplaysBottomButton:(BOOL)displaysBottomButton
{
	if(displaysBottomButton != _displaysBottomButton)
	{
		_displaysBottomButton = displaysBottomButton;

		if(_displaysBottomButton)
		{
			[self addSubview:_bottomButton];
		}
		else
		{
			[_bottomButton removeFromSuperview];
		}

		[self setNeedsLayout];
	}
}

//Fuck autolayout
- (void)layoutSubviews
{
	[super layoutSubviews];

	CGFloat buttonSize = self.bounds.size.width;
	CGFloat height = self.bounds.size.height;

	if(_displaysBottomButton)
	{
		CGFloat spacing = (height - buttonSize * 2) / 3;
		_topButton.frame = CGRectMake(0,spacing,buttonSize,buttonSize);
		_bottomButton.frame = CGRectMake(0,height - spacing - buttonSize,buttonSize,buttonSize);
	}
	else
	{
		CGFloat y = (height / 2) - (buttonSize / 2);

		#ifdef CGFLOAT_IS_DOUBLE
		y = lround(y);
		#else
		y = lroundf(y);
		#endif

		_topButton.frame = CGRectMake(0,y,buttonSize,buttonSize);
	}

	_topButton.layer.masksToBounds = YES;
	_topButton.layer.cornerRadius = buttonSize / 2;

	_bottomButton.layer.masksToBounds = YES;
	_bottomButton.layer.cornerRadius = buttonSize / 2;
}

@end
