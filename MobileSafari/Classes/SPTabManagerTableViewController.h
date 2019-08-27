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

@class TabController, TabDocument;

@interface SPTabManagerTableViewController : UITableViewController <UISearchResultsUpdating>
{
	TabController* _tabController;
	NSArray<TabDocument*>* _allTabs;
	NSArray<TabDocument*>* _filteredTabs;
	NSArray<TabDocument*>* _selectedTabs;
	NSArray<TabDocument*>* _displayedTabs;
	TabDocument* _initialVisibleTab;
	BOOL _isFiltering;
	BOOL _shouldUpdateOnSelectionChange;
	UISearchController* _searchController;
	UIBarButtonItem* _addTabsBarButtonItem;
	UIBarButtonItem* _exportBarButtonItem;
	UIBarButtonItem* _addToBookmarksBarButtonItem;
	UIBarButtonItem* _closeTabsBarButtonItem;
	UIBarButtonItem* _lockUnlockBarButtonItem;
}
@property (nonatomic) BOOL lockBarButtonIsUnlockButton;
- (instancetype)initWithTabController:(TabController*)tabController;
- (void)setUpTopBar;
- (void)setUpBottomToolbar;
- (void)updateBottomToolbarButtonAvailability;
- (NSArray<TabDocument*>*)activeTabs;
- (UIViewController*)presentationController;
- (TabDocument*)tabDocumentForIndexPath:(NSIndexPath*)indexPath;
- (NSIndexPath*)indexPathForTabDocument:(TabDocument*)tabDocument;
- (BOOL)loadTabs;
- (void)reloadAnimated:(BOOL)animated;
- (void)updateSelectAllButton;
- (void)selectAll;
- (void)deselectAll;
- (void)doneButtonPressed;
- (void)selectAllButtonPressed;
- (void)addTabsButtonPressed;
- (void)openAllURLsInsideString:(NSString*)string;
- (void)addToBookmarksButtonPressed:(UIBarButtonItem*)sender;
- (void)closeTabsButtonPressed;
- (void)exportButtonPressed:(id)sender;
- (void)updateSelectedTabs;
@end
