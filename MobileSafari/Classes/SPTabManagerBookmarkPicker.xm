// SPTabManagerBookmarkPicker.mm
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

#import "SPTabManagerBookmarkPicker.h"
#import "../SafariPlus.h"
#import "../Util.h"
#import "SPLocalizationManager.h"

%subclass SPTabManagerBookmarkPicker : BookmarkInfoViewController

%property (nonatomic, retain) NSArray *tabDocuments;

%new
- (instancetype)initWithTabDocuments:(NSArray<TabDocument*>*)tabDocuments
{
	WebBookmarkCollection* collection = [%c(WebBookmarkCollection) safariBookmarkCollection];

	if([self respondsToSelector:@selector(initWithBookmark:inCollection:addingBookmark:toFavorites:willBeDisplayedModally:)])
	{
		self = [self initWithBookmark:nil inCollection:collection addingBookmark:YES toFavorites:NO willBeDisplayedModally:NO];
	}
	else
	{
		self = [self initWithBookmark:nil inCollection:collection addingBookmark:YES];
	}

	self.tabDocuments = tabDocuments;

	NSString* parent = [[NSUserDefaults standardUserDefaults] stringForKey:@"LastSelectedBookmarksFolder"];

	WebBookmark* parentBookmark;

	if([parent isEqualToString:@"Favorites"])
	{
		parentBookmark = [collection favoritesFolder];
	}
	else
	{
		parentBookmark = [collection bookmarkWithUUID:parent];
	}

	MSHookIvar<WebBookmark*>(self, "_parentBookmark") = parentBookmark;

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[localizationManager
											 localizedSPStringForKey:@"SAVE"] style:UIBarButtonItemStyleDone
						  target:self action:@selector(saveTabDocumentsAsBookmarks)];

	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[localizationManager
											localizedSPStringForKey:@"CANCEL"] style:UIBarButtonItemStylePlain
						 target:self action:@selector(cancel)];

	self.title = [localizationManager localizedSPStringForKey:@"ADD_BOOKMARKS"];

	return self;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	if(section == 0)
	{
		return nil;
	}
	return %orig;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section == 0)
	{
		return 0;
	}
	return %orig;
}

%new
- (void)saveTabDocumentsAsBookmarks
{
	BOOL locked = [%c(WebBookmarkCollection) isLockedSync];

	if(!locked)
	{
		[%c(WebBookmarkCollection) lockSync];
	}

	WebBookmarkCollection* collection = MSHookIvar<WebBookmarkCollection*>(self, "_collection");
	WebBookmark* parentBookmark = MSHookIvar<WebBookmark*>(self, "_parentBookmark");

	[[NSUserDefaults standardUserDefaults] setObject:parentBookmark.UUID forKey:@"LastSelectedBookmarksFolder"];

	for(TabDocument* tabDocument in self.tabDocuments)
	{
		WebBookmark* bookmark = [[%c(WebBookmark) alloc] initWithTitle:[tabDocument titleForNewBookmark] address:[tabDocument URL].absoluteString];

		[collection moveBookmark:bookmark toFolderWithID:parentBookmark.identifier];
		[collection saveBookmark:bookmark];
	}

	if(!locked)
	{
		[%c(WebBookmarkCollection) unlockSync];
	}

	[self dismissViewControllerAnimated:YES completion:nil];
}

%new
- (void)cancel
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)canSaveChanges
{
	return YES;
}

%end

void initSPTabManagerBookmarkPicker()
{
	Class BookmarkInfoViewControllerClass = NSClassFromString(@"BookmarkInfoViewController");

	if(!BookmarkInfoViewControllerClass)
	{
		BookmarkInfoViewControllerClass = NSClassFromString(@"_SFBookmarkInfoViewController");
	}

	%init(BookmarkInfoViewController=BookmarkInfoViewControllerClass)
}
