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

#import "SPPDirectoryPickerTableViewController.h"
#import "../MobileSafari/Util.h"
#import "Extensions.h"

@implementation SPPDirectoryPickerTableViewController

- (void)setUpRightBarButtonItems
{
	//UIBarButtonItem to choose current directory
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[localizationManager
											 localizedSPStringForKey:@"CHOOSE"] style:UIBarButtonItemStylePlain
						  target:self action:@selector(chooseButtonPressed)];
}

- (void)chooseButtonPressed
{
	NSNumber* isWritable;
	[self.directoryURL getResourceValue:&isWritable forKey:NSURLIsWritableKey error:nil];

	if([isWritable boolValue])
	{
		//Path is writable -> create alert to pick file name
		UIAlertController * confirmationAlert = [UIAlertController alertControllerWithTitle:
							 [localizationManager localizedSPStringForKey:@"CHOOSE_PATH_CONFIRMATION_TITLE"]
							 message:[NSString stringWithFormat:[localizationManager localizedSPStringForKey:@"CHOOSE_PATH_CONFIRMATION_MESSAGE"], self.directoryURL.path]
							 preferredStyle:UIAlertControllerStyleAlert];

		//Create yes action to pick a path
		UIAlertAction* yesAction = [UIAlertAction actionWithTitle:
					    [localizationManager localizedSPStringForKey:@"YES"]
					    style:UIAlertActionStyleDefault handler:^(UIAlertAction *addAction)
		{
			//Dismiss picker
			[self dismissViewControllerAnimated:YES completion:^
			{
				//Finish picking
				[((SPPDirectoryPickerNavigationController*)self.navigationController).pinnedLocationsDelegate
				 directoryPickerFinishedWithPath:self.directoryURL.path];
			}];
		}];

		[confirmationAlert addAction:yesAction];


		//Create no action to continue picking a path
		UIAlertAction* noAction = [UIAlertAction actionWithTitle:
					   [localizationManager localizedSPStringForKey:@"NO"]
					   style:UIAlertActionStyleDefault handler:nil];

		//Add action
		[confirmationAlert addAction:noAction];

		//Create action to close the picker
		UIAlertAction* closePickerAction = [UIAlertAction actionWithTitle:
						    [localizationManager localizedSPStringForKey:@"EXIT_PICKER"]
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
						  [localizationManager localizedSPStringForKey:@"ERROR"]
						  message:[localizationManager localizedSPStringForKey:@"PERMISSION_ERROR_MESSAGE"]
						  preferredStyle:UIAlertControllerStyleAlert];

		//Create action to close the alert
		UIAlertAction* closeAction = [UIAlertAction actionWithTitle:
					      [localizationManager localizedSPStringForKey:@"CLOSE"]
					      style:UIAlertActionStyleDefault handler:nil];

		//Add action
		[errorAlert addAction:closeAction];

		//Create action to close the picker
		UIAlertAction* closePickerAction = [UIAlertAction actionWithTitle:
						    [localizationManager localizedSPStringForKey:@"EXIT_PICKER"]
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

@end
