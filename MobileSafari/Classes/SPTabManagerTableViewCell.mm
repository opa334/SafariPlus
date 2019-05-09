// SPTabManagerTableViewCell.mm
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

#import "SPTabManagerTableViewCell.h"

#import "../SafariPlus.h"
#import "Extensions.h"

@implementation SPTabManagerTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

	[self initContent];

	[self setUpConstraints];

	return self;
}

- (void)applyTabDocument:(TabDocument*)tabDocument
{
	_tabDocument = tabDocument;
	_tabDocument.tabManagerViewCell = self;

	[self updateContent];
}

- (void)prepareForReuse
{
	[super prepareForReuse];

	_tabDocument.tabManagerViewCell = nil;
}

- (void)initContent
{
	self.textLabel.text = nil;
	self.imageView.image = nil;

	_titleLabel = [UILabel autolayoutView];
	_titleLabel.textAlignment = NSTextAlignmentLeft;
	_titleLabel.font = [_titleLabel.font fontWithSize:14];

	_URLLabel = [UILabel autolayoutView];
	_URLLabel.textAlignment = NSTextAlignmentLeft;
	_URLLabel.font = [_URLLabel.font fontWithSize:11];

	_tabIconImageView = [UIImageView autolayoutView];

	[self.contentView addSubview:_titleLabel];
	[self.contentView addSubview:_URLLabel];
	[self.contentView addSubview:_tabIconImageView];
}

- (void)updateContent
{
	_titleLabel.text = [_tabDocument title];
	_URLLabel.text = [_tabDocument URL].absoluteString;

	if(_tabDocument.currentTabIcon)
	{
		_tabIconImageView.image = _tabDocument.currentTabIcon;
	}
}

- (void)setUpConstraints
{
	UIView* contentView = self.contentView;

	NSDictionary *metrics = @{@"TabIconSize" : @30, @"TitleHeight" : @17, @"URLHeight" : @13.33333333};

	NSDictionary *views = NSDictionaryOfVariableBindings(_tabIconImageView, _titleLabel, _URLLabel);

	BOOL useTabIcons = NO;

	if([NSUserDefaults respondsToSelector:@selector(_sf_safariDefaults)])
	{
		NSUserDefaults* safariDefaults = [NSUserDefaults _sf_safariDefaults];

		useTabIcons = [safariDefaults boolForKey:@"IconsInTabsEnabled"];
	}

	if(useTabIcons)
	{
		[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
					     @"H:|-[_tabIconImageView(TabIconSize)]" options:0 metrics:metrics views:views]];

		[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
					     @"H:[_tabIconImageView]-[_titleLabel]-|" options:0 metrics:metrics views:views]];

		[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
					     @"H:[_tabIconImageView]-[_URLLabel]-|" options:0 metrics:metrics views:views]];

		[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
					     @"V:|-[_tabIconImageView(TabIconSize)]-|" options:0 metrics:metrics views:views]];
	}
	else
	{
		[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
					     @"H:|-[_titleLabel]-|" options:0 metrics:metrics views:views]];

		[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
					     @"H:|-[_URLLabel]-|" options:0 metrics:metrics views:views]];
	}

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"V:|-5-[_titleLabel]-2.5-[_URLLabel]-5-|" options:0 metrics:metrics views:views]];
}

@end
