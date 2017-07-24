//  SafariPlusPrefs.m
//  Preference bundle for SafariPlus

// (c) 2017 opa334

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


- (void)sourceLink
{
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/opa334/SafariPlus"]];
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
	UIAlertController * addExceptionAlert = [UIAlertController alertControllerWithTitle:[[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"ADD_EXCEPTION_ALERT_TITLE"]
											message:[[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"ADD_EXCEPTION_ALERT_MESSAGE"]
											preferredStyle:UIAlertControllerStyleAlert];

	[addExceptionAlert addTextFieldWithConfigurationHandler:^(UITextField *textField)
	{
		textField.placeholder = [[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"ADD_EXCEPTION_ALERT_PLACEHOLDER"];
		textField.textColor = [UIColor blackColor];
		textField.keyboardType = UIKeyboardTypeURL;
		textField.clearButtonMode = UITextFieldViewModeWhileEditing;
		textField.borderStyle = UITextBorderStyleNone;
	}];

	[addExceptionAlert addAction:[UIAlertAction actionWithTitle:[[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"CANCEL"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *cancelAction)
	{
		[addExceptionAlert dismissViewControllerAnimated:YES completion:nil];
	}]];

	[addExceptionAlert addAction:[UIAlertAction actionWithTitle:[[SPPreferenceLocalizationManager sharedInstance] localizedSPStringForKey:@"ADD"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *addAction)
	{
		UITextField * URLField = addExceptionAlert.textFields[0];

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

	[self presentViewController:addExceptionAlert animated:YES completion:nil];
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
	return @[@1, @2];
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
	return @[@1, @2];
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
	return @[@1, @2, @3, @4];
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
	return @[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10];
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

- (void)desktopButtonLink
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://icons8.com/icon/1345/workstation"]];
}

- (void)deviceButtonLink
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://icons8.com/icon/79/iphone"]];
}

- (void)LockGlyphXRepoLink
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/evilgoldfish/LockGlyphX"]];
}

- (void)LockGlyphXFileLink
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/evilgoldfish/LockGlyphX/blob/master/Prefs/LockGlyphXPrefs.mm"]];
}

- (void)WatusiLink
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.reddit.com/r/jailbreak/comments/6f7zdn/release_watusi_2_your_allinone_tweak_for_whatsapp/"]];
}

@end
