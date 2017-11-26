// CatalogViewController.xm
// (c) 2017 opa334

#import "../SafariPlus.h"

#import "../Classes/SPPreferenceManager.h"
#import "../Shared.h"

//Long press on Search / Site suggestions
%hook CatalogViewController

- (UITableViewCell *)tableView:(id)tableView cellForRowAtIndexPath:(id)indexPath
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
- (void)handleLongPress:(UILongPressGestureRecognizer*)gestureRecognizer
{
  if(gestureRecognizer.state == UIGestureRecognizerStateBegan)
  {
    //Get tableViewController for suggestions
    CompletionListTableViewController* completionTableController =
      MSHookIvar<CompletionListTableViewController*>(self, "_completionTableController");

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
        else //SearchSuggestion
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
