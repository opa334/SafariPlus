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
