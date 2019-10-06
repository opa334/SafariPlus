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

#import "SPPBottomToolbarReorderingListController.h"
#import "../MobileSafari/Enums.h"
#import "SafariPlusPrefs.h"
#import "Extensions.h"

@interface UIBarButtonItem (Private)
+ (void)_getSystemItemStyle:(NSInteger*)arg1 title:(id*)arg2 image:(UIImage**)arg3 selectedImage:(UIImage**)arg4 action:(SEL*)arg5 forBarStyle:(NSInteger)arg6 landscape:(BOOL)arg7 alwaysBordered:(BOOL)arg8 usingSystemItem:(NSInteger)arg9 usingItemStyle:(NSInteger)arg10;
@end

@interface UIImage (Private)
+ (UIImage*)ss_imageNamed:(NSString*)x;
+ (UIImage*)imageNamed:(id)arg1 inBundle:(id)arg2;
- (UIImage*)_flatImageWithColor:(UIColor*)color;
@end

@implementation SPPBottomToolbarReorderingListController

- (instancetype)init
{
	self = [super init];

	_toolbarOrderSpecifier = [PSSpecifier preferenceSpecifierNamed:[self specifierName]
				  target:self
				  set:nil
				  get:nil
				  detail:nil
				  cell:nil
				  edit:nil];

	[_toolbarOrderSpecifier setProperty:@"com.opa334.safariplusprefs" forKey:@"defaults"];
	[_toolbarOrderSpecifier setProperty:[self specifierName] forKey:@"key"];
	[_toolbarOrderSpecifier setProperty:@"com.opa334.safariplusprefs/ReloadPrefs" forKey:@"PostNotification"];

	NSMutableArray* allItems = [NSMutableArray new];

	for(NSInteger i = BrowserToolbarBackItem; i < BrowserToolbarItemCount; i++)
	{
		if(![self searchBarIncluded] && i == BrowserToolbarSearchBarSpace)
		{
			continue;
		}

		[allItems addObject:@(i)];
	}

	_allItems = [allItems copy];

	[self loadOrder];

	if(!_enabledItems)
	{
		_enabledItems = [[self defaultOrder] mutableCopy];
	}

	_disabledItems = [NSMutableArray new];

	for(NSNumber* item in _allItems)
	{
		if(![_enabledItems containsObject:item])
		{
			[_disabledItems addObject:item];
		}
	}

	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	UITableView* tableView = [self valueForKey:@"_table"];
	[tableView setEditing:YES animated:NO];
}

- (NSArray*)specifiers
{
	if(!_specifiers)
	{
		_specifiers = [NSMutableArray new];

		PSSpecifier* enabledGroup = [PSSpecifier preferenceSpecifierNamed:[localizationManager localizedSPStringForKey:@"ENABLED_ITEMS"]
					     target:self
					     set:nil
					     get:nil
					     detail:nil
					     cell:PSGroupCell
					     edit:nil];

		[_specifiers addObject:enabledGroup];

		for(NSNumber* item in _enabledItems)
		{
			NSString* name = [self nameForItem:[item intValue]];

			PSSpecifier* itemSpecifier = [PSSpecifier preferenceSpecifierNamed:name
						      target:self
						      set:nil
						      get:nil
						      detail:nil
						      cell:PSStaticTextCell
						      edit:nil];

			[itemSpecifier setProperty:@YES forKey:@"enabled"];
			[itemSpecifier setProperty:item forKey:@"itemNumber"];

			[_specifiers addObject:itemSpecifier];
		}

		PSSpecifier* disabledGroup = [PSSpecifier preferenceSpecifierNamed:[localizationManager localizedSPStringForKey:@"DISABLED_ITEMS"]
					      target:self
					      set:nil
					      get:nil
					      detail:nil
					      cell:PSGroupCell
					      edit:nil];

		[_specifiers addObject:disabledGroup];

		for(NSNumber* item in _disabledItems)
		{
			NSString* name = [self nameForItem:[item intValue]];

			PSSpecifier* itemSpecifier = [PSSpecifier preferenceSpecifierNamed:name
						      target:self
						      set:nil
						      get:nil
						      detail:nil
						      cell:PSStaticTextCell
						      edit:nil];

			[itemSpecifier setProperty:@YES forKey:@"enabled"];
			[itemSpecifier setProperty:item forKey:@"itemNumber"];

			[_specifiers addObject:itemSpecifier];
		}
	}

	[(UINavigationItem *)self.navigationItem setTitle:[self title]];

	return _specifiers;
}

- (NSString*)title
{
	return [localizationManager localizedSPStringForKey:@"BOTTOM_TOOLBAR_ORDER"];
}

- (NSString*)specifierName
{
	return @"bottomToolbarCustomOrder";
}

- (BOOL)searchBarIncluded
{
	return NO;
}

- (NSString*)nameForItem:(NSInteger)item
{
	switch(item)
	{
	case BrowserToolbarBackItem:
		return [localizationManager localizedSPStringForKey:@"BACK"];

	case BrowserToolbarForwardItem:
		return [localizationManager localizedSPStringForKey:@"FORWARD"];

	case BrowserToolbarBookmarksItem:
		return [localizationManager localizedSPStringForKey:@"BOOKMARKS"];

	case BrowserToolbarShareItem:
		return [localizationManager localizedSPStringForKey:@"SHARE"];

	case BrowserToolbarAddTabItem:
		return [localizationManager localizedSPStringForKey:@"ADD_TAB"];

	case BrowserToolbarTabExposeItem:
		return [localizationManager localizedSPStringForKey:@"TABS"];

	case BrowserToolbarSearchBarSpace:
		return [localizationManager localizedSPStringForKey:@"SEARCH_BAR_SPACE"];

	case BrowserToolbarDownloadsItem:
		return [localizationManager localizedSPStringForKey:@"DOWNLOADS"];

	case BrowserToolbarReloadItem:
		return [localizationManager localizedSPStringForKey:@"RELOAD"];

	case BrowserToolbarClearDataItem:
		return [localizationManager localizedSPStringForKey:@"CLEAR_HISTORY"];

	default:
		return @"";
	}
}

- (UIImage*)imageForItem:(NSInteger)item
{
	if(!_imageByItem)
	{
		_imageByItem = [NSMutableDictionary new];

		for(NSNumber* itemNumber in _allItems)
		{
			UIImage* itemImage;

			switch([itemNumber intValue])
			{
			case BrowserToolbarBackItem:
			{
				[UIBarButtonItem _getSystemItemStyle:nil title:nil image:&itemImage selectedImage:nil action:nil forBarStyle:0 landscape:NO alwaysBordered:NO usingSystemItem:101 usingItemStyle:0];
				break;
			}

			case BrowserToolbarForwardItem:
			{
				[UIBarButtonItem _getSystemItemStyle:nil title:nil image:&itemImage selectedImage:nil action:nil forBarStyle:0 landscape:NO alwaysBordered:NO usingSystemItem:102 usingItemStyle:0];
				break;
			}

			case BrowserToolbarBookmarksItem:
			{
				[UIBarButtonItem _getSystemItemStyle:nil title:nil image:&itemImage selectedImage:nil action:nil forBarStyle:0 landscape:NO alwaysBordered:NO usingSystemItem:11 usingItemStyle:0];
				break;
			}

			case BrowserToolbarShareItem:
			{
				[UIBarButtonItem _getSystemItemStyle:nil title:nil image:&itemImage selectedImage:nil action:nil forBarStyle:0 landscape:NO alwaysBordered:NO usingSystemItem:9 usingItemStyle:0];
				break;
			}

			case BrowserToolbarAddTabItem:
			{
				itemImage = [UIImage imageNamed:@"AddTab" inBundle:MSBundle];
				if(!itemImage)
				{
					itemImage = [UIImage imageNamed:@"AddTab" inBundle:SSBundle];
				}
				break;
			}

			case BrowserToolbarTabExposeItem:
			{
				itemImage = [UIImage imageNamed:@"TabButton" inBundle:MSBundle];
				if(!itemImage)
				{
					itemImage = [UIImage imageNamed:@"TabButton" inBundle:SSBundle];
				}
				break;
			}

			case BrowserToolbarSearchBarSpace:
			{
				itemImage = [UIImage imageNamed:@"SearchBarSpace" inBundle:SPBundle compatibleWithTraitCollection:nil];
				break;
			}

			case BrowserToolbarDownloadsItem:
			{
				itemImage = [UIImage imageNamed:@"DownloadsButton" inBundle:SPBundle compatibleWithTraitCollection:nil];
				break;
			}

			case BrowserToolbarReloadItem:
			{
				[UIBarButtonItem _getSystemItemStyle:nil title:nil image:&itemImage selectedImage:nil action:nil forBarStyle:0 landscape:NO alwaysBordered:NO usingSystemItem:UIBarButtonSystemItemRefresh usingItemStyle:0];
				break;
			}

			case BrowserToolbarClearDataItem:
			{
				[UIBarButtonItem _getSystemItemStyle:nil title:nil image:&itemImage selectedImage:nil action:nil forBarStyle:0 landscape:NO alwaysBordered:NO usingSystemItem:UIBarButtonSystemItemTrash usingItemStyle:0];
				break;
			}
			}

			if(itemImage)
			{
				itemImage = [itemImage _flatImageWithColor:self.view.tintColor];

				if(itemImage.size.width < 25)
				{
					itemImage = [itemImage imageWithWidth:25 alignment:0];
				}

				[_imageByItem setObject:itemImage forKey:itemNumber];
			}
		}
	}

	return [_imageByItem objectForKey:@(item)];
}

- (NSArray*)defaultOrder
{
	return @[@(BrowserToolbarBackItem), @(BrowserToolbarForwardItem), @(BrowserToolbarShareItem), @(BrowserToolbarBookmarksItem), @(BrowserToolbarTabExposeItem)];
}

- (id)_editButtonBarItem
{
	return nil;
}

- (PSTableCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	PSTableCell* cell = (PSTableCell*)[super tableView:tableView cellForRowAtIndexPath:indexPath];

	PSSpecifier* specifier = cell.specifier;

	NSNumber* itemNumber = [specifier propertyForKey:@"itemNumber"];

	UIImage* image = [self imageForItem:[itemNumber intValue]];

	cell.imageView.image = image;
	cell.separatorInset = UIEdgeInsetsMake(0,0,0,0);

	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

- (BOOL)tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath*)indexPath
{
	return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == 0)
	{
		return UITableViewCellEditingStyleDelete;
	}
	else if(indexPath.section == 1)
	{
		return UITableViewCellEditingStyleInsert;
	}
	else
	{
		return UITableViewCellEditingStyleNone;
	}
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
	if(sourceIndexPath.section == 0 && destinationIndexPath.section == 0)
	{
		NSNumber* item = [_enabledItems objectAtIndex:sourceIndexPath.row];
		[_enabledItems removeObjectAtIndex:sourceIndexPath.row];
		[_enabledItems insertObject:item atIndex:destinationIndexPath.row];
	}
	else if(sourceIndexPath.section == 0 && destinationIndexPath.section == 1)
	{
		NSNumber* item = [_enabledItems objectAtIndex:sourceIndexPath.row];
		[_enabledItems removeObjectAtIndex:sourceIndexPath.row];
		[_disabledItems insertObject:item atIndex:destinationIndexPath.row];
	}
	else if(sourceIndexPath.section == 1 && destinationIndexPath.section == 0)
	{
		NSNumber* item = [_disabledItems objectAtIndex:sourceIndexPath.row];
		[_disabledItems removeObjectAtIndex:sourceIndexPath.row];
		[_enabledItems insertObject:item atIndex:destinationIndexPath.row];
	}

	[self reloadSpecifiers];
	[self saveOrder];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == 0)
	{
		NSIndexPath* disabledIndexPath = [self disabledIndexPathForEnabledItemAtIndexPath:indexPath];
		NSNumber* affectedItem = [_enabledItems objectAtIndex:indexPath.row];
		[_enabledItems removeObjectAtIndex:indexPath.row];
		[_disabledItems insertObject:affectedItem atIndex:disabledIndexPath.row];
		PSSpecifier* specifier = [self specifierAtIndex:[self indexForIndexPath:indexPath]];
		[self removeSpecifierAtIndex:[self indexForIndexPath:indexPath] animated:YES];
		[self insertSpecifier:specifier atIndex:[self indexForIndexPath:disabledIndexPath] animated:YES];
	}
	else if(indexPath.section == 1)
	{
		NSIndexPath* enabledIndexPath = [NSIndexPath indexPathForRow:_enabledItems.count inSection:0];
		NSNumber* affectedItem = [_disabledItems objectAtIndex:indexPath.row];
		[_disabledItems removeObjectAtIndex:indexPath.row];
		[_enabledItems insertObject:affectedItem atIndex:enabledIndexPath.row];
		PSSpecifier* specifier = [self specifierAtIndex:[self indexForIndexPath:indexPath]];
		[self removeSpecifierAtIndex:[self indexForIndexPath:indexPath] animated:YES];
		[self insertSpecifier:specifier atIndex:[self indexForIndexPath:enabledIndexPath] animated:YES];
	}

	[self saveOrder];
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
	if(proposedDestinationIndexPath.section == 0)
	{
		return proposedDestinationIndexPath;
	}
	else if(proposedDestinationIndexPath.section == 1)
	{
		return [self disabledIndexPathForEnabledItemAtIndexPath:sourceIndexPath];
	}

	return nil;
}

- (NSIndexPath*)disabledIndexPathForEnabledItemAtIndexPath:(NSIndexPath*)indexPath
{
	PSSpecifier* sourceSpecifier = [self specifierAtIndexPath:indexPath];
	NSNumber* itemNumber = [sourceSpecifier propertyForKey:@"itemNumber"];

	if([_disabledItems containsObject:itemNumber])
	{
		return indexPath;
	}

	for(NSNumber* item in _disabledItems)
	{
		if([itemNumber intValue] < [item intValue])
		{
			return [NSIndexPath indexPathForRow:[_disabledItems indexOfObject:item] inSection:1];
		}
	}

	return [NSIndexPath indexPathForRow:_disabledItems.count inSection:1];
}

- (void)saveOrder
{
	[self setPreferenceValue:[_enabledItems copy] specifier:_toolbarOrderSpecifier];
}

- (void)loadOrder
{
	_enabledItems = [(NSArray*)[self readPreferenceValue:_toolbarOrderSpecifier] mutableCopy];
}

- (void)suspend { };	//This method turns the UITableView back into non-editing mode if the app is minimized, so we prevent it

@end
