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

void otherPlistChanged()
{
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.opa334.safariplusprefs/ReloadOtherPlist"), NULL, NULL, true);
}

@implementation SPListController

//Must be overwritten by subclass
- (NSString*)title
{
	return nil;
}

//Must be overwritten by subclass
- (NSString*)plistName
{
	return nil;
}

- (NSMutableArray*)specifiers
{
	if(!_specifiers)
	{
		_specifiers = [self loadSpecifiersFromPlistName:[self plistName] target:self];
		[[SPPreferenceLocalizationManager sharedInstance] parseSPLocalizationsForSpecifiers:_specifiers];

		_allSpecifiers = [_specifiers copy];
		[self removeDisabledGroups:_specifiers];
	}

	[(UINavigationItem *)self.navigationItem setTitle:[self title]];
	return _specifiers;
}

- (void)removeDisabledGroups:(NSMutableArray*)specifiers;
{
	for(PSSpecifier* specifier in [specifiers reverseObjectEnumerator])
	{
		NSNumber* nestedEntryCount = [[specifier properties] objectForKey:@"nestedEntryCount"];
		if(nestedEntryCount)
		{
			CFStringRef key = (__bridge CFStringRef)[[specifier properties] objectForKey:@"key"];
			CFStringRef defaults = (__bridge CFStringRef)[[specifier properties] objectForKey:@"defaults"];

			Boolean keyExists;
			Boolean enabled = CFPreferencesGetAppBooleanValue(key, defaults, &keyExists);

			if(!enabled || !keyExists)
			{
				NSMutableArray* nestedEntries = [[_allSpecifiers subarrayWithRange:NSMakeRange([_allSpecifiers indexOfObject:specifier]+1, [nestedEntryCount intValue])] mutableCopy];

				BOOL containsNestedEntries = NO;

				for(PSSpecifier* nestedEntry in nestedEntries)
				{
					NSNumber* nestedNestedEntryCount = [[nestedEntry properties] objectForKey:@"nestedEntryCount"];
					if(nestedNestedEntryCount)
					{
						containsNestedEntries = YES;
						break;
					}
				}

				if(containsNestedEntries)
				{
					[self removeDisabledGroups:nestedEntries];
				}

				[specifiers removeObjectsInArray:nestedEntries];
			}
		}
	}
}

- (void)setPreferenceValue:(NSNumber *)value specifier:(PSSpecifier*)specifier
{
	[super setPreferenceValue:value specifier:specifier];

	NSNumber* nestedEntryCount = [[specifier properties] objectForKey:@"nestedEntryCount"];
	if(nestedEntryCount)
	{
		NSInteger index = [_allSpecifiers indexOfObject:specifier];
		NSMutableArray* nestedEntries = [[_allSpecifiers subarrayWithRange:NSMakeRange(index + 1, [nestedEntryCount intValue])] mutableCopy];
		[self removeDisabledGroups:nestedEntries];

		if([value boolValue])
		{
			[self insertContiguousSpecifiers:nestedEntries afterSpecifier:specifier animated:YES];
		}
		else
		{
			[self removeContiguousSpecifiers:nestedEntries animated:YES];
		}
	}
}

@end

@implementation SafariPlusRootListController

- (NSString*)title
{
	return @"Safari Plus";
}

- (NSString*)plistName
{
	return @"Root";
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

- (NSString*)title
{
	return [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"GENERAL"];
}

- (NSString*)plistName
{
	return @"GeneralPrefs";
}

@end

@implementation DownloadPrefsController

- (NSString*)title
{
	return [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"DOWNLOAD_ADDONS"];
}

- (NSString*)plistName
{
	return @"DownloadPrefs";
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
			otherPlistChanged();
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
			otherPlistChanged();
		}
		else
		{
			ForceHTTPSExceptions = [plist objectForKey:@"ForceHTTPSExceptions"];
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

		for(NSString* exception in ForceHTTPSExceptions)
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

		otherPlistChanged();
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
	[plist writeToFile:otherPlistPath atomically:YES];
	otherPlistChanged();
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
			otherPlistChanged();
		}

		if(!plist)
		{
			plist = [[NSMutableDictionary alloc] initWithContentsOfFile:otherPlistPath];
		}

		if(![[plist allKeys] containsObject:@"PinnedLocationNames"])
		{
			PinnedLocationNames = [NSMutableArray new];
			[plist setObject:PinnedLocationNames forKey:@"PinnedLocationNames"];
			[plist writeToFile:otherPlistPath atomically:YES];
			otherPlistChanged();
		}
		else
		{
			PinnedLocationNames = [plist objectForKey:@"PinnedLocationNames"];
		}

		if(![[plist allKeys] containsObject:@"PinnedLocationPaths"])
		{
			PinnedLocationPaths = [NSMutableArray new];
			[plist setObject:PinnedLocationPaths forKey:@"PinnedLocationPaths"];
			[plist writeToFile:otherPlistPath atomically:YES];
			otherPlistChanged();
		}
		else
		{
			PinnedLocationPaths = [plist objectForKey:@"PinnedLocationPaths"];
		}

		_specifiers = [NSMutableArray new];

		PSSpecifier* LocationListGroup = [PSSpecifier preferenceSpecifierNamed:@""
									target:self
									set:nil
									get:nil
									detail:nil
									cell:PSGroupCell
									edit:nil];

		[_specifiers addObject:LocationListGroup];

		for(NSString* PinnedLocationName in PinnedLocationNames)
		{
			PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:PinnedLocationName
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
			[PinnedLocationPaths addObject:path];

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

			otherPlistChanged();
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

	[plist writeToFile:otherPlistPath atomically:YES];
	otherPlistChanged();

	return orig;
}
@end

@implementation ActionPrefsController

- (NSString*)title
{
	return [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"ACTION_ADDONS"];
}

- (NSString*)plistName
{
	return @"ActionPrefs";
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

- (NSString*)title
{
	return [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"GESTURE_ADDONS"];
}

- (NSString*)plistName
{
	return @"GesturePrefs";
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

- (NSString*)title
{
	return [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"OTHER_ADDONS"];
}

- (NSString*)plistName
{
	return @"OtherPrefs";
}

@end

@implementation ColorOverviewPrefsController

- (NSString*)title
{
	return [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"COLOR_SETTINGS"];
}

- (NSString*)plistName
{
	return @"ColorPrefsOverview";
}

@end

@implementation TopBarNormalColorPrefsController

- (NSString*)title
{
	return [NSString stringWithFormat:@"%@ (%@)", [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"TOP_BAR"], [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"NORMAL"]];
}

- (NSString*)plistName
{
	return @"TopBarNormalColorPrefs";
}

@end

@implementation TopBarPrivateColorPrefsController

- (NSString*)title
{
	return [NSString stringWithFormat:@"%@ (%@)", [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"TOP_BAR"], [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"PRIVATE"]];
}

- (NSString*)plistName
{
	return @"TopBarPrivateColorPrefs";
}

@end

@implementation BottomBarNormalColorPrefsController

- (NSString*)title
{
	return [NSString stringWithFormat:@"%@ (%@)", [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"BOTTOM_BAR"], [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"NORMAL"]];
}

- (NSString*)plistName
{
	return @"BottomBarNormalColorPrefs";
}

@end

@implementation BottomBarPrivateColorPrefsController

- (NSString*)title
{
	return [NSString stringWithFormat:@"%@ (%@)", [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"BOTTOM_BAR"], [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"PRIVATE"]];
}

- (NSString*)plistName
{
	return @"BottomBarPrivateColorPrefs";
}

@end

@implementation TabSwitcherNormalColorPrefsController

- (NSString*)title
{
	return [NSString stringWithFormat:@"%@ (%@)", [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"TAB_SWITCHER"], [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"NORMAL"]];
}

- (NSString*)plistName
{
	return @"TabSwitcherNormalColorPrefs";
}

@end

@implementation TabSwitcherPrivateColorPrefsController

- (NSString*)title
{
	return [NSString stringWithFormat:@"%@ (%@)", [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"TAB_SWITCHER"], [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"PRIVATE"]];
}

- (NSString*)plistName
{
	return @"TabSwitcherPrivateColorPrefs";
}

@end

@implementation CreditsController

- (NSString*)title
{
	return [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"CREDITS"];
}

- (NSString*)plistName
{
	return @"Credits";
}

- (void)WatusiLink
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.reddit.com/r/jailbreak/comments/6f7zdn/release_watusi_2_your_allinone_tweak_for_whatsapp/"]];
}

@end
