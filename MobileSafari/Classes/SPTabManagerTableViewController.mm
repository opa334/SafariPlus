// Copyright (c) 2017-2020 Lars Fröder

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

#import "SPTabManagerTableViewController.h"

#import "../SafariPlus.h"
#import "../Util.h"
#import "SPLocalizationManager.h"
#import "SPPreferenceManager.h"
#import "SPTabManagerTableViewCell.h"
#import "SPTabManagerBookmarkPicker.h"
#import "Extensions.h"
#import "../Defines.h"

@implementation SPTabManagerTableViewController

- (instancetype)initWithTabController:(TabController*)tabController
{
	self = [super init];

	_tabController = tabController;
	_shouldUpdateOnSelectionChange = YES;

	self.tableView.allowsMultipleSelectionDuringEditing = YES;
	self.tableView.editing = YES;

	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	[self setUpTopBar];
	[self setUpBottomToolbar];

	[self.tableView registerClass:[SPTabManagerTableViewCell class] forCellReuseIdentifier:@"SPTabManagerTableViewCell"];

	_selectedTabs = [NSArray new];
	[self loadTabs];

	if(preferenceManager.tabManagerScrollPositionFromTabSwitcherEnabled)
	{
		if(_tabController.tiltedTabView)
		{
			CGPoint contentOffset = ((UIScrollView*)[_tabController.tiltedTabView valueForKey:@"_scrollView"]).contentOffset;
			CGRect bounds = _tabController.tiltedTabView.bounds;

			TiltedTabItem* item = [_tabController.tiltedTabView _tiltedTabItemForLocation:CGPointMake(contentOffset.x + bounds.size.width / 2, contentOffset.y + bounds.size.height / 2)];
			_initialVisibleTab = tabDocumentForItem(_tabController, item);
		}
		else if(_tabController.tabOverview)
		{
			TabOverviewItem* item = [_tabController.tabOverview valueForKey:@"_visiblyCenteredItem"];
			_initialVisibleTab = tabDocumentForItem(_tabController, item);
		}
	}
}

- (void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];

	if(_initialVisibleTab && preferenceManager.tabManagerScrollPositionFromTabSwitcherEnabled)
	{
		NSIndexPath* indexPath = [self indexPathForTabDocument:_initialVisibleTab];
		if(indexPath)
		{
			[self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
		}
		_initialVisibleTab = nil;
	}
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
	UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

	//Option to batch open new tabs
	_addTabsBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addTabsButtonPressed)];

	//Option to export tabs (Text Form)
	_exportBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(exportButtonPressed:)];

	//Option to save tabs to bookmarks
	_addToBookmarksBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self action:@selector(addToBookmarksButtonPressed:)];

	//Option to batch-close tabs
	_closeTabsBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(closeTabsButtonPressed)];

	if(preferenceManager.lockedTabsEnabled)
	{
		UIImage* lockImage;
		if([UIImage respondsToSelector:@selector(systemImageNamed:)])
		{
			_lockUnlockBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"lock"] style:UIBarButtonItemStylePlain target:self action:@selector(lockUnlockButtonPressed)];
		}
		else
		{
			_lockUnlockBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"LockButton_Slim_Closed" inBundle:SPBundle compatibleWithTraitCollection:nil] landscapeImagePhone:[UIImage imageNamed:@"LockButton_Slim_Closed_Landscape" inBundle:SPBundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:self action:@selector(lockUnlockButtonPressed)];
		}
		self.toolbarItems = @[_addTabsBarButtonItem,flexibleSpace,_lockUnlockBarButtonItem,flexibleSpace,_exportBarButtonItem,flexibleSpace,_addToBookmarksBarButtonItem,flexibleSpace,_closeTabsBarButtonItem];
	}
	else
	{
		self.toolbarItems = @[_addTabsBarButtonItem,flexibleSpace,_exportBarButtonItem,flexibleSpace,_addToBookmarksBarButtonItem,flexibleSpace,_closeTabsBarButtonItem];
	}

	[self updateBottomToolbarButtonAvailability];
}

- (void)updateBottomToolbarButtonAvailability
{
	BOOL tabsSelected = (_selectedTabs.count > 0);
	BOOL nonLockedTabsSelected = ([self nonLockedSelectedTabs].count > 0);

	_exportBarButtonItem.enabled = tabsSelected;
	_addToBookmarksBarButtonItem.enabled = tabsSelected;
	_closeTabsBarButtonItem.enabled = nonLockedTabsSelected;
	if(_lockUnlockBarButtonItem)
	{
		_lockUnlockBarButtonItem.enabled = tabsSelected;

		BOOL allSelectedTabsLocked = tabsSelected;

		for(TabDocument* tabDocument in _selectedTabs)
		{
			if(!tabDocument.locked)
			{
				allSelectedTabsLocked = NO;
				break;
			}
		}

		self.lockBarButtonIsUnlockButton = allSelectedTabsLocked;
	}
}

- (void)setLockBarButtonIsUnlockButton:(BOOL)lockBarButtonIsUnlockButton
{
	if(_lockBarButtonIsUnlockButton != lockBarButtonIsUnlockButton)
	{
		_lockBarButtonIsUnlockButton = lockBarButtonIsUnlockButton;

		if(_lockBarButtonIsUnlockButton)
		{
			if([UIImage respondsToSelector:@selector(systemImageNamed:)])
			{
				_lockUnlockBarButtonItem.image = [UIImage systemImageNamed:@"lock.open"];
			}
			else
			{
				_lockUnlockBarButtonItem.image = [UIImage imageNamed:@"LockButton_Slim_Open" inBundle:SPBundle compatibleWithTraitCollection:nil];
				[_lockUnlockBarButtonItem setLandscapeImagePhone:[UIImage imageNamed:@"LockButton_Slim_Open_Landscape" inBundle:SPBundle compatibleWithTraitCollection:nil]];
			}
		}
		else
		{
			if([UIImage respondsToSelector:@selector(systemImageNamed:)])
			{
				_lockUnlockBarButtonItem.image = [UIImage systemImageNamed:@"lock"];
			}
			else
			{
				_lockUnlockBarButtonItem.image = [UIImage imageNamed:@"LockButton_Slim_Closed" inBundle:SPBundle compatibleWithTraitCollection:nil];
				[_lockUnlockBarButtonItem setLandscapeImagePhone:[UIImage imageNamed:@"LockButton_Slim_Closed_Landscape" inBundle:SPBundle compatibleWithTraitCollection:nil]];
			}
		}
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

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

- (NSArray<TabDocument*>*)nonLockedSelectedTabs
{
	if(preferenceManager.lockedTabsEnabled)
	{
		return [_selectedTabs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL (id evaluatedObject, NSDictionary<NSString *,id>* bindings)
		{
			TabDocument* document = evaluatedObject;

			return !document.locked;
		}]];
	}
	else
	{
		return _selectedTabs;
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

- (NSIndexPath*)indexPathForTabDocument:(TabDocument*)tabDocument
{
	NSArray<TabDocument*>* activeTabs = [self activeTabs];

	if(![activeTabs containsObject:tabDocument])
	{
		return nil;
	}

	return [NSIndexPath indexPathForRow:[activeTabs indexOfObject:tabDocument] inSection:0];
}

- (BOOL)loadTabs
{
	BOOL firstLoad = (_allTabs == nil);

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

	if(firstLoad)
	{
		_displayedTabs = [self activeTabs];
	}

	return ![[self activeTabs] isEqualToArray:_displayedTabs];
}

- (void)reloadAnimated:(BOOL)animated
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
	{
		@synchronized(self)
		{
			BOOL needsReload = [self loadTabs];

			if(needsReload)
			{
				if(animated)
				{
					[self applyChangesToTable];
				}
				else
				{
					dispatch_sync(dispatch_get_main_queue(), ^
					{
						[self.tableView reloadData];
						[self applyChangesAfterReload];
					});
				}
			}
		}
	});
}

- (void)applyChangesAfterReload
{
	_displayedTabs = [[self activeTabs] copy];

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

	[self updateBottomToolbarButtonAvailability];
}

- (void)applyChangesToTable
{
	if(!_displayedTabs)
	{
		return;
	}

	NSMutableSet<TabDocument*>* oldTabs = [NSMutableSet setWithArray:_displayedTabs];
	NSMutableSet<TabDocument*>* currentTabs = [NSMutableSet setWithArray:[self activeTabs]];

	NSMutableSet<TabDocument*>* newTabs = [currentTabs mutableCopy];
	NSMutableSet<TabDocument*>* closedTabs = [oldTabs mutableCopy];

	[newTabs minusSet:oldTabs];
	[closedTabs minusSet:currentTabs];

	NSMutableArray<NSIndexPath*>* addIndexPaths = [NSMutableArray new];
	NSMutableArray<NSIndexPath*>* deleteIndexPaths = [NSMutableArray new];

	for(TabDocument* tabDocument in closedTabs)
	{
		[deleteIndexPaths addObject:[NSIndexPath indexPathForRow:[_displayedTabs indexOfObject:tabDocument] inSection:0]];
	}

	for(TabDocument* tabDocument in newTabs)
	{
		[addIndexPaths addObject:[NSIndexPath indexPathForRow:[[self activeTabs] indexOfObject:tabDocument] inSection:0]];
	}

	dispatch_sync(dispatch_get_main_queue(), ^
	{
		if(addIndexPaths.count > 0 || deleteIndexPaths.count > 0)
		{
			[self.tableView beginUpdates];
			[self.tableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];
			[self.tableView insertRowsAtIndexPaths:addIndexPaths withRowAnimation:UITableViewRowAnimationFade];
			[self.tableView endUpdates];
		}

		[self applyChangesAfterReload];
	});
}

- (void)updateSelectAllButton
{
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
}

- (void)deselectAll
{
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
}

- (void)doneButtonPressed
{
	[self.navigationController dismissViewControllerAnimated:YES completion:^
	{
		[_tabController tabManagerDidClose];
	}];
}

- (void)selectAllButtonPressed
{
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
	}
}

- (void)addToBookmarksButtonPressed:(UIBarButtonItem*)sender
{
	SPTabManagerBookmarkPicker* bookmarkPicker = [[NSClassFromString(@"SPTabManagerBookmarkPicker") alloc] initWithTabDocuments:_selectedTabs];

	UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:bookmarkPicker];

	if(IS_PAD)
	{
		navigationController.modalPresentationStyle = UIModalPresentationPopover;
		navigationController.popoverPresentationController.sourceView = [self presentationController].view;
		navigationController.popoverPresentationController.sourceRect = [[sender.view superview] convertRect:sender.view.frame toView:[self presentationController].view];
	}

	[[self presentationController] presentViewController:navigationController animated:YES completion:nil];
}

- (void)closeTabsButtonPressed
{
	NSArray<TabDocument*>* tabsToClose = [self nonLockedSelectedTabs];

	if(tabsToClose.count <= 0)
	{
		return;
	}

	NSString* message;

	if(tabsToClose.count == 1)
	{
		message = [localizationManager localizedSPStringForKey:@"CLOSE_TAB_WARNING_MESSAGE"];
	}
	else
	{
		message = [NSString stringWithFormat:[localizationManager localizedSPStringForKey:@"CLOSE_TABS_WARNING_MESSAGE"], tabsToClose.count];
	}

	UIAlertController* confirmationController = [UIAlertController alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"WARNING"]
						     message:message
						     preferredStyle:UIAlertControllerStyleAlert];

	UIAlertAction* yesAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"YES"]
				    style:UIAlertActionStyleDestructive
				    handler:^(UIAlertAction* action)
	{
		closeTabDocuments(_tabController, tabsToClose, NO);
	}];

	UIAlertAction* noAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"NO"]
				   style:UIAlertActionStyleDefault
				   handler:nil];

	[confirmationController addAction:noAction];
	[confirmationController addAction:yesAction];

	[[self presentationController] presentViewController:confirmationController animated:YES completion:nil];
}

- (void)exportButtonPressed:(UIBarButtonItem*)sender
{
	if(_selectedTabs.count <= 0)
	{
		return;
	}

	CGRect sourceRect = [[sender.view superview] convertRect:sender.view.frame toView:[self presentationController].view];

	void (^presentActivityController)(id) = ^void (id exportString)
	{
		UIActivityViewController* activityController = [[UIActivityViewController alloc] initWithActivityItems:@[exportString] applicationActivities:nil];
		activityController.popoverPresentationController.sourceView = [self presentationController].view;
		activityController.popoverPresentationController.sourceRect = sourceRect;

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

	//Title as fallback for when the attributed string doesn't work (on some iPads)
	UIAlertAction* hyperlinkAction = [UIAlertAction actionWithTitle:[titleForExample stringByAppendingString:[NSString stringWithFormat:@" (%@)", [localizationManager localizedSPStringForKey:@"WITH_CLICKABLE_URL"]]]
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

	formatAlertController.popoverPresentationController.sourceView = [self presentationController].view;
	formatAlertController.popoverPresentationController.sourceRect = sourceRect;

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

- (void)lockUnlockButtonPressed
{
	BOOL newLockState = !self.lockBarButtonIsUnlockButton;

	[_tabController setLocked:newLockState forTabDocuments:_selectedTabs];
}

- (void)updateSelectedTabs
{
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

	[self updateBottomToolbarButtonAvailability];
	[self updateSelectAllButton];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [[self activeTabs] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	TabDocument* tabDocument = [self tabDocumentForIndexPath:indexPath];

	SPTabManagerTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"SPTabManagerTableViewCell"];

	if(!cell)
	{
		cell = [[SPTabManagerTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SPTabManagerTableViewCell"];
	}

	[cell applyTabDocument:tabDocument];

	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(_shouldUpdateOnSelectionChange)
	{
		[self updateSelectedTabs];
	}
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(_shouldUpdateOnSelectionChange)
	{
		[self updateSelectedTabs];
	}
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
	_isFiltering = searchController.searchBar.text.length > 0;

	[self reloadAnimated:NO];

	[self updateSelectAllButton];
}

@end
