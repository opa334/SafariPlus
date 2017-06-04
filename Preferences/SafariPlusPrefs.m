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
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
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
		_specifiers = [[self loadSpecifiersFromPlistName:@"GeneralPrefs" target:self] retain];
	}
	[LGShared parseSpecifiers:_specifiers];
	[(UINavigationItem *)self.navigationItem setTitle:[LGShared localisedStringForKey:@"GENERAL"]];
	return _specifiers;
}

@end

@implementation ActionPrefsController

- (NSArray *)specifiers
{
	if(!_specifiers)
	{
		_specifiers = [[self loadSpecifiersFromPlistName:@"ActionPrefs" target:self] retain];
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
		_specifiers = [[self loadSpecifiersFromPlistName:@"GesturePrefs" target:self] retain];
	}
	[LGShared parseSpecifiers:_specifiers];
	[(UINavigationItem *)self.navigationItem setTitle:[LGShared localisedStringForKey:@"GESTURE_ADDONS"]];
	return _specifiers;
}

- (NSArray *)gestureActionValues
{
	return @[@1, @2, @3, @4, @5];
}

- (NSArray *)gestureActionTitles
{
	NSMutableArray* titles = [@[@"CLOSE_ACTIVE_TAB", @"OPEN_NEW_TAB", @"DUPLICATE_ACTIVE_TAB", @"CLOSE_ALL_TABS", @"SWITCH_MODE"] mutableCopy];
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
		_specifiers = [[self loadSpecifiersFromPlistName:@"OtherPrefs" target:self] retain];
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
		_specifiers = [[self loadSpecifiersFromPlistName:@"ColorPrefs" target:self] retain];
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
		_specifiers = [[self loadSpecifiersFromPlistName:@"NormalColorPrefs" target:self] retain];
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
		_specifiers = [[self loadSpecifiersFromPlistName:@"PrivateColorPrefs" target:self] retain];
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
		_specifiers = [[self loadSpecifiersFromPlistName:@"Credits" target:self] retain];
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
