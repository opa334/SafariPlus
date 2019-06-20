// SPDownloadsBarButtonItemView.h
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

@class SPDownloadsBarButtonItem;

@interface SPDownloadsBarButtonItemView : UIView
{
	UIProgressView* _progressView;
	UIButton* _downloadsButton;
	SPDownloadsBarButtonItem* _item;

	NSArray<NSLayoutConstraint*>* _progressViewHiddenConstraints;
	NSArray<NSLayoutConstraint*>* _progressViewShownConstraints;
}

@property (nonatomic) BOOL progressViewHidden;

- (instancetype)initWithItem:(SPDownloadsBarButtonItem*)item progressViewHidden:(BOOL)progressViewHidden initialProgress:(float)initialProgress;
- (void)setUpConstraints;
- (void)updateProgress:(float)progress animated:(BOOL)animated;
- (UIButton*)downloadsButton;
@end
