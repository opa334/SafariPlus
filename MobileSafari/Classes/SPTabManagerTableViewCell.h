// Copyright (c) 2017-2019 Lars Fröder

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
