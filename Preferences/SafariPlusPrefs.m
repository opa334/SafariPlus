//  SafariPlusPrefs.m
//  Preference bundle for SafariPlus

// (c) 2017 opa334

#import "SafariPlusPrefs.h"
#import "../LGShared.xm"

@implementation SafariPlusRootListController

- (NSArray *)specifiers
{
	if(!_specifiers)
	{
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}
	[LGShared parseSpecifiers:_specifiers];
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
	[LGShared parseSpecifiers:_specifiers];
	[(UINavigationItem *)self.navigationItem setTitle:[LGShared localisedStringForKey:@"GENERAL"]];
	return _specifiers;
}

@end

@implementation ExceptionsController

- (NSArray *)specifiers
{
	if(!_specifiers)
	{
		if(!plist)
		{
			plist = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
		}

		if(![[plist allKeys] containsObject:@"ForceHTTPSExceptions"])
		{
			ForceHTTPSExceptions = [NSMutableArray new];
			[plist setObject:ForceHTTPSExceptions forKey:@"ForceHTTPSExceptions"];
			[plist writeToFile:plistPath atomically:YES];
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

		for(int i = 0; i < [ForceHTTPSExceptions count]; i++)
		{
			PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:ForceHTTPSExceptions[i]
									target:self
										set:@selector(setPreferenceValue:specifier:)
										get:@selector(readPreferenceValue:)
									detail:nil
										cell:PSStaticTextCell
										edit:nil];

			[specifier setProperty:@YES forKey:@"enabled"];

			[specifiers addObject:specifier];
		}

		PSSpecifier* space = [PSSpecifier preferenceSpecifierNamed:@""
								target:self
									set:nil
									get:nil
								detail:nil
									cell:PSGroupCell
									edit:nil];

		PSSpecifier* addButton = [PSSpecifier preferenceSpecifierNamed:[LGShared localisedStringForKey:@"ADD"]
								target:self
									set:@selector(setPreferenceValue:specifier:)
									get:@selector(readPreferenceValue:)
								detail:nil
									cell:PSButtonCell
									edit:nil];

		[addButton setProperty:@YES forKey:@"enabled"];
		[addButton setButtonAction:@selector(addButtonPressed)];

		[specifiers addObject:space];
		[specifiers addObject:addButton];

		_specifiers = (NSArray*)[specifiers copy];
	}

	[(UINavigationItem *)self.navigationItem setTitle:[LGShared localisedStringForKey:@"FORCE_HTTPS_EXCEPTIONS_TITLE"]];
	return _specifiers;
}

- (void)addButtonPressed
{
	UIAlertController * addExceptionAlert = [UIAlertController alertControllerWithTitle:[LGShared localisedStringForKey:@"ADD_EXCEPTION_ALERT_TITLE"]
											message:[LGShared localisedStringForKey:@"ADD_EXCEPTION_ALERT_MESSAGE"]
											preferredStyle:UIAlertControllerStyleAlert];

	[addExceptionAlert addTextFieldWithConfigurationHandler:^(UITextField *textField)
	{
		textField.placeholder = [LGShared localisedStringForKey:@"ADD_EXCEPTION_ALERT_PLACEHOLDER"];
		textField.textColor = [UIColor blueColor];
		textField.clearButtonMode = UITextFieldViewModeWhileEditing;
		textField.borderStyle = UITextBorderStyleRoundedRect;
	}];

	[addExceptionAlert addAction:[UIAlertAction actionWithTitle:[LGShared localisedStringForKey:@"CANCEL"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *cancelAction)
	{
		[addExceptionAlert dismissViewControllerAnimated:YES completion:nil];
	}]];

	[addExceptionAlert addAction:[UIAlertAction actionWithTitle:[LGShared localisedStringForKey:@"ADD"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *addAction)
	{
        UITextField * URLField = addExceptionAlert.textFields[0];

				[ForceHTTPSExceptions addObject:URLField.text];
				[plist setObject:ForceHTTPSExceptions forKey:@"ForceHTTPSExceptions"];
				[plist writeToFile:plistPath atomically:YES];

				PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:URLField.text
										target:self
											set:@selector(setPreferenceValue:specifier:)
											get:@selector(readPreferenceValue:)
										detail:nil
											cell:PSStaticTextCell
											edit:nil];

				[specifier setProperty:@YES forKey:@"enabled"];

				[[NSNotificationCenter defaultCenter] postNotificationName:@"com.opa334.safariplusprefs/ReloadExceptions" object:nil];

				[self insertSpecifier:specifier atEndOfGroup:0 animated:YES];
  }]];

	[self presentViewController:addExceptionAlert animated:YES completion:nil];
}

- (id)_editButtonBarItem
{
	return nil;
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
	[plist writeToFile:plistPath atomically:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"com.opa334.safariplusprefs/ReloadExceptions" object:nil];
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
	[LGShared parseSpecifiers:_specifiers];
	[(UINavigationItem *)self.navigationItem setTitle:[LGShared localisedStringForKey:@"ACTION_ADDONS"]];
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
		titles[i] = [LGShared localisedStringForKey:titles[i]];
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
		titles[i] = [LGShared localisedStringForKey:titles[i]];
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
		titles[i] = [LGShared localisedStringForKey:titles[i]];
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
	[LGShared parseSpecifiers:_specifiers];
	[(UINavigationItem *)self.navigationItem setTitle:[LGShared localisedStringForKey:@"GESTURE_ADDONS"]];
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
		titles[i] = [LGShared localisedStringForKey:titles[i]];
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
	[LGShared parseSpecifiers:_specifiers];
	[(UINavigationItem *)self.navigationItem setTitle:[LGShared localisedStringForKey:@"OTHER_ADDONS"]];
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
	[LGShared parseSpecifiers:_specifiers];
	[(UINavigationItem *)self.navigationItem setTitle:[LGShared localisedStringForKey:@"COLOR_SETTINGS"]];
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
	[LGShared parseSpecifiers:_specifiers];
	[(UINavigationItem *)self.navigationItem setTitle:[LGShared localisedStringForKey:@"NORMAL_MODE"]];
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
	[LGShared parseSpecifiers:_specifiers];
	[(UINavigationItem *)self.navigationItem setTitle:[LGShared localisedStringForKey:@"PRIVATE_MODE"]];
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
	[LGShared parseSpecifiers:_specifiers];
	[(UINavigationItem *)self.navigationItem setTitle:[LGShared localisedStringForKey:@"CREDITS"]];
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

- (void)fileLink
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://icons8.com/icon/11651/file"]];
}

- (void)directoryLink
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://icons8.com/icon/843/file"]];
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
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.reddit.com/r/jailbreak/comments/57fgpf/release_discussion_watusi_2_the_ultimate_whatsapp/"]];
}

@end
