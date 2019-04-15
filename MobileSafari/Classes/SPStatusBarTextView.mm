// SPStatusBarTextView.mm
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

#import "SPStatusBarTextView.h"
#import "SPStatusBarNotification.h"

@implementation SPStatusBarTextView

- (instancetype)init
{
	self = [super init];

	_textLabel = [[UILabel alloc] init];
	_textLabel.font = [_textLabel.font fontWithSize:12];
	[self addSubview:_textLabel];

	return self;
}

- (void)layoutSubviews
{
	dispatch_async(dispatch_get_main_queue(),^
	{
		_textLabel.frame = CGRectMake(0,0,self.frame.size.width, self.frame.size.height);
	});
}

- (void)setCurrentNotification:(SPStatusBarNotification*)notification
{
	_textLabel.text = notification.text;
	_textLabel.textColor = notification.textColor;
	_textLabel.textAlignment = NSTextAlignmentCenter;
}

@end
