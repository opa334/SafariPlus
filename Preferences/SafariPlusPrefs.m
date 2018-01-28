// SafariPlusPrefs.m
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

#import "SafariPlusPrefs.h"

@implementation SafariPlusRootListController

- (NSArray *)specifiers
{
	if(!_specifiers)
	{
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}
	[[SPPreferenceLocalizationManager sharedInstance] parseSPLocalizationsForSpecifiers:_specifiers];
	return _specifiers;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	if(section == 0)
	{
		return self.headerView;
  }

	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	if(!self.headerView)
	{
		UIImage* headerImage = [UIImage imageWithContentsOfFile:[NSString
			stringWithFormat:@"%@/PrefHeader.png", bundlePath]];

		self.headerView = [[UIImageView alloc] initWithImage:headerImage];

		CGFloat aspectRatio = 3.312;
		CGFloat width = self.parentViewController.view.frame.size.width;
		CGFloat height = width / aspectRatio;

		self.headerView.frame = CGRectMake(0,0,width,height);
	}

	if(section == 0)
	{
		return self.headerView.frame.size.height;
	}

	return 0;
}

- (void)sourceLink
{
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/opa334/SafariPlus"]];
}

- (void)donationLink
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.me/opa334d"]];
}
@end

@implementation GeneralPrefsController

- (NSArray *)specifiers
{
	if(!_specifiers)
	{
		_specifiers = [self loadSpecifiersFromPlistName:@"GeneralPrefs" target:self];
	}
	[[SPPreferenceLocalizationManager sharedInstance] parseSPLocalizationsForSpecifiers:_specifiers];
	[(UINavigationItem *)self.navigationItem setTitle:[[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"GENERAL"]];
	return _specifiers;
}

@end

@implementation DownloadPrefsController

- (NSArray *)specifiers
{
	if(!_specifiers)
	{
		_specifiers = [self loadSpecifiersFromPlistName:@"DownloadPrefs" target:self];
	}
	[[SPPreferenceLocalizationManager sharedInstance] parseSPLocalizationsForSpecifiers:_specifiers];
	[(UINavigationItem *)self.navigationItem setTitle:[[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"DOWNLOAD_ADDONS"]];
	return _specifiers;
}

- (NSArray *)instantDownloadValues
{
	return @[@1, @2];
}

- (NSArray *)instantDownloadTitles
{
	NSMutableArray* titles = [@[@"DOWNLOAD", @"DOWNLOAD_TO"] mutableCopy];
	for(int i = 0; i < titles.count; i++)
	{
		titles[i] = [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:titles[i]];
	}
	return titles;
}

@end

@implementation ExceptionsController

- (NSArray *)specifiers
{
	if(!_specifiers)
	{
		if(![[NSFileManager defaultManager] fileExistsAtPath:otherPlistPath])
		{
			[@{} writeToFile:otherPlistPath atomically:NO];
		}

		if(!plist)
		{
			plist = [[NSMutableDictionary alloc] initWithContentsOfFile:otherPlistPath];
		}

		if(![[plist allKeys] containsObject:@"ForceHTTPSExceptions"])
		{
			ForceHTTPSExceptions = [NSMutableArray new];
			[plist setObject:ForceHTTPSExceptions forKey:@"ForceHTTPSExceptions"];
			[plist writeToFile:otherPlistPath atomically:YES];
		}
		else
		{
			ForceHTTPSExceptions = [plist objectForKey:@"ForceHTTPSExceptions"];
		}

		NSMutableArray* specifiers = [NSMutableArray new];

		PSSpecifier* URLListGroup = [PSSpecifier preferenceSpecifierNamed:@""
									target:self
									set:nil
									get:nil
									detail:nil
									cell:PSGroupCell
									edit:nil];

		[specifiers addObject:URLListGroup];

		for(NSString* exception in ForceHTTPSExceptions)
		{
			PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:exception
									target:self
										set:@selector(setPreferenceValue:specifier:)
										get:@selector(readPreferenceValue:)
									detail:nil
										cell:PSStaticTextCell
										edit:nil];

			[specifier setProperty:@YES forKey:@"enabled"];

			[specifiers addObject:specifier];
		}

		_specifiers = (NSArray*)[specifiers copy];
	}

	[(UINavigationItem *)self.navigationItem setTitle:[[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"FORCE_HTTPS_EXCEPTIONS_TITLE"]];
	return _specifiers;
}

- (void)addButtonPressed
{
	UIAlertController * addLocationAlert = [UIAlertController alertControllerWithTitle:[[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"ADD_EXCEPTION_ALERT_TITLE"]
											message:[[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"ADD_EXCEPTION_ALERT_MESSAGE"]
											preferredStyle:UIAlertControllerStyleAlert];

	[addLocationAlert addTextFieldWithConfigurationHandler:^(UITextField *textField)
	{
		textField.placeholder = [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"ADD_EXCEPTION_ALERT_PLACEHOLDER"];
		textField.textColor = [UIColor blackColor];
		textField.keyboardType = UIKeyboardTypeURL;
		textField.clearButtonMode = UITextFieldViewModeWhileEditing;
		textField.borderStyle = UITextBorderStyleNone;
	}];

	[addLocationAlert addAction:[UIAlertAction actionWithTitle:[[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"CANCEL"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *cancelAction)
	{
		[addLocationAlert dismissViewControllerAnimated:YES completion:nil];
	}]];

	[addLocationAlert addAction:[UIAlertAction actionWithTitle:[[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"ADD"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *addAction)
	{
		UITextField * URLField = addLocationAlert.textFields[0];

		[ForceHTTPSExceptions addObject:URLField.text];
		[plist setObject:ForceHTTPSExceptions forKey:@"ForceHTTPSExceptions"];
		[plist writeToFile:otherPlistPath atomically:YES];

		PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:URLField.text
									target:self
									set:@selector(setPreferenceValue:specifier:)
									get:@selector(readPreferenceValue:)
									detail:nil
									cell:PSStaticTextCell
									edit:nil];

		[specifier setProperty:@YES forKey:@"enabled"];
		[self insertSpecifier:specifier atEndOfGroup:0 animated:YES];
  }]];

	[self presentViewController:addLocationAlert animated:YES completion:nil];
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
	[ForceHTTPSExceptions removeObject:[specifier name]];
	[plist setObject:ForceHTTPSExceptions forKey:@"ForceHTTPSExceptions"];
	[plist writeToFile:otherPlistPath atomically:YES];
	return orig;
}
@end

@implementation PinnedLocationsController

- (NSArray *)specifiers
{
	if(!_specifiers)
	{
		if(![[NSFileManager defaultManager] fileExistsAtPath:otherPlistPath])
		{
			[@{} writeToFile:otherPlistPath atomically:NO];
		}

		if(!plist)
		{
			plist = [[NSMutableDictionary alloc] initWithContentsOfFile:otherPlistPath];
		}

		PinnedLocationNames = [NSMutableArray new];
		PinnedLocationPaths = [NSMutableArray new];

		if(![[plist allKeys] containsObject:@"PinnedLocationNames"])
		{
			[plist setObject:PinnedLocationNames forKey:@"PinnedLocationNames"];
			[plist writeToFile:otherPlistPath atomically:YES];
		}
		else
		{
			PinnedLocationNames = [plist objectForKey:@"PinnedLocationNames"];
		}

		if(![[plist allKeys] containsObject:@"PinnedLocationPaths"])
		{
			[plist setObject:PinnedLocationPaths forKey:@"PinnedLocationPaths"];
			[plist writeToFile:otherPlistPath atomically:YES];
		}
		else
		{
			PinnedLocationPaths = [plist objectForKey:@"PinnedLocationPaths"];
		}

		NSMutableArray* specifiers = [NSMutableArray new];

		PSSpecifier* LocationListGroup = [PSSpecifier preferenceSpecifierNamed:@""
									target:self
									set:nil
									get:nil
									detail:nil
									cell:PSGroupCell
									edit:nil];

		[specifiers addObject:LocationListGroup];

		for(NSString* PinnedLocationName in PinnedLocationNames)
		{
			PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:PinnedLocationName
									target:self
										set:@selector(setPreferenceValue:specifier:)
										get:@selector(readPreferenceValue:)
									detail:nil
										cell:PSStaticTextCell
										edit:nil];

			[specifier setProperty:@YES forKey:@"enabled"];

			[specifiers addObject:specifier];
		}

		_specifiers = (NSArray*)[specifiers copy];
	}

	[(UINavigationItem *)self.navigationItem setTitle:[[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"PINNED_LOCATIONS"]];
	return _specifiers;
}

- (void)presentAddAlertWithName:(NSString*)name path:(NSString*)path
{
	UIAlertController* addLocationAlert = [UIAlertController alertControllerWithTitle:
		[[SPPreferenceLocalizationManager sharedInstance]
		localizedSPStringForKey:@"PINNED_LOCATIONS_ALERT_TITLE"]
		message:[[SPPreferenceLocalizationManager sharedInstance]
		localizedSPStringForKey:@"PINNED_LOCATIONS_ALERT_MESSAGE"]
		preferredStyle:UIAlertControllerStyleAlert];

	[addLocationAlert addTextFieldWithConfigurationHandler:^(UITextField *textField)
	{
		textField.placeholder = [[SPPreferenceLocalizationManager sharedInstance]
			localizedSPStringForKey:@"PINNED_LOCATIONS_ALERT_NAME_PLACEHOLDER"];

		textField.textColor = [UIColor blackColor];
		textField.clearButtonMode = UITextFieldViewModeWhileEditing;
		textField.borderStyle = UITextBorderStyleNone;
		textField.text = name;
	}];

	[addLocationAlert addTextFieldWithConfigurationHandler:^(UITextField *textField)
	{
		textField.placeholder = [[SPPreferenceLocalizationManager sharedInstance]
			localizedSPStringForKey:@"PINNED_LOCATIONS_ALERT_PATH_PLACEHOLDER"];

		textField.textColor = [UIColor blackColor];
		textField.clearButtonMode = UITextFieldViewModeWhileEditing;
		textField.borderStyle = UITextBorderStyleNone;
		textField.text = path;
	}];

	[addLocationAlert addAction:[UIAlertAction actionWithTitle:
		[[SPPreferenceLocalizationManager sharedInstance]
		localizedSPStringForKey:@"BROWSE"] style:UIAlertActionStyleDefault
		handler:^(UIAlertAction *addAction)
	{
		NSString* name = addLocationAlert.textFields[0].text;
		[self openDirectoryPickerWithName:name];
	}]];

	[addLocationAlert addAction:[UIAlertAction actionWithTitle:
		[[SPPreferenceLocalizationManager sharedInstance]
		localizedSPStringForKey:@"ADD"] style:UIAlertActionStyleDefault
		handler:^(UIAlertAction *addAction)
	{
		NSString* name = addLocationAlert.textFields[0].text;
		NSString* path = addLocationAlert.textFields[1].text;

		BOOL isDir;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];

		if(![name isEqualToString:@""] && ![path isEqualToString:@""] && exists && isDir)
		{
			[PinnedLocationNames addObject:name];
			[plist setObject:PinnedLocationNames forKey:@"PinnedLocationNames"];
			[plist writeToFile:otherPlistPath atomically:YES];

			[PinnedLocationPaths addObject:path];
			[plist setObject:PinnedLocationPaths forKey:@"PinnedLocationPaths"];
			[plist writeToFile:otherPlistPath atomically:YES];

			PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:name
										target:self
										set:@selector(setPreferenceValue:specifier:)
										get:@selector(readPreferenceValue:)
										detail:nil
										cell:PSStaticTextCell
										edit:nil];

			[specifier setProperty:@YES forKey:@"enabled"];
			[self insertSpecifier:specifier atEndOfGroup:0 animated:YES];
		}
		else
		{
			UIAlertController* errorAlert = [UIAlertController alertControllerWithTitle:
				[[SPPreferenceLocalizationManager sharedInstance]
				localizedSPStringForKey:@"ERROR"]
				message:[[SPPreferenceLocalizationManager sharedInstance]
				localizedSPStringForKey:@"ERROR_INVALID_NAME_OR_PATH"]
				preferredStyle:UIAlertControllerStyleAlert];

			UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK"
				style:UIAlertActionStyleDefault
				handler:nil];

			[errorAlert addAction:okAction];

			[self presentViewController:errorAlert animated:YES completion:nil];
		}
  }]];

	[addLocationAlert addAction:[UIAlertAction actionWithTitle:[[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"CANCEL"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *cancelAction)
	{
		[addLocationAlert dismissViewControllerAnimated:YES completion:nil];
	}]];

	[self presentViewController:addLocationAlert animated:YES completion:nil];
}

- (void)addButtonPressed
{
	[self presentAddAlertWithName:nil path:nil];
}

- (void)openDirectoryPickerWithName:(NSString*)name
{
	preferenceDirectoryPickerNavigationController* directoryPicker =
		[[preferenceDirectoryPickerNavigationController alloc] initWithDelegate:self name:name];

	[self presentViewController:directoryPicker animated:YES completion:nil];
}

- (void)directoryPickerFinishedWithName:(NSString*)name path:(NSURL*)pathURL
{
	[self presentAddAlertWithName:name path:[pathURL path]];
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

	NSIndexPath* indexPath = [self indexPathForSpecifier:specifier];

	[PinnedLocationNames removeObjectAtIndex:[indexPath row]];
	[PinnedLocationPaths removeObjectAtIndex:[indexPath row]];

	[plist setObject:PinnedLocationNames forKey:@"PinnedLocationNames"];
	[plist setObject:PinnedLocationPaths forKey:@"PinnedLocationPaths"];

	[plist writeToFile:otherPlistPath atomically:YES];
	return orig;
}
@end

@implementation ActionPrefsController

- (NSArray *)specifiers
{
	if(!_specifiers)
	{
		_specifiers = [self loadSpecifiersFromPlistName:@"ActionPrefs" target:self];
	}
	[[SPPreferenceLocalizationManager sharedInstance] parseSPLocalizationsForSpecifiers:_specifiers];
	[(UINavigationItem *)self.navigationItem setTitle:[[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"ACTION_ADDONS"]];
	return _specifiers;
}

- (NSArray *)modeValues
{
	return @[@(ModeSwitchActionNormalMode), @(ModeSwitchActionPrivateMode)];
}

- (NSArray *)modeTitles
{
	NSMutableArray* titles = [@[@"NORMAL_MODE", @"PRIVATE_MODE"] mutableCopy];
	for(int i = 0; i < titles.count; i++)
	{
		titles[i] = [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:titles[i]];
	}
	return titles;
}

- (NSArray *)stateValues
{
	return @[@(CloseTabActionOnSafariClosed), @(CloseTabActionOnSafariMinimized)];
}

- (NSArray *)stateTitles
{
	NSMutableArray* titles = [@[@"SAFARI_CLOSED", @"SAFARI_MINIMIZED"] mutableCopy];
	for(int i = 0; i < titles.count; i++)
	{
		titles[i] = [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:titles[i]];
	}
	return titles;
}

- (NSArray *)closeModeValues
{
	return @[@(CloseTabActionFromActiveMode), @(CloseTabActionFromNormalMode), @(CloseTabActionFromPrivateMode), @(CloseTabActionFromBothModes)];
}

- (NSArray *)closeModeTitles
{
	NSMutableArray* titles = [@[@"ACTIVE_MODE", @"NORMAL_MODE", @"PRIVATE_MODE", @"BOTH_MODES"] mutableCopy];
	for(int i = 0; i < titles.count; i++)
	{
		titles[i] = [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:titles[i]];
	}
	return titles;
}

@end

@implementation GesturePrefsController

- (NSArray *)specifiers
{
	if(!_specifiers)
	{
		_specifiers = [self loadSpecifiersFromPlistName:@"GesturePrefs" target:self];
	}
	[[SPPreferenceLocalizationManager sharedInstance] parseSPLocalizationsForSpecifiers:_specifiers];
	[(UINavigationItem *)self.navigationItem setTitle:[[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"GESTURE_ADDONS"]];
	return _specifiers;
}

- (NSArray *)gestureActionValues
{
	return @[@(GestureActionCloseActiveTab), @(GestureActionOpenNewTab), @(GestureActionDuplicateActiveTab), @(GestureActionCloseAllTabs), @(GestureActionSwitchMode), @(GestureActionSwitchTabBackwards), @(GestureActionSwitchTabForwards), @(GestureActionReloadActiveTab), @(GestureActionRequestDesktopSite), @(GestureActionOpenFindOnPage)];
}

- (NSArray *)gestureActionTitles
{
	NSMutableArray* titles = [@[@"CLOSE_ACTIVE_TAB", @"OPEN_NEW_TAB", @"DUPLICATE_ACTIVE_TAB", @"CLOSE_ALL_TABS", @"SWITCH_MODE", @"TAB_BACKWARD", @"TAB_FORWARD", @"RELOAD_ACTIVE_TAB", @"REQUEST_DESTKOP_SITE", @"OPEN_FIND_ON_PAGE"] mutableCopy];
	for(int i = 0; i < titles.count; i++)
	{
		titles[i] = [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:titles[i]];
	}
	return titles;
}

@end

@implementation OtherPrefsController

- (NSArray *)specifiers
{
	if(!_specifiers)
	{
		_specifiers = [self loadSpecifiersFromPlistName:@"OtherPrefs" target:self];
	}
	[[SPPreferenceLocalizationManager sharedInstance] parseSPLocalizationsForSpecifiers:_specifiers];
	[(UINavigationItem *)self.navigationItem setTitle:[[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"OTHER_ADDONS"]];
	return _specifiers;
}
@end

#ifndef ELECTRA

@implementation ColorPrefsController

- (NSArray *)specifiers
{
	if(!_specifiers)
	{
		_specifiers = [self loadSpecifiersFromPlistName:@"ColorPrefs" target:self];
	}
	[[SPPreferenceLocalizationManager sharedInstance] parseSPLocalizationsForSpecifiers:_specifiers];
	[(UINavigationItem *)self.navigationItem setTitle:[[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"COLOR_SETTINGS"]];
	return _specifiers;
}
@end

@implementation NormalColorPrefsController

- (NSArray *)specifiers
{
	if(!_specifiers)
	{
		_specifiers = [self loadSpecifiersFromPlistName:@"NormalColorPrefs" target:self];
	}
	[[SPPreferenceLocalizationManager sharedInstance] parseSPLocalizationsForSpecifiers:_specifiers];
	[(UINavigationItem *)self.navigationItem setTitle:[[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"NORMAL_MODE"]];
	return _specifiers;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self reload];
    [super viewWillAppear:animated];
}
@end

@implementation PrivateColorPrefsController

- (NSArray *)specifiers
{
	if(!_specifiers)
	{
		_specifiers = [self loadSpecifiersFromPlistName:@"PrivateColorPrefs" target:self];
	}
	[[SPPreferenceLocalizationManager sharedInstance] parseSPLocalizationsForSpecifiers:_specifiers];
	[(UINavigationItem *)self.navigationItem setTitle:[[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"PRIVATE_MODE"]];
	return _specifiers;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self reload];
    [super viewWillAppear:animated];
}
@end

#else

@implementation ColorPrefsController

- (NSArray *)specifiers
{
	[(UINavigationItem *)self.navigationItem setTitle:@"Not supported on Electra"];
	return nil;
}
@end

#endif

@implementation CreditsController

- (NSArray *)specifiers
{
	if(!_specifiers)
	{
		_specifiers = [self loadSpecifiersFromPlistName:@"Credits" target:self];
	}
	[[SPPreferenceLocalizationManager sharedInstance] parseSPLocalizationsForSpecifiers:_specifiers];
	[(UINavigationItem *)self.navigationItem setTitle:[[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"CREDITS"]];
	return _specifiers;
}

- (void)WatusiLink
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.reddit.com/r/jailbreak/comments/6f7zdn/release_watusi_2_your_allinone_tweak_for_whatsapp/"]];
}

@end
