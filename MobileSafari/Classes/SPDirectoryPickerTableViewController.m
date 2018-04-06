// SPDirectoryPickerTableViewController.m
// (c) 2017 opa334

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

#import "SPDirectoryPickerTableViewController.h"

#import "../Shared.h"
#import "SPDirectoryPickerNavigationController.h"
#import "SPDownloadInfo.h"
#import "SPDownloadManager.h"
#import "SPLocalizationManager.h"
#import "SPPreferenceManager.h"

@implementation SPDirectoryPickerTableViewController

- (UIBarButtonItem*)defaultRightBarButtonItem
{
  //Create and return UIBarButtonItem to choose current directory
  return [[UIBarButtonItem alloc] initWithTitle:[localizationManager
    localizedSPStringForKey:@"CHOOSE"] style:UIBarButtonItemStylePlain
    target:self action:@selector(chooseButtonPressed)];
}

- (void)chooseButtonPressed
{
  if([self canDownloadToPath:self.currentPath])
  {
    //Get downloadInfo
    SPDownloadInfo* downloadInfo = ((SPDirectoryPickerNavigationController*)
      self.navigationController).downloadInfo;

    //Path is writable -> create alert to pick file name
    UIAlertController * nameAlert = [UIAlertController alertControllerWithTitle:
      [localizationManager localizedSPStringForKey:@"CHOOSE_FILENAME"] message:nil
  		preferredStyle:UIAlertControllerStyleAlert];

    //Add textField to choose filename
  	[nameAlert addTextFieldWithConfigurationHandler:^(UITextField *textField)
  	{
      textField.text = downloadInfo.filename;
  		textField.placeholder = [localizationManager localizedSPStringForKey:@"FILENAME"];
  		textField.textColor = [UIColor blackColor];
  		textField.clearButtonMode = UITextFieldViewModeWhileEditing;
  		textField.borderStyle = UITextBorderStyleNone;
  	}];

    //Create action to start downloading
    UIAlertAction* startDownloadAction = [UIAlertAction
      actionWithTitle:[localizationManager
      localizedSPStringForKey:@"START_DOWNLOAD"]
      style:UIAlertActionStyleDefault handler:^(UIAlertAction *addAction)
  	{
      //Get textField and the filename from it's content
  		UITextField * nameField = nameAlert.textFields[0];
      NSString* filename = nameField.text;

      downloadInfo.filename = filename;

      downloadInfo.targetPath = self.currentPath;

      [self dismiss];

      [downloadManager pathSelectionResponseWithDownloadInfo:downloadInfo];
    }];

    //Add action
    [nameAlert addAction:startDownloadAction];

    //Create action to close the picker
    UIAlertAction* closePickerAction = [UIAlertAction actionWithTitle:
      [localizationManager localizedSPStringForKey:@"CANCEL_PICKER"]
      style:UIAlertActionStyleDefault handler:^(UIAlertAction *addAction)
    {
      //Dismiss picker
      [self dismiss];
    }];

    //Add action
    [nameAlert addAction:closePickerAction];

    //Create action to close the alert
  	UIAlertAction* closeAction = [UIAlertAction actionWithTitle:
      [localizationManager localizedSPStringForKey:@"CLOSE"]
      style:UIAlertActionStyleDefault handler:nil];

    //Add action
    [nameAlert addAction:closeAction];

    //Present alert
    [self presentViewController:nameAlert animated:YES completion:nil];
  }
  else
  {
    //Path is not writable -> Create error alert
    UIAlertController * errorAlert = [UIAlertController alertControllerWithTitle:
      [localizationManager localizedSPStringForKey:@"ERROR"]
      message:[localizationManager localizedSPStringForKey:@"WRONG_PATH_MESSAGE"]
  		preferredStyle:UIAlertControllerStyleAlert];

    //Create action to close the alert
    UIAlertAction* closeAction = [UIAlertAction actionWithTitle:
    [localizationManager localizedSPStringForKey:@"CLOSE"]
    style:UIAlertActionStyleDefault handler:nil];

    //Add action
    [errorAlert addAction:closeAction];

    //Create action to close the picker
    UIAlertAction* closePickerAction = [UIAlertAction actionWithTitle:
      [localizationManager localizedSPStringForKey:@"CANCEL_PICKER"]
      style:UIAlertActionStyleDefault handler:^(UIAlertAction *addAction)
    {
      //Close picker
      [self dismiss];
    }];

    //Add action
    [errorAlert addAction:closePickerAction];

    //Present alert
    [self presentViewController:errorAlert animated:YES completion:nil];
  }
}

- (BOOL)canDownloadToPath:(NSURL*)pathURL
{
  //Check if path is writable and return it
  NSNumber* writable;
  [pathURL getResourceValue:&writable forKey:@"NSURLIsWritableKey" error:nil];
  return [writable boolValue];
}

@end
