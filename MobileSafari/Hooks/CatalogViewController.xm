// CatalogViewController.xm
// (c) 2018 opa334

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

#import "../SafariPlus.h"

#import "../Classes/SPPreferenceManager.h"
#import "../Shared.h"
#import "../Defines.h"

//Long press on Search / Site suggestions
%hook CatalogViewController

- (UITableViewCell *)tableView: (id)tableView cellForRowAtIndexPath: (id)indexPath
{
	if(preferenceManager.longPressSuggestionsEnabled)
	{
		UITableViewCell* orig = %orig;

		//Get item class from cell
		id target = [self _completionItemAtIndexPath:indexPath];

		if([target isKindOfClass:[%c(WBSBookmarkAndHistoryCompletionMatch) class]]
		   || [target isKindOfClass:[%c(SearchSuggestion) class]])
		{
			//Cell is suggestion from bookmarks / history or a search suggestion
			//-> add long press recognizer
			UILongPressGestureRecognizer* longPressRecognizer = [[UILongPressGestureRecognizer alloc]
									     initWithTarget:self action:@selector(handleLongPress:)];

			//Get long press duration to value specified in preferences
			longPressRecognizer.minimumPressDuration = preferenceManager.longPressSuggestionsDuration;

			//Add recognizer to cell
			[orig addGestureRecognizer:longPressRecognizer];
		}

		return orig;
	}

	return %orig;
}

%new
- (void)handleLongPress: (UILongPressGestureRecognizer*)gestureRecognizer
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

				if([target isKindOfClass:[%c(WBSBookmarkAndHistoryCompletionMatch) class]])
				{
					//Set long pressed URL to textField
					[textField setText:[target originalURLString]];
				}
				else	//SearchSuggestion
				{
					//Set long pressed search string to textField
					[textField setText:[target string]];
				}

				//Focus URL field if specified in preferences
				if(preferenceManager.longPressSuggestionsFocusEnabled)
				{
					[textField becomeFirstResponder];
				}

				//Update Field
				[textField _textDidChangeFromTyping];
				[self _textFieldEditingChanged];
			}
		}
	}
}

%end
