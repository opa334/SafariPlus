// SPTabManagerTableViewController.mm
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

#import "SPTabManagerTableViewController.h"

#import "../SafariPlus.h"
#import "../Util.h"
#import "SPLocalizationManager.h"
#import "SPPreferenceManager.h"
#import "SPTabManagerTableViewCell.h"
#import "Extensions.h"
#import "../Defines.h"

@implementation SPTabManagerTableViewController

- (instancetype)initWithTabController:(TabController*)tabController
{
	//NSLog(@"initWithTabController");
	self = [super init];

	_tabController = tabController;
	_shouldUpdateOnSelectionChange = YES;

	[self setUpTopBar];
	[self setUpBottomToolbar];

	self.tableView.allowsMultipleSelectionDuringEditing = YES;
	self.tableView.editing = YES;

	return self;
}

- (void)setUpTopBar
{
	//'Select All' / 'Deselect All' button in top right
	//'Tab Manager' in middle
	//'Done' button in top right
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[localizationManager localizedSPStringForKey:@"SELECT_ALL"] style:UIBarButtonItemStylePlain target:self action:@selector(selectAllButtonPressed)];

	self.title = [localizationManager localizedSPStringForKey:@"TAB_MANAGER"];

	_searchController = [[UISearchController alloc] initWithSearchResultsController:nil];

	_searchController.dimsBackgroundDuringPresentation = NO;
	_searchController.hidesNavigationBarDuringPresentation = NO;
	_searchController.searchResultsUpdater = self;

	if([self.navigationItem respondsToSelector:@selector(setSearchController:)])
	{
		self.navigationItem.searchController = _searchController;
		self.navigationItem.hidesSearchBarWhenScrolling = YES;
	}
	else
	{
		_searchController.searchBar.frame = CGRectMake(0,0,0,44);
		self.tableView.tableHeaderView = _searchController.searchBar;
	}
}

- (void)setUpBottomToolbar
{
	//NSLog(@"setUpBottomToolbar");

	//Option to batch-close tabs
	//Option to export tabs (Text Form)
	//Option to save tabs to bookmarks
	//MAYBE: Option to batch open new tabs
	UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

	UIBarButtonItem* addTabsBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addTabsButtonPressed)];
	UIBarButtonItem* exportBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(exportButtonPressed:)];
	//UIBarButtonItem* addToBookmarksBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self action:@selector(addToBookmarksButtonPressed)];
	UIBarButtonItem* closeTabsBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(closeTabsButtonPressed)];

	self.toolbarItems = @[addTabsBarButtonItem,flexibleSpace,exportBarButtonItem,flexibleSpace /*,addToBookmarksBarButtonItem,flexibleSpace*/,closeTabsBarButtonItem];
}

- (void)viewDidLoad
{
	//NSLog(@"viewDidLoad");
	_selectedTabs = [NSArray new];
	[self loadTabs];
}

- (void)viewWillAppear:(BOOL)animated
{
	//NSLog(@"viewWillAppear");
	if(!_isFiltering)
	{
		[self.navigationController setToolbarHidden:NO animated:NO];
	}
}

- (NSArray<TabDocument*>*)activeTabs
{
	if(_isFiltering)
	{
		return _filteredTabs;
	}
	else
	{
		return _allTabs;
	}
}

- (UIViewController*)presentationController
{
	if(_searchController.isActive)
	{
		return _searchController;
	}
	else
	{
		return self.navigationController;
	}
}

- (TabDocument*)tabDocumentForIndexPath:(NSIndexPath*)indexPath
{
	NSArray<TabDocument*>* activeTabs = [self activeTabs];

	return activeTabs[indexPath.row];
}

- (void)loadTabs
{
	_allTabs = [_tabController.currentTabDocuments copy];

	if(_isFiltering)
	{
		NSString* searchString = [_searchController.searchBar.text lowercaseString];

		_filteredTabs = [_allTabs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL (id evaluatedObject, NSDictionary<NSString *,id>* bindings)
		{
			TabDocument* document = evaluatedObject;

			BOOL URLMatch = NO;
			BOOL titleMatch = NO;

			NSString* URLString = [[document URL].absoluteString lowercaseString];
			if(URLString)
			{
				URLMatch = [URLString containsString:searchString];
			}

			NSString* title = [[document title] lowercaseString];
			if(title)
			{
				titleMatch = [title containsString:searchString];
			}

			return (URLMatch || titleMatch);
		}]];
	}
	else
	{
		_filteredTabs = nil;
	}

	NSMutableArray* selectedTabsM = [_selectedTabs mutableCopy];

	for(TabDocument* selectedTabDocument in _selectedTabs)
	{
		if(![_allTabs containsObject:selectedTabDocument])
		{
			[selectedTabsM removeObject:selectedTabDocument];
		}
	}

	_selectedTabs = [selectedTabsM copy];
}

- (void)reloadAnimated:(BOOL)animated
{
	[self loadTabs];

	if(animated)
	{
		NSRange range = NSMakeRange(0, [self numberOfSectionsInTableView:self.tableView]);
		NSIndexSet* sections = [NSIndexSet indexSetWithIndexesInRange:range];
		[self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
	}
	else
	{
		[self.tableView reloadData];
	}

	for(TabDocument* selectedTab in _selectedTabs)
	{
		NSArray<TabDocument*>* documents = [self activeTabs];

		if([documents containsObject:selectedTab])
		{
			NSInteger index = [documents indexOfObject:selectedTab];
			NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
			[self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		}
	}
}

- (void)updateSelectAllButton
{
	//NSLog(@"updateSelectAllButton");
	NSArray<NSIndexPath*>* selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
	NSInteger rowNumber = [self tableView:self.tableView numberOfRowsInSection:0];

	if(selectedIndexPaths.count == rowNumber)
	{
		self.navigationItem.leftBarButtonItem.title = [localizationManager localizedSPStringForKey:@"DESELECT_ALL"];
	}
	else
	{
		self.navigationItem.leftBarButtonItem.title = [localizationManager localizedSPStringForKey:@"SELECT_ALL"];
	}
}

- (void)selectAll
{
	//NSLog(@"selectAll");

	_shouldUpdateOnSelectionChange = NO;

	NSArray<TabDocument*>* documentsToSelect = [self activeTabs];

	for(TabDocument* documentToSelect in documentsToSelect)
	{
		NSInteger index = [documentsToSelect indexOfObject:documentToSelect];
		NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
		[self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
	}

	_shouldUpdateOnSelectionChange = YES;

	[self updateSelectedTabs];
	[self updateSelectAllButton];
}

- (void)deselectAll
{
	//NSLog(@"deselectAll");

	_shouldUpdateOnSelectionChange = NO;

	NSArray<TabDocument*>* documentsToDeselect = [self activeTabs];

	for(TabDocument* documentToDeselect in documentsToDeselect)
	{
		NSInteger index = [documentsToDeselect indexOfObject:documentToDeselect];
		NSIndexPath* indexPath = [NSIndexPath indexPathForRow:index inSection:0];
		[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
	}

	_shouldUpdateOnSelectionChange = YES;

	[self updateSelectedTabs];
	[self updateSelectAllButton];
}

- (void)doneButtonPressed
{
	//NSLog(@"doneButtonPressed");
	[self.navigationController dismissViewControllerAnimated:YES completion:^
	{
		[_tabController tabManagerDidClose];
	}];
}

- (void)selectAllButtonPressed
{
	//NSLog(@"selectAllButtonPressed");

	NSArray<NSIndexPath*>* selectedIndexPaths = [self.tableView indexPathsForSelectedRows];
	NSInteger rowNumber = [self tableView:self.tableView numberOfRowsInSection:0];

	if(selectedIndexPaths.count == rowNumber)
	{
		[self deselectAll];
	}
	else
	{
		[self selectAll];
	}
}

- (void)addTabsButtonPressed
{
	UIAlertController* addTabsController = [UIAlertController alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"ADD_TABS_ALERT"]
						message:[localizationManager localizedSPStringForKey:@"ADD_TABS_ALERT_MESSAGE"] preferredStyle:UIAlertControllerStyleAlert];

	UITextView* tabsTextView = [[UITextView alloc] initWithFrame:CGRectZero];

	UIAlertAction* openAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"OPEN"] style:UIAlertActionStyleDefault
				     handler:^(UIAlertAction* action)
	{
		[self openAllURLsInsideString:tabsTextView.text];
	}];

	[addTabsController addAction:openAction];

	UIAlertAction* useClipboardAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"USE_CLIPBOARD"] style:UIAlertActionStyleDefault
					     handler:^(UIAlertAction* action)
	{
		[self openAllURLsInsideString:[UIPasteboard generalPasteboard].string];
	}];

	[addTabsController addAction:useClipboardAction];

	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CANCEL"] style:UIAlertActionStyleCancel handler:nil];

	[addTabsController addAction:cancelAction];

	[addTabsController setTextView:tabsTextView];

	[[self presentationController] presentViewController:addTabsController animated:YES completion:nil];
}

- (void)openAllURLsInsideString:(NSString*)string
{
	NSDataDetector* linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];

	NSArray<NSTextCheckingResult*>* matches = [linkDetector matchesInString:string options:0 range:NSMakeRange(0,string.length)];

	if(matches.count <= 0)
	{
		return;
	}

	BrowserController* browserController = [_tabController valueForKey:@"_browserController"];

	for(NSTextCheckingResult* match in matches)
	{
		NSString* matchString = [string substringWithRange:match.range];

		if(![matchString hasPrefix:@"http"])
		{
			matchString = [@"http://" stringByAppendingString:matchString];
		}

		NSURL* matchURL = [NSURL URLWithString:matchString];

		TabDocument* document = [[NSClassFromString(@"TabDocument") alloc] initWithTitle:nil URL:matchURL UUID:[NSUUID UUID] privateBrowsingEnabled:privateBrowsingEnabled(browserController) hibernated:YES bookmark:nil browserController:browserController];

		if([_tabController respondsToSelector:@selector(_insertTabDocument:afterTabDocument:inBackground:animated:)])
		{
			[_tabController _insertTabDocument:document afterTabDocument:_allTabs.lastObject inBackground:YES animated:NO];
		}
		else
		{
			[_tabController insertTabDocument:document afterTabDocument:_allTabs.lastObject inBackground:YES animated:NO];
		}

		[document unhibernate];

		//[self reloadAnimated:YES];
	}
}

- (void)addToBookmarksButtonPressed	//TODO: Implement
{

}

- (void)closeTabsButtonPressed
{
	if(_selectedTabs.count <= 0)
	{
		return;
	}

	NSString* message;

	if(_selectedTabs.count == 1)
	{
		message = [localizationManager localizedSPStringForKey:@"CLOSE_TAB_WARNING_MESSAGE"];
	}
	else
	{
		message = [NSString stringWithFormat:[localizationManager localizedSPStringForKey:@"CLOSE_TABS_WARNING_MESSAGE"], _selectedTabs.count];
	}

	UIAlertController* confirmationController = [UIAlertController alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"WARNING"]
						     message:message
						     preferredStyle:UIAlertControllerStyleAlert];

	UIAlertAction* yesAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"YES"]
				    style:UIAlertActionStyleDestructive
				    handler:^(UIAlertAction* action)
	{
		if([_tabController respondsToSelector:@selector(closeTabsDocuments:)])
		{
			[_tabController closeTabsDocuments:_selectedTabs];
		}
		else
		{
			for(TabDocument* tabDocument in _selectedTabs)
			{
				[_tabController closeTabDocument:tabDocument animated:NO];
			}
		}
	}];

	UIAlertAction* noAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"NO"]
				   style:UIAlertActionStyleDefault
				   handler:nil];

	[confirmationController addAction:noAction];
	[confirmationController addAction:yesAction];

	[[self presentationController] presentViewController:confirmationController animated:YES completion:nil];
}

- (void)exportButtonPressed:(id)sender
{
	if(_selectedTabs.count <= 0)
	{
		return;
	}

	void (^presentActivityController)(id) = ^void (id exportString)
	{
		UIActivityViewController* activityController = [[UIActivityViewController alloc] initWithActivityItems:@[exportString] applicationActivities:nil];
		activityController.popoverPresentationController.sourceView = self.navigationController.view;

		[[self presentationController] presentViewController:activityController animated:YES completion:nil];
	};

	NSString* titleForExample = [_selectedTabs.firstObject title];
	NSString* URLStringForExample = [_selectedTabs.firstObject URL].absoluteString;
	if(!titleForExample || !URLStringForExample)
	{
		//Fall back to apple.com
		titleForExample = @"Apple";
		URLStringForExample = @"https://apple.com";
	}

	NSString* titleAndURLExample = [NSString stringWithFormat:@"%@ (%@)", titleForExample, URLStringForExample];
	NSString* URLExample = URLStringForExample;
	NSAttributedString* hyperlinkExample = [[NSAttributedString alloc] initWithString:titleForExample attributes:@{NSLinkAttributeName : URLStringForExample}];

	UIAlertController* formatAlertController = [UIAlertController alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"CHOOSE_EXPORT_FORMAT"]
						    message:[localizationManager localizedSPStringForKey:@"CHOOSE_EXPORT_FORMAT_MESSAGE"]
						    preferredStyle:UIAlertControllerStyleActionSheet];

	UIAlertAction* titleAndURLAction = [UIAlertAction actionWithTitle:titleAndURLExample
					    style:UIAlertActionStyleDefault
					    handler:^(UIAlertAction* action)
	{
		NSMutableString* tabsString = [NSMutableString new];

		for(TabDocument* tab in _selectedTabs)
		{
			if([tab URL] && [tab title])
			{
				[tabsString appendString:[NSString stringWithFormat:@"%@ (%@)\n\n", [tab title], [tab URL]]];
			}
		}

		presentActivityController([tabsString copy]);
	}];

	UIAlertAction* URLAction = [UIAlertAction actionWithTitle:URLExample
				    style:UIAlertActionStyleDefault
				    handler:^(UIAlertAction* action)
	{
		NSMutableString* tabsString = [NSMutableString new];

		for(TabDocument* tab in _selectedTabs)
		{
			if([tab URL] && [tab title])
			{
				[tabsString appendString:[NSString stringWithFormat:@"%@\n\n", [tab URL]]];
			}
		}

		presentActivityController([tabsString copy]);
	}];

	UIAlertAction* hyperlinkAction = [UIAlertAction actionWithTitle:@""
					  style:UIAlertActionStyleDefault
					  handler:^(UIAlertAction* action)
	{
		NSMutableAttributedString* tabsString = [NSMutableAttributedString new];

		for(TabDocument* tab in _selectedTabs)
		{
			if([tab URL] && [tab title])
			{
				NSAttributedString* attrStringForTab = [[NSAttributedString alloc] initWithString:[tab title] attributes:@{NSLinkAttributeName : [tab URL].absoluteString}];
				[tabsString appendAttributedString:attrStringForTab];
				[tabsString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n" attributes:nil]];
			}
		}

		presentActivityController([tabsString copy]);
	}];

	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CANCEL"]
				       style:UIAlertActionStyleCancel
				       handler:nil];

	[formatAlertController addAction:titleAndURLAction];
	[formatAlertController addAction:URLAction];
	[formatAlertController addAction:hyperlinkAction];
	[formatAlertController addAction:cancelAction];

	UIPopoverPresentationController* popPresenter = [formatAlertController popoverPresentationController];
	popPresenter.sourceView = self.navigationController.view;
	popPresenter.sourceRect = ((UIBarButtonItem*)sender).view.bounds;

	[[self presentationController] presentViewController:formatAlertController animated:YES completion:nil];

	NSString* labelKey;

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0)
	{
		labelKey = @"_label";
	}
	else
	{
		labelKey = @"label";
	}

	UILabel* hyperlinkLabel = [hyperlinkAction._representer valueForKey:labelKey];
	hyperlinkLabel.attributedText = hyperlinkExample;
}

- (void)updateSelectedTabs
{
	//NSLog(@"updateSelectedTabs");

	NSArray<NSIndexPath*>* selectedIndexPaths = [self.tableView indexPathsForSelectedRows];

	NSInteger rowNumber = [self tableView:self.tableView numberOfRowsInSection:0];

	NSMutableArray* newSelectedM = [_selectedTabs mutableCopy];

	for(NSInteger i = 0; i < rowNumber; i++)
	{
		NSIndexPath* currentIndexPath = [NSIndexPath indexPathForRow:i inSection:0];
		TabDocument* tabDocumentForIndexPath;
		tabDocumentForIndexPath = [self tabDocumentForIndexPath:currentIndexPath];

		if([selectedIndexPaths containsObject:currentIndexPath])
		{
			if(![newSelectedM containsObject:tabDocumentForIndexPath])
			{
				[newSelectedM addObject:tabDocumentForIndexPath];
			}
		}
		else
		{
			if([newSelectedM containsObject:tabDocumentForIndexPath])
			{
				[newSelectedM removeObject:tabDocumentForIndexPath];
			}
		}
	}

	[newSelectedM sortUsingComparator:^NSComparisonResult (TabDocument* tab1, TabDocument* tab2)
	{
		return [@([_allTabs indexOfObject:tab1]) compare:@([_allTabs indexOfObject:tab2])];
	}];

	_selectedTabs = [newSelectedM copy];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	//NSLog(@"numberOfSectionsInTableView");
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	//NSLog(@"numberOfRowsInSection");

	return [[self activeTabs] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	////NSLog(@"cellForRowAtIndexPath");

	TabDocument* tabDocument = [self tabDocumentForIndexPath:indexPath];

	SPTabManagerTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"SPTabManagerTableViewCell"];

	if(!cell)
	{
		cell = [[SPTabManagerTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SPTabManagerTableViewCell"];
	}

	[cell applyTabDocument:tabDocument];

	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	//NSLog(@"didSelectRowAtIndexPath");

	if(_shouldUpdateOnSelectionChange)
	{
		[self updateSelectedTabs];
		[self updateSelectAllButton];
	}
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	//NSLog(@"didDeselectRowAtIndexPath");

	if(_shouldUpdateOnSelectionChange)
	{
		[self updateSelectedTabs];
		[self updateSelectAllButton];
	}
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
	//NSLog(@"updateSearchResultsForSearchController");

	_isFiltering = searchController.searchBar.text.length > 0;

	//[self.navigationController setToolbarHidden:_isFiltering animated:YES]; TODO: decide

	[self reloadAnimated:NO];

	[self updateSelectAllButton];
}

@end
