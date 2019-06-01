// SPPRootHeaderView.mm
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

#import "SPPRootHeaderView.h"

#import <Preferences/PSSpecifier.h>

@implementation SPPRootHeaderView

- (instancetype)initWithSpecifier:(PSSpecifier*)specifier
{
	self = [super init];

	UIImage* headerImage = [UIImage imageNamed:@"PrefHeader" inBundle:[NSBundle bundleForClass:[self class]] compatibleWithTraitCollection:nil];
	_aspectRatio = headerImage.size.width / headerImage.size.height;
	_headerImageView = [[UIImageView alloc] initWithImage:headerImage];
	[self addSubview:_headerImageView];

	return self;
}

- (void)setFrame:(CGRect)frame
{
	[super setFrame:CGRectMake(frame.origin.x,0,frame.size.width,frame.size.height)];

	CGFloat xOffset = (frame.size.width - _currentWidth) / 2;

	_headerImageView.frame = CGRectMake(xOffset,0,_currentWidth,frame.size.height+35);
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width
{
	_currentWidth = width;
	CGFloat height = width / _aspectRatio;
	return height - 35;
}

@end
