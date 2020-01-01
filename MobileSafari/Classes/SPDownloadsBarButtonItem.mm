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

#import "SPDownloadsBarButtonItem.h"
#import "SPDownloadsBarButtonItemView.h"
#import "SPDownloadManager.h"
#import "SPPreferenceManager.h"
#import "SPTouchView.h"
#import "../Defines.h"
#import "../Util.h"

@implementation SPDownloadsBarButtonItem

- (instancetype)initWithTarget:(id)target action:(SEL)action
{
	return [self initWithTarget:target action:action placement:0];
}

- (instancetype)initWithTarget:(id)target action:(SEL)action placement:(NSInteger)placement
{
	self = [super init];

	self.target = target;
	self.action = action;
	self.style = UIBarButtonItemStylePlain;

	CGFloat width, height;
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0)
	{
		if(placement == 1)
		{
			width = 60;
		}
		else
		{
			width = 25;
		}

		height = 44;
	}
	else if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0)
	{
		width = 35;
		height = 44;
	}
	else
	{
		width = 25;
		height = 25;
	}

	_itemView = [[SPDownloadsBarButtonItemView alloc] initWithItem:self progressViewHidden:([downloadManager runningDownloadsCount] == 0) initialProgress:[downloadManager progressOfAllRunningDownloads]];
	_touchView = [[SPTouchView alloc] initWithFrame:CGRectMake(0,0,width,height) touchReceiver:[_itemView downloadsButton]];
	_itemView.translatesAutoresizingMaskIntoConstraints = NO;

	[_touchView addSubview:_itemView];

	self.customView = _touchView;

	[NSLayoutConstraint activateConstraints:@[
		 [NSLayoutConstraint constraintWithItem:self.customView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
		  toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:width],
		 [NSLayoutConstraint constraintWithItem:self.customView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
		  toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:height],
	]];

	[NSLayoutConstraint activateConstraints:@[
		 [NSLayoutConstraint constraintWithItem:_itemView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
		  toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:25],
		 [NSLayoutConstraint constraintWithItem:_itemView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
		  toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:25],
		 [NSLayoutConstraint constraintWithItem:_itemView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual
		  toItem:self.customView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_itemView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
		  toItem:self.customView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0],
	]];

	[_itemView setNeedsLayout];

	if(downloadManager)
	{
		[downloadManager addObserverDelegate:self];
	}
	else
	{
		[[NSNotificationCenter defaultCenter] addObserverForName:@"SPDownloadManagerDidInitNotification" object:nil queue:nil usingBlock:^(NSNotification* note)
		{
			[downloadManager addObserverDelegate:self];
		}];
	}

	return self;
}

- (void)totalProgressDidChangeForDownloadManager:(SPDownloadManager*)dm
{
	[_itemView updateProgress:[dm progressOfAllRunningDownloads] animated:YES];
}

- (void)runningDownloadsCountDidChangeForDownloadManager:(SPDownloadManager*)dm
{
	[_itemView updateProgress:[dm progressOfAllRunningDownloads] animated:NO];
	_itemView.progressViewHidden = [dm runningDownloadsCount] == 0;
}

- (void)setEnabled:(BOOL)arg1
{
	[super setEnabled:arg1];
	[_itemView downloadsButton].enabled = arg1;
}

@end
