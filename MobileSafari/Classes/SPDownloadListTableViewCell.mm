// SPDownloadListTableViewCell.mm
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

#import "SPDownloadListTableViewCell.h"
#import "Extensions.h"

#import "SPDownload.h"
#import "../Util.h"

@implementation SPDownloadListTableViewCell

- (void)setUpContent
{
	[super setUpContent];

	_targetLabel = [[UILabel alloc] init];
	_targetLabel.translatesAutoresizingMaskIntoConstraints = NO;
	_targetLabel.font = [_targetLabel.font fontWithSize:10];
	_targetLabel.textAlignment = NSTextAlignmentCenter;

	[self.contentView addSubview:_targetLabel];
}

- (void)applyDownload:(SPDownload*)download
{
	[super applyDownload:download];

	_targetLabel.text = self.download.targetURL.path;
}

- (void)setUpConstraints
{
	[super setUpConstraints];

	self.bottomConstraint.active = NO;

	[NSLayoutConstraint activateConstraints:@[
		//Horizontal
		 [NSLayoutConstraint constraintWithItem:_targetLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
		  toItem:self.contentView attribute:NSLayoutAttributeLeadingMargin multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_targetLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
		  toItem:self.buttonsView attribute:NSLayoutAttributeTrailing multiplier:1 constant:-7.5],
		//Vertical
		 [NSLayoutConstraint constraintWithItem:_targetLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual
		  toItem:self.downloadProgressView attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
		 [NSLayoutConstraint constraintWithItem:_targetLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
		  toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:18],
		 [NSLayoutConstraint constraintWithItem:_targetLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual
		  toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
	]];
}

@end
