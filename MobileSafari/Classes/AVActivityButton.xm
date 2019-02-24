// AVActivityButton.mm
// (c) 2019 opa334

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

#import "AVActivityButton.h"
#import "../Defines.h"

%subclass AVActivityButton: AVButton

%property (nonatomic,retain) UIActivityIndicatorView *activityIndicatorView;

+ (instancetype)buttonWithType:(UIButtonType)buttonType
{
	AVActivityButton* button = %orig;

	[button setUpSpinner];

	return button;
}

%new
- (void)setUpSpinner
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

%new
- (BOOL)spinning
{
	return [objc_getAssociatedObject(self, "spinning") boolValue];
}

%new
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

%end
