// SPTabManagerTableViewCell.h
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

@class TabDocument;

@interface UITableViewLabel : UILabel
@property (nonatomic,assign) UITableViewCell* tableCell;
@end

@interface SPTabManagerTableViewCell : UITableViewCell
{
	__weak TabDocument* _tabDocument;

	UIImageView* _tabIconImageView;
	UIView* _titleLockView;
	UILabel* _URLLabel;

	UIImageView* _lockIconView;
	UILabel* _titleLabel;

	NSArray<NSLayoutConstraint*>* _tabIconConstraints;
	NSArray<NSLayoutConstraint*>* _noTabIconConstraints;

	NSArray<NSLayoutConstraint*>* _URLLabelConstraints;
	NSArray<NSLayoutConstraint*>* _noURLLabelConstraints;

	NSArray<NSLayoutConstraint*>* _lockViewConstraints;
	NSArray<NSLayoutConstraint*>* _noLockViewConstraints;
}
@property (nonatomic) BOOL showsTabIcon;
@property (nonatomic) BOOL showsURLLabel;
@property (nonatomic) BOOL showsLockIcon;
- (void)updateContent;
- (void)updateContentAnimated:(BOOL)animated;
- (void)setShowsLockIcon:(BOOL)showsLockIcon animated:(BOOL)animated;
- (void)applyTabDocument:(TabDocument*)tabDocument;
- (void)initContent;
- (void)setUpConstraints;
@end
