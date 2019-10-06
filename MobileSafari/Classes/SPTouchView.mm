// Copyright (c) 2017-2019 Lars Fröder

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

#import "SPTouchView.h"
#import "../Defines.h"

@implementation SPTouchView

- (instancetype)initWithFrame:(CGRect)frame touchReceiver:(UIView*)touchReceiver
{
	self = [super initWithFrame:frame];
	self.touchReceiver = touchReceiver;
	return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent*)event
{
	UIView* hitView = [super hitTest:point withEvent:event];

	CGFloat extendedWidth = 0;
	CGFloat extendedHeight = 0;

	if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_11_0)
	{
		extendedWidth = 11;
		extendedHeight = 2.5;
	}

	if((point.x > -extendedWidth && point.x <= self.frame.size.width + extendedWidth) && (point.y > -extendedHeight && point.y <= self.frame.size.height + extendedHeight))
	{
		return self.touchReceiver;
	}

	return hitView;
}

@end
