// SPTouchView.mm
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
