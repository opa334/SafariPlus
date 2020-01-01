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

#import "SPPExceptionsController.h"

@implementation SPPExceptionsController

- (id)init
{
	self = [super init];

	_forceHTTPSExceptionsSpecifier = [PSSpecifier preferenceSpecifierNamed:@"forceHTTPSExceptions"
					  target:self
					  set:nil
					  get:nil
					  detail:nil
					  cell:nil
					  edit:nil];

	[_forceHTTPSExceptionsSpecifier setProperty:@"com.opa334.safariplusprefs" forKey:@"defaults"];
	[_forceHTTPSExceptionsSpecifier setProperty:@"forceHTTPSExceptions" forKey:@"key"];
	[_forceHTTPSExceptionsSpecifier setProperty:@"com.opa334.safariplusprefs/ReloadPrefs" forKey:@"PostNotification"];

	return self;
}

- (BOOL)shouldReloadSpecifiersOnResume
{
	return YES;
}

- (NSArray *)specifiers
{
	if(!_specifiers)
	{
		_forceHTTPSExceptions = [(NSArray*)[self readPreferenceValue:_forceHTTPSExceptionsSpecifier] mutableCopy];

		if(!_forceHTTPSExceptions)
		{
			_forceHTTPSExceptions = [NSMutableArray new];
		}

		_specifiers = [NSMutableArray new];

		PSSpecifier* URLListGroup = [PSSpecifier preferenceSpecifierNamed:@""
					     target:self
					     set:nil
					     get:nil
					     detail:nil
					     cell:PSGroupCell
					     edit:nil];

		[_specifiers addObject:URLListGroup];

		for(NSString* exception in _forceHTTPSExceptions)
		{
			PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:exception
						  target:self
						  set:nil
						  get:nil
						  detail:nil
						  cell:PSStaticTextCell
						  edit:nil];

			[specifier setProperty:@YES forKey:@"enabled"];

			[_specifiers addObject:specifier];
		}
	}

	[(UINavigationItem *)self.navigationItem setTitle:[localizationManager localizedSPStringForKey:@"FORCE_HTTPS_EXCEPTIONS_TITLE"]];
	return _specifiers;
}

- (void)addButtonPressed
{
	UIAlertController* locationAlert = [UIAlertController alertControllerWithTitle:[localizationManager localizedSPStringForKey:@"ADD_EXCEPTION_ALERT_TITLE"]
					    message:[localizationManager localizedSPStringForKey:@"ADD_EXCEPTION_ALERT_MESSAGE"]
					    preferredStyle:UIAlertControllerStyleAlert];

	[locationAlert addTextFieldWithConfigurationHandler:^(UITextField *textField)
	{
		textField.placeholder = [localizationManager localizedSPStringForKey:@"ADD_EXCEPTION_ALERT_PLACEHOLDER"];
		if([UIColor respondsToSelector:@selector(labelColor)])
		{
			textField.textColor = [UIColor labelColor];
		}
		else
		{
			textField.textColor = [UIColor blackColor];
		}
		textField.keyboardType = UIKeyboardTypeURL;
		textField.clearButtonMode = UITextFieldViewModeWhileEditing;
		textField.borderStyle = UITextBorderStyleNone;
	}];

	[locationAlert addAction:[UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CANCEL"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *cancelAction)
	{
		[locationAlert dismissViewControllerAnimated:YES completion:nil];
	}]];

	[locationAlert addAction:[UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"ADD"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *addAction)
	{
		UITextField * URLField = locationAlert.textFields[0];

		[_forceHTTPSExceptions addObject:URLField.text];
		[self setPreferenceValue:[_forceHTTPSExceptions copy] specifier:_forceHTTPSExceptionsSpecifier];

		PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:URLField.text
					  target:self
					  set:nil
					  get:nil
					  detail:nil
					  cell:PSStaticTextCell
					  edit:nil];

		[specifier setProperty:@YES forKey:@"enabled"];
		[self insertSpecifier:specifier atEndOfGroup:0 animated:YES];
	}]];

	[self presentViewController:locationAlert animated:YES completion:nil];
}

- (id)_editButtonBarItem
{
	UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonPressed)];
	return addButton;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleDelete;
}

- (BOOL)performDeletionActionForSpecifier:(PSSpecifier*)specifier
{
	BOOL orig = [super performDeletionActionForSpecifier:specifier];

	[_forceHTTPSExceptions removeObject:[specifier name]];
	[self setPreferenceValue:[_forceHTTPSExceptions copy] specifier:_forceHTTPSExceptionsSpecifier];

	return orig;
}

@end
