// Copyright (c) 2017-2021 Lars Fröder

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

#import "../SafariPlus.h"

#import "../Classes/SPPreferenceManager.h"
#import "../Util.h"
#import "../Defines.h"

//Long press on Search / Site suggestions
%hook CatalogViewController

- (UITableViewCell *)tableView:(id)tableView cellForRowAtIndexPath:(id)indexPath
{
	if(preferenceManager.longPressSuggestionsEnabled || preferenceManager.suggestionInsertButtonEnabled)
	{
		UITableViewCell* orig = %orig;

		//Get item class from cell
		id target = [self _completionItemAtIndexPath:indexPath];

		if([target respondsToSelector:@selector(setSp_handler:)] && preferenceManager.suggestionInsertButtonEnabled)
		{
			((SearchSuggestion*)target).sp_handler = self;
		}

		if(preferenceManager.longPressSuggestionsEnabled)
		{
			if([target isKindOfClass:[%c(WBSBookmarkAndHistoryCompletionMatch) class]]
			   || [target isKindOfClass:[%c(SearchSuggestion) class]])
			{
				//Cell is suggestion from bookmarks / history or a search suggestion
				//-> add long press recognizer
				UILongPressGestureRecognizer* longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];

				//Get long press duration to value specified in preferences
				longPressRecognizer.minimumPressDuration = preferenceManager.longPressSuggestionsDuration;

				//Add recognizer to cell
				[orig addGestureRecognizer:longPressRecognizer];
			}
		}

		return orig;
	}

	return %orig;
}

%new
- (void)handleLongPress:(UILongPressGestureRecognizer*)gestureRecognizer
{
	if(gestureRecognizer.state == UIGestureRecognizerStateBegan)
	{
		CompletionListTableViewController* completionTableController;

		//Get tableViewController for suggestions
		if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_3)
		{
			completionTableController = MSHookIvar<CompletionListTableViewController*>(self, "_completionsViewController");
		}
		else
		{
			completionTableController = MSHookIvar<CompletionListTableViewController*>(self, "_completionTableController");
		}

		//Get tapped CGPoint
		CGPoint p = [gestureRecognizer locationInView:completionTableController.tableView];

		//Get IndexPath for tapped CGPoint
		NSIndexPath *indexPath = [completionTableController.tableView indexPathForRowAtPoint:p];

		if(indexPath != nil)
		{
			//Get tapped cell
			UITableViewCell *cell = [completionTableController.tableView cellForRowAtIndexPath:indexPath];

			if(cell.isHighlighted)
			{
				//Get completiton item for cell
				id target = [self _completionItemAtIndexPath:indexPath];

				//Get URL textfield
				UnifiedField* textField = MSHookIvar<UnifiedField*>(self, "_textField");

				[textField _setTopHit:nil];

				//Focus URL field if specified in preferences
				if(preferenceManager.longPressSuggestionsFocusEnabled)
				{
					[textField becomeFirstResponder];
				}

				if([target isKindOfClass:[%c(WBSBookmarkAndHistoryCompletionMatch) class]])
				{
					self.queryString = [target originalURLString];
				}
				else	//SearchSuggestion
				{
					self.queryString = [target string];
				}
			}
		}
	}
}

%end

%group iOS12_1_4_down

@interface SPSearchSuggestionInsertView : UIView
@property (nonatomic) BOOL rtl;
@end

@implementation SPSearchSuggestionInsertView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
	if(([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft))
	{
		//Every press left from the x position of the button should trigger the action (RTL)
		if(point.x < self.frame.size.width)
		{
			return YES;
		}
	}
	else
	{
		//Every press right from the x position of the button should trigger the action
		if(point.x >= 0)
		{
			return YES;
		}
	}

	return [super pointInside:point withEvent:event];
}

@end

%hook SearchSuggestionTableViewCell

%property (nonatomic, retain) UIImageView *hiddenAccessoryView;

%new
- (void)setHidesAccessoryView:(BOOL)hidden
{
	if(hidden && self.accessoryView)
	{
		self.hiddenAccessoryView = (UIImageView*)self.accessoryView;
		self.accessoryView = nil;
	}
	else if(!hidden && self.hiddenAccessoryView)
	{
		self.accessoryView = self.hiddenAccessoryView;
		self.hiddenAccessoryView = nil;
	}
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	SearchSuggestionTableViewCell* orig = %orig;

	if(preferenceManager.suggestionInsertButtonEnabled)
	{
		UIImageView* arrowImageView = [[UIImageView alloc] initWithFrame:CGRectMake(4,4,15,15)];

		UIImage* arrowImage = [UIImage imageNamed:@"CompletionArrow" inBundle:SPBundle compatibleWithTraitCollection:nil];

		arrowImage = [arrowImage _flatImageWithColor:self.contentView.tintColor];

		if([arrowImage respondsToSelector:@selector(imageFlippedForRightToLeftLayoutDirection)])
		{
			arrowImage = [arrowImage imageFlippedForRightToLeftLayoutDirection];
		}

		[arrowImageView setImage:arrowImage];

		self.accessoryView = [[SPSearchSuggestionInsertView alloc] initWithFrame:CGRectMake(0,0,23,23)];
		[self.accessoryView addSubview:arrowImageView];
		[self setHidesAccessoryView:YES];
	}

	return orig;
}

%end

%hook SearchSuggestion

%property (nonatomic, retain) CatalogViewController *sp_handler;

- (void)configureCompletionTableViewCell:(SearchSuggestionTableViewCell*)cell forCompletionList:(id)completionList
{
	%orig;

	if(preferenceManager.suggestionInsertButtonEnabled)
	{
		BOOL differentFromQuery = NO;

		if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0)
		{
			differentFromQuery = ![MSHookIvar<WBSCompletionQuery*>(self,"_userQuery").queryString isEqualToString:self.string];
		}
		else
		{
			differentFromQuery = ![MSHookIvar<WBSCompletionQuery*>(completionList, "_query").queryString isEqualToString:self.string];
		}

		if(differentFromQuery)
		{
			[cell setHidesAccessoryView:self.goesToURL];

			UITapGestureRecognizer* tapGestureRegognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(insertSuggestion:)];
			[cell.accessoryView removeAllGestureRecognizers];
			[cell.accessoryView addGestureRecognizer:tapGestureRegognizer];
		}
		else
		{
			[cell setHidesAccessoryView:YES];
		}
	}
}

%new
- (void)insertSuggestion:(UIGestureRecognizer*)recognizer
{
	UnifiedField* textField = MSHookIvar<UnifiedField*>(self.sp_handler, "_textField");

	[textField _setTopHit:nil];

	self.sp_handler.queryString = self.string;
}

%end

%end

void initCatalogViewController()
{
	if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_12_2)
	{
		%init(iOS12_1_4_down);
	}

	%init();
}
