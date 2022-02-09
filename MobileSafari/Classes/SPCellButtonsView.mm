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
