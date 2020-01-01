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
			if([UIColor respondsToSelector:@selector(labelColor)])
			{
				textField.textColor = [UIColor labelColor];
			}
			else
			{
				textField.textColor = [UIColor blackColor];
			}
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
		UIAlertAction* closePickerAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"EXIT_PICKER"]
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
