// SPPExceptionsController.mm
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
		textField.textColor = [UIColor blackColor];
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
