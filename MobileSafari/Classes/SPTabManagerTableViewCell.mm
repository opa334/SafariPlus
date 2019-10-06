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
	_titleLabel.text = [tabDocument title];
	_URLLabel.text = [tabDocument URL].absoluteString;
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

	[self.contentView addSubview:_titleLabel];
	[self.contentView addSubview:_URLLabel];
}

- (void)setUpConstraints
{
	UIView* contentView = self.contentView;

	NSDictionary *metrics = @{@"TitleHeight" : @17, @"URLHeight" : @13.33333333};

	NSDictionary *views = NSDictionaryOfVariableBindings(_titleLabel, _URLLabel);

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"H:|-[_titleLabel]-|" options:0 metrics:metrics views:views]];

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"H:|-[_URLLabel]-|" options:0 metrics:metrics views:views]];

	[contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
				     @"V:|-5-[_titleLabel]-2.5-[_URLLabel]-5-|" options:0 metrics:metrics views:views]];
}

@end
