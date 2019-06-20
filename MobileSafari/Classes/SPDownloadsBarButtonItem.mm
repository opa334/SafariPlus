// SPDownloadsBarButtonItem.mm
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

#import "SPDownloadsBarButtonItem.h"
#import "SPDownloadsBarButtonItemView.h"
#import "SPDownloadManager.h"
#import "SPTouchView.h"
#import "../Defines.h"
#import "../Util.h"

@implementation SPDownloadsBarButtonItem

- (instancetype)initWithTarget:(id)target action:(SEL)action
{
	self = [super init];

	self.target = target;
	self.action = action;
	self.style = UIBarButtonItemStylePlain;

	CGFloat width, height;

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0)
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

-(void)setEnabled:(BOOL)arg1
{
	[super setEnabled:arg1];
	[_itemView downloadsButton].enabled = arg1;
}

@end
