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

#import "UIButton+ActivityIndicator.h"
#import "../Defines.h"

#import <objc/runtime.h>

@implementation UIButton (ActivityIndicator)

- (void)setUpActivityIndicator
{
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0)
	{
		self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	}
	else
	{
		self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	}

	self.activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
	self.activityIndicatorView.hidden = YES;
	[self addSubview:self.activityIndicatorView];

	NSDictionary* views = @{@"activityIndicatorView" : self.activityIndicatorView};

	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[activityIndicatorView]-0-|" options:0 metrics:nil views:views]];
	[self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[activityIndicatorView]-0-|" options:0 metrics:nil views:views]];
}

- (UIActivityIndicatorView*)activityIndicatorView
{
	return objc_getAssociatedObject(self, "activityIndicatorView");
}

- (void)setActivityIndicatorView:(UIActivityIndicatorView*)activityIndicatorView
{
	objc_setAssociatedObject(self, "activityIndicatorView", activityIndicatorView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)spinning
{
	return [objc_getAssociatedObject(self, "spinning") boolValue];
}

- (void)setSpinning:(BOOL)spinning
{
	BOOL _spinning = [self spinning];

	if(spinning != _spinning)
	{
		objc_setAssociatedObject(self, "spinning", [NSNumber numberWithBool:spinning], OBJC_ASSOCIATION_RETAIN_NONATOMIC);

		dispatch_async(dispatch_get_main_queue(), ^
		{
			if(spinning)
			{
				[self.activityIndicatorView startAnimating];
				self.activityIndicatorView.hidden = NO;
			}
			else
			{
				self.activityIndicatorView.hidden = YES;
				[self.activityIndicatorView stopAnimating];
			}
		});
	}
}

@end
