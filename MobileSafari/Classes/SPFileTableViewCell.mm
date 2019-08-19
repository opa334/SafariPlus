// SPFileTableViewCell.mm
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

#import "SPFileTableViewCell.h"

#import "../Util.h"
#import "SPLocalizationManager.h"
#import "SPFileManager.h"
#import "../../Shared/SPFile.h"
#import "SPCellIconLabelView.h"
#import "Extensions.h"

@implementation SPFileTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];

	[self setUpContent];
	[self setUpConstraints];

	return self;
}

- (void)setUpContent
{
	_iconLabelView = [[SPCellIconLabelView alloc] init];
	_iconLabelView.translatesAutoresizingMaskIntoConstraints = NO;

	[self.contentView addSubview:_iconLabelView];

	_sizeLabel = [[UILabel alloc] init];
	_sizeLabel.textColor = [UIColor lightGrayColor];
	_sizeLabel.font = [_sizeLabel.font fontWithSize:10];
	_sizeLabel.textAlignment = NSTextAlignmentCenter;
	_sizeLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
}

- (void)setUpConstraints
{
	[NSLayoutConstraint activateConstraints:@[
		//Horizontal
		 [NSLayoutConstraint constraintWithItem:_iconLabelView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
		  toItem:self.contentView attribute:NSLayoutAttributeLeadingMargin multiplier:1 constant:0],
		//[_iconLabelView.leadingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.leadingAnchor],

		 [NSLayoutConstraint constraintWithItem:_iconLabelView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
		  toItem:self.contentView attribute:NSLayoutAttributeTrailingMargin multiplier:1 constant:0],
		//[_iconLabelView.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor],

		//Vertical
		 [NSLayoutConstraint constraintWithItem:_iconLabelView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
		  toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1 constant:0],
		//[_iconLabelView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],

		 [NSLayoutConstraint constraintWithItem:_iconLabelView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
		  toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
		//[_iconLabelView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
	]];
}

- (void)applyFile:(SPFile*)file
{
	//Set label of cell to filename
	_iconLabelView.label.attributedText = file.cellTitle;

	if([file displaysAsRegularFile])	//File icon with filesize as accessoryView
	{
		_iconLabelView.iconView.image = [fileManager iconForFile:file];
		self.accessoryType = UITableViewCellAccessoryNone;
		self.accessoryView = _sizeLabel;
		_sizeLabel.text = [NSByteCountFormatter stringFromByteCount:file.size countStyle:NSByteCountFormatterCountStyleFile];
		_sizeLabel.frame = CGRectMake(0,0, _sizeLabel.intrinsicContentSize.width, 15);
	}
	else	//Directory icon with arrow as accessoryType
	{
		_iconLabelView.iconView.image = [fileManager genericDirectoryIcon];
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		self.accessoryView = nil;
	}

	if(file.isHidden)
	{
		_iconLabelView.alpha = 0.5;
	}
	else
	{
		_iconLabelView.alpha = 1;
	}

	//Enable separators between imageViews
	[self setSeparatorInset:UIEdgeInsetsZero];
}

@end
