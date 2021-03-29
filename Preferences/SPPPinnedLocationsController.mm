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

#import "SPPPinnedLocationsController.h"

@implementation SPPPinnedLocationsController

- (id)init
{
	self = [super init];

	_pinnedLocationsSpecifier = [PSSpecifier preferenceSpecifierNamed:@"pinnedLocations"
				     target:self
				     set:nil
				     get:nil
				     detail:nil
				     cell:nil
				     edit:nil];

	[_pinnedLocationsSpecifier setProperty:@"com.opa334.safariplusprefs" forKey:@"defaults"];
	[_pinnedLocationsSpecifier setProperty:@"pinnedLocations" forKey:@"key"];
	[_pinnedLocationsSpecifier setProperty:@"com.opa334.safariplusprefs/ReloadPrefs" forKey:@"PostNotification"];

	return self;
}

- (NSArray*)specifiers
{
	if(!_specifiers)
	{
		_pinnedLocations = [(NSArray*)[self readPreferenceValue:_pinnedLocationsSpecifier] mutableCopy];

		if(!_pinnedLocations)
		{
			_pinnedLocations = [NSMutableArray new];
		}

		_specifiers = [NSMutableArray new];

		PSSpecifier* locationListGroup = [PSSpecifier preferenceSpecifierNamed:@""
						  target:self
						  set:nil
						  get:nil
						  detail:nil
						  cell:PSGroupCell
						  edit:nil];

		[_specifiers addObject:locationListGroup];

		for(NSDictionary* pinnedLocation in _pinnedLocations)
		{
			PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:[pinnedLocation objectForKey:@"name"]
						  target:self
						  set:nil
						  get:nil
						  detail:nil
						  cell:PSButtonCell
						  edit:nil];

			[specifier setProperty:@YES forKey:@"enabled"];
			[specifier setProperty:NSClassFromString(@"SPPBlackTextTableCell") forKey:@"cellClass"];
			specifier.buttonAction = @selector(locationPressed:);

			[_specifiers addObject:specifier];
		}

		PSSpecifier* addButtonGroup = [PSSpecifier preferenceSpecifierNamed:@""
					       target:self
					       set:nil
					       get:nil
					       detail:nil
					       cell:PSGroupCell
					       edit:nil];

		[_specifiers addObject:addButtonGroup];

		PSSpecifier* addButton = [PSSpecifier preferenceSpecifierNamed:[localizationManager localizedSPStringForKey:@"ADD"]
					  target:self
					  set:nil
					  get:nil
					  detail:nil
					  cell:PSButtonCell
					  edit:nil];

		[addButton setProperty:@YES forKey:@"enabled"];
		addButton.buttonAction = @selector(addButtonPressed);

		[_specifiers addObject:addButton];
	}

	[(UINavigationItem *)self.navigationItem setTitle:[localizationManager localizedSPStringForKey:@"PINNED_LOCATIONS"]];
	return _specifiers;
}

- (void)presentLocationAlertForLocation:(NSDictionary*)location forSpecifierAtIndexPath:(NSIndexPath*)indexPath
{
	NSString* alertTitle = indexPath ? [localizationManager localizedSPStringForKey:@"PINNED_LOCATIONS_EDIT_ALERT_TITLE"] : [localizationManager localizedSPStringForKey:@"PINNED_LOCATIONS_ADD_ALERT_TITLE"];

	UIAlertController* locationAlert = [UIAlertController alertControllerWithTitle:alertTitle
					    message:[localizationManager localizedSPStringForKey:@"PINNED_LOCATIONS_ALERT_MESSAGE"]
					    preferredStyle:UIAlertControllerStyleAlert];

	[locationAlert addTextFieldWithConfigurationHandler:^(UITextField *textField)
	{
		textField.placeholder = [localizationManager
					 localizedSPStringForKey:@"PINNED_LOCATIONS_ALERT_NAME_PLACEHOLDER"];

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
		textField.text = [location objectForKey:@"name"];
	}];

	[locationAlert addTextFieldWithConfigurationHandler:^(UITextField *textField)
	{
		textField.placeholder = [localizationManager
					 localizedSPStringForKey:@"PINNED_LOCATIONS_ALERT_PATH_PLACEHOLDER"];

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
		textField.text = [location objectForKey:@"path"];
	}];

	[locationAlert addAction:[UIAlertAction actionWithTitle:
				  [localizationManager
				   localizedSPStringForKey:@"BROWSE"] style:UIAlertActionStyleDefault
				  handler:^(UIAlertAction *addAction)
	{
		NSString* path = locationAlert.textFields[1].text;

		_modifiedSpecifierName = locationAlert.textFields[0].text;
		_modifiedSpecifierIndexPath = indexPath;

		[self openDirectoryPickerWithPath:path];
	}]];

	NSString* addEditActionTitle = indexPath ? [localizationManager localizedSPStringForKey:@"APPLY"] : [localizationManager localizedSPStringForKey:@"ADD"];

	[locationAlert addAction:[UIAlertAction actionWithTitle:addEditActionTitle
				  style:UIAlertActionStyleDefault
				  handler:^(UIAlertAction *addAction)
	{
		NSString* name = locationAlert.textFields[0].text;
		NSString* path = locationAlert.textFields[1].text;

		BOOL isDir;
		BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];

		if(![name isEqualToString:@""] && ![path isEqualToString:@""] && exists && isDir)
		{
			NSDictionary* newLocation = [self locationWithName:name path:path];

			if(indexPath)
			{
				_pinnedLocations[indexPath.row] = newLocation;
				[self setPreferenceValue:[_pinnedLocations copy] specifier:_pinnedLocationsSpecifier];

				PSSpecifier* specifier = [self specifierAtIndexPath:indexPath];
				specifier.name = name;
				[self reloadSpecifier:specifier animated:YES];
			}
			else
			{
				[_pinnedLocations addObject:newLocation];
				[self setPreferenceValue:[_pinnedLocations copy] specifier:_pinnedLocationsSpecifier];

				PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:name
							  target:self
							  set:nil
							  get:nil
							  detail:nil
							  cell:PSButtonCell
							  edit:nil];

				[specifier setProperty:@YES forKey:@"enabled"];
				[specifier setProperty:NSClassFromString(@"SPPBlackTextTableCell") forKey:@"cellClass"];
				specifier.buttonAction = @selector(locationPressed:);

				[self insertSpecifier:specifier atEndOfGroup:0 animated:YES];
			}
		}
		else
		{
			UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:
							 [localizationManager
							  localizedSPStringForKey:@"ERROR"]
							 message:[localizationManager
								  localizedSPStringForKey:@"ERROR_INVALID_NAME_OR_PATH"]
							 preferredStyle:UIAlertControllerStyleAlert];

			UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK"
						   style:UIAlertActionStyleDefault
						   handler:^(UIAlertAction* action)
			{
				NSDictionary* location = [self locationWithName:name path:path];
				[self presentLocationAlertForLocation:location forSpecifierAtIndexPath:indexPath];
			}];

			[errorAlert addAction:okAction];

			[self presentViewController:errorAlert animated:YES completion:nil];
		}
	}]];

	[locationAlert addAction:[UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CANCEL"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *cancelAction)
	{
		[locationAlert dismissViewControllerAnimated:YES completion:nil];
	}]];

	[self presentViewController:locationAlert animated:YES completion:nil];
}

- (NSDictionary*)locationWithName:(NSString*)name path:(NSString*)path
{
	NSMutableDictionary* locationM = [NSMutableDictionary new];

	if(name)
	{
		[locationM setObject:name forKey:@"name"];
	}

	if(path)
	{
		[locationM setObject:path forKey:@"path"];
	}

	return [locationM copy];
}

- (void)addButtonPressed
{
	[self presentLocationAlertForLocation:nil forSpecifierAtIndexPath:nil];
}

- (void)locationPressed:(PSSpecifier*)specifier
{
	NSIndexPath* specifierIndexPath = [self indexPathForSpecifier:specifier];
	NSDictionary* selectedLocation = _pinnedLocations[specifierIndexPath.row];
	[self presentLocationAlertForLocation:selectedLocation forSpecifierAtIndexPath:specifierIndexPath];
}

- (void)openDirectoryPickerWithPath:(NSString*)path
{
	SPPDirectoryPickerNavigationController* directoryPicker = [[SPPDirectoryPickerNavigationController alloc] initWithDelegate:self];

	[self presentViewController:directoryPicker animated:YES completion:nil];
}

- (void)directoryPickerFinishedWithPath:(NSString*)path
{
	NSDictionary* newLocation = [self locationWithName:_modifiedSpecifierName path:path];
	[self presentLocationAlertForLocation:newLocation forSpecifierAtIndexPath:_modifiedSpecifierIndexPath];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath*)indexPath
{
	if(indexPath.section == 0)
	{
		return YES;
	}

	return NO;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
	if(proposedDestinationIndexPath.section != 0)
	{
		return [NSIndexPath indexPathForRow:[tableView numberOfRowsInSection:sourceIndexPath.section] - 1 inSection:sourceIndexPath.section];
	}
	else
	{
		return proposedDestinationIndexPath;
	}
}

- (void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath*)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath
{
	NSDictionary* movedLocation = [_pinnedLocations objectAtIndex:sourceIndexPath.row];
	[_pinnedLocations removeObjectAtIndex:sourceIndexPath.row];
	[_pinnedLocations insertObject:movedLocation atIndex:destinationIndexPath.row];

	[self setPreferenceValue:[_pinnedLocations copy] specifier:_pinnedLocationsSpecifier];
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
	if(indexPath.section == 0)
	{
		return YES;
	}

	return [super tableView:tableView canEditRowAtIndexPath:indexPath];
}

- (BOOL)performDeletionActionForSpecifier:(PSSpecifier*)specifier
{
	BOOL orig = [super performDeletionActionForSpecifier:specifier];

	NSIndexPath* indexPath = [self indexPathForSpecifier:specifier];
	[_pinnedLocations removeObjectAtIndex:[indexPath row]];
	[self setPreferenceValue:[_pinnedLocations copy] specifier:_pinnedLocationsSpecifier];

	return orig;
}

@end
