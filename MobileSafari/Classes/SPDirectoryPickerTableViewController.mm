// SPDirectoryPickerTableViewController.mm
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

#import "SPDirectoryPickerTableViewController.h"

#import "../Util.h"
#import "SPDirectoryPickerNavigationController.h"
#import "SPLocalizationManager.h"
#import "SPPreferenceManager.h"
#import "SPFileManager.h"

@implementation SPDirectoryPickerTableViewController

- (void)setUpRightBarButtonItems
{
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:
						  [localizationManager localizedSPStringForKey:@"CHOOSE"] style:UIBarButtonItemStylePlain
						  target:self action:@selector(chooseButtonPressed)];
}

- (void)chooseButtonPressed
{
	NSNumber* isWritable;

	//Check if current directory is writable
	[fileManager URLResourceValue:&isWritable forKey:NSURLIsWritableKey forURL:self.directoryURL error:nil];

	if([isWritable boolValue])
	{
		//Path is writable -> create alert to pick file name
		UIAlertController* nameAlert = [UIAlertController alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"CHOOSE_FILENAME"]
						 message:nil
						 preferredStyle:UIAlertControllerStyleAlert];

		//Add textField to choose filename
		[nameAlert addTextFieldWithConfigurationHandler:^(UITextField *textField)
		{
			textField.text = ((SPDirectoryPickerNavigationController*)self.navigationController).placeholderFilename;
			textField.placeholder = [localizationManager localizedSPStringForKey:@"FILENAME"];
			textField.textColor = [UIColor blackColor];
			textField.clearButtonMode = UITextFieldViewModeWhileEditing;
			textField.borderStyle = UITextBorderStyleNone;
		}];

		//Create action to select path
		UIAlertAction* startDownloadAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"SELECT_PATH"]
						      style:UIAlertActionStyleDefault
						      handler:^(UIAlertAction *addAction)
		{
			//Get textField and the filename from it's content
			UITextField * nameField = nameAlert.textFields[0];
			NSString* filename = nameField.text;

			[self dismiss];

			[((SPDirectoryPickerNavigationController*)self.navigationController).pickerDelegate directoryPicker:self.navigationController didSelectDirectoryAtURL:self.directoryURL withFilename:filename];
		}];

		//Add action
		[nameAlert addAction:startDownloadAction];

		//Create action to close the picker
		UIAlertAction* closePickerAction = [UIAlertAction actionWithTitle:
						    [localizationManager localizedSPStringForKey:@"EXIT_PICKER"]
						    style:UIAlertActionStyleDefault handler:^(UIAlertAction *addAction)
		{
			//Dismiss picker
			[self cancel];
		}];

		//Add action
		[nameAlert addAction:closePickerAction];

		//Create action to close the alert
		UIAlertAction* closeAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CLOSE"]
					      style:UIAlertActionStyleDefault handler:nil];

		//Add action
		[nameAlert addAction:closeAction];

		//Present alert
		[self presentViewController:nameAlert animated:YES completion:nil];
	}
	else
	{
		//Path is not writable -> Create error alert
		UIAlertController * errorAlert = [UIAlertController alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"ERROR"]
						  message:[localizationManager localizedSPStringForKey:@"PERMISSION_ERROR_MESSAGE"]
						  preferredStyle:UIAlertControllerStyleAlert];

		//Create action to close the alert
		UIAlertAction* closeAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CLOSE"]
					      style:UIAlertActionStyleDefault handler:nil];

		//Add action
		[errorAlert addAction:closeAction];

		//Create action to close the picker
		UIAlertAction* closePickerAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CANCEL_PICKER"]
						    style:UIAlertActionStyleDefault handler:^(UIAlertAction *addAction)
		{
			//Close picker
			[self cancel];
		}];

		//Add action
		[errorAlert addAction:closePickerAction];

		//Present alert
		[self presentViewController:errorAlert animated:YES completion:nil];
	}
}

- (void)cancel
{
	[((SPDirectoryPickerNavigationController*)self.navigationController).pickerDelegate directoryPicker:self.navigationController didSelectDirectoryAtURL:nil withFilename:nil];

	[self dismiss];
}

@end
