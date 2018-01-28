// preferenceDirectoryPickerTableViewController.xm
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

#import "preferenceDirectoryPickerTableViewController.h"

@implementation preferenceDirectoryPickerTableViewController

- (UIBarButtonItem*)defaultRightBarButtonItem
{
  //Create and return UIBarButtonItem to choose current directory
  return [[UIBarButtonItem alloc] initWithTitle:[[SPPreferenceLocalizationManager sharedInstance]
    localizedSPStringForKey:@"CHOOSE"] style:UIBarButtonItemStylePlain
    target:self action:@selector(chooseButtonPressed)];
}

- (void)chooseButtonPressed
{
  if([self canDownloadToPath:self.currentPath])
  {
    //Path is writable -> create alert to pick file name
    UIAlertController * confirmationAlert = [UIAlertController alertControllerWithTitle:
      [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"CHOOSE_PATH_CONFIRMATION_TITLE"]
      message:[[[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"CHOOSE_PATH_CONFIRMATION_MESSAGE"]
      stringByReplacingOccurrencesOfString:@"<pathURL>" withString:[self.currentPath path]]
  		preferredStyle:UIAlertControllerStyleAlert];

    //Create yes action to pick a path
    UIAlertAction* yesAction = [UIAlertAction actionWithTitle:
      [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"YES"]
      style:UIAlertActionStyleDefault handler:^(UIAlertAction *addAction)
      {
        //Dismiss picker
        [self dismissViewControllerAnimated:YES completion:
        ^{
          //Get name
          NSString* name = ((preferenceDirectoryPickerNavigationController*)self.navigationController).name;

          //Finish picking
          [((preferenceDirectoryPickerNavigationController*)self.navigationController).pinnedLocationsDelegate
            directoryPickerFinishedWithName:name path:self.currentPath];
        }];
      }];

    [confirmationAlert addAction:yesAction];


    //Create no action to continue picking a path
    UIAlertAction* noAction = [UIAlertAction actionWithTitle:
      [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"NO"]
      style:UIAlertActionStyleDefault handler:nil];

    //Add action
    [confirmationAlert addAction:noAction];

    //Create action to close the picker
    UIAlertAction* closePickerAction = [UIAlertAction actionWithTitle:
      [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"CANCEL_PICKER"]
      style:UIAlertActionStyleDefault handler:^(UIAlertAction *addAction)
    {
      //Dismiss picker
      [self dismiss];
    }];

    //Add action
    [confirmationAlert addAction:closePickerAction];

    //Present alert
    [self presentViewController:confirmationAlert animated:YES completion:nil];
  }
  else
  {
    //Path is not writable -> Create error alert
    UIAlertController * errorAlert = [UIAlertController alertControllerWithTitle:
      [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"ERROR"]
      message:[[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"WRONG_PATH_MESSAGE"]
  		preferredStyle:UIAlertControllerStyleAlert];

    //Create action to close the alert
    UIAlertAction* closeAction = [UIAlertAction actionWithTitle:
    [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"CLOSE"]
    style:UIAlertActionStyleDefault handler:nil];

    //Add action
    [errorAlert addAction:closeAction];

    //Create action to close the picker
    UIAlertAction* closePickerAction = [UIAlertAction actionWithTitle:
      [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"CANCEL_PICKER"]
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
  NSNumber* writable;
  [pathURL getResourceValue:&writable forKey:@"NSURLIsWritableKey" error:nil];
  return [writable boolValue];
}

@end
