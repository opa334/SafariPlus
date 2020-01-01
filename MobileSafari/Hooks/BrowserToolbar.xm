// Copyright (c) 2017-2020 Lars Fröder

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

#import "../SafariPlus.h"
#import "Extensions.h"

#import "../Classes/SPPreferenceManager.h"
#import "../Classes/SPDownloadsBarButtonItem.h"
#import "../Defines.h"
#import "../Util.h"
#import "../Enums.h"
#import "substrate.h"

#define tSelf ((BrowserToolbar*)self)

static void updateToolbarConnectionWithBarButtonItem(__kindof UIBarButtonItem* item, BrowserToolbar* toolbar, NSInteger itemValue)
{
	id target;

	if(NSClassFromString(@"SFBarRegistration"))
	{
		target = MSHookIvar<id>(toolbar, "_barRegistration");
	}
	else
	{
		target = toolbar;
	}

	NSArray* recognizers;

	if([item respondsToSelector:@selector(gestureRecognizer)])
	{
		recognizers = @[((GestureRecognizingBarButtonItem*)item).gestureRecognizer];
	}
	else if([item respondsToSelector:@selector(_gestureRecognizers)])
	{
		recognizers = [item _gestureRecognizers];
	}

	for(UIGestureRecognizer* recognizer in recognizers)
	{
		if([recognizer isKindOfClass:[NSClassFromString(@"SFBarButtonItemLongPressGestureRecognizer") class]])
		{
			if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_3)
			{
				[recognizer setValue:item forKey:@"_barButtonItem"];
			}

			if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_12_0)
			{
				[recognizer setValue:target forKey:@"_target"];
			}
			else
			{
				[recognizer setValue:target forKey:@"_longPressTarget"];
			}
		}
		else
		{
			NSMutableArray* targets = MSHookIvar<NSMutableArray*>(recognizer, "_targets");
			for(id recognizerTarget in targets)
			{
				[recognizerTarget setValue:target forKey:@"_target"];
			}
		}
	}

	switch(itemValue)
	{
		case BrowserToolbarBackItem:
		[target setValue:item forKey:@"_backItem"];
		break;

		case BrowserToolbarForwardItem:
		[target setValue:item forKey:@"_forwardItem"];
		break;

		case BrowserToolbarBookmarksItem:
		[target setValue:item forKey:@"_bookmarksItem"];
		break;

		case BrowserToolbarShareItem:
		{
			if(NSClassFromString(@"SFBarRegistration"))
			{
				[target setValue:item forKey:@"_shareItem"];
			}
			else
			{
				[target setValue:item forKey:@"_actionItem"];
			}
			break;
		}

		case BrowserToolbarAddTabItem:
		[target setValue:item forKey:@"_addTabItem"];
		break;

		case BrowserToolbarTabExposeItem:
		[target setValue:item forKey:@"_tabExposeItem"];
		break;

		case BrowserToolbarDownloadsItem:
		toolbar._downloadsItem = item;
		break;

		case BrowserToolbarReloadItem:
		toolbar._reloadItem = item;
		break;

		case BrowserToolbarClearDataItem:
		toolbar._clearDataItem = item;
		break;
	}
}

//Turns a system bar button item into a non-system one
//Needed because system items act weird and can't be modified that easily
static __kindof UIBarButtonItem* unsystemifiedBarButtonItem(__kindof UIBarButtonItem* oldItem, CGFloat width, NSInteger alignment)
{
	UIImage* itemImage;
	[UIBarButtonItem _getSystemItemStyle:nil title:nil image:&itemImage selectedImage:nil action:nil forBarStyle:0 landscape:NO alwaysBordered:NO usingSystemItem:oldItem.systemItem usingItemStyle:0];

	UIImage* newImage = [itemImage imageWithWidth:width alignment:alignment];

	UIBarButtonItem* newItem = [[(__kindof UIBarButtonItem*)[oldItem class] alloc] initWithImage:newImage style:UIBarButtonItemStylePlain target:oldItem.target action:oldItem.action];

	if([newItem respondsToSelector:@selector(setGestureRecognizer:)])
	{
		[((GestureRecognizingBarButtonItem*)newItem) setGestureRecognizer:((GestureRecognizingBarButtonItem*)oldItem).gestureRecognizer];
	}
	else if([newItem respondsToSelector:@selector(_setGestureRecognizers:)])
	{
		newItem._sf_longPressEnabled = oldItem._sf_longPressEnabled;
		newItem._gestureRecognizers = oldItem._gestureRecognizers;
	}

	newItem.imageInsets = UIEdgeInsetsMake(oldItem.imageInsets.top, 0, oldItem.imageInsets.bottom, 0);
	newItem.enabled = oldItem.enabled;

	return newItem;
}

@interface BrowserToolbar (FullSafari)
@property (nonatomic, retain) UIBarButtonItem *addTabItemManual;
@end

%hook BrowserToolbar

%property (nonatomic,retain) UIBarButtonItem *_downloadsItem;
%property (nonatomic,retain) UIBarButtonItem *_reloadItem;
%property (nonatomic,retain) UIBarButtonItem *_clearDataItem;
%property (nonatomic,retain) UILabel *tabCountLabel;
%property (nonatomic,retain) UIImage *tabExposeImage;
%property (nonatomic,retain) UIImage *tabExposeImageWithCount;

- (instancetype)initWithPlacement:(NSInteger)placement
{
	self = %orig;

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0)
	{
		NSMutableArray* usedOrder;

		if(placement == 1 && preferenceManager.bottomToolbarCustomOrderEnabled && preferenceManager.bottomToolbarCustomOrder)
		{
			usedOrder = [preferenceManager.bottomToolbarCustomOrder mutableCopy];
		}

		if(placement == 0 && preferenceManager.topToolbarCustomOrderEnabled && preferenceManager.topToolbarCustomOrder)
		{
			usedOrder = [preferenceManager.topToolbarCustomOrder mutableCopy];
		}

		NSNumber* downloadsItemNum = @(BrowserToolbarDownloadsItem);
		if([usedOrder containsObject:downloadsItemNum] && !preferenceManager.downloadManagerEnabled)
		{
			[usedOrder removeObject:downloadsItemNum];
		}

		UIImageSymbolConfiguration* symbolConfiguration = [%c(UIImageSymbolConfiguration) configurationWithTextStyle:UIFontTextStyleBody scale:UIImageSymbolScaleLarge];
        symbolConfiguration = [symbolConfiguration configurationWithTraitCollection:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:UIContentSizeCategoryMedium]];


		if(usedOrder)
		{
			if([usedOrder containsObject:downloadsItemNum])
			{
				if(preferenceManager.previewDownloadProgressEnabled)
				{
					tSelf._downloadsItem = [[SPDownloadsBarButtonItem alloc] initWithTarget:self action:@selector(_itemReceivedTap:) placement:placement];
				}
				else
				{
					tSelf._downloadsItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"arrow.down.circle" withConfiguration:symbolConfiguration] style:UIBarButtonItemStylePlain target:nil action:@selector(_itemReceivedTap:)];

					if(placement != 0)
					{
						[tSelf._downloadsItem _setWidth:60];
					}
				}
			}

			NSNumber* reloadItemNum = @(BrowserToolbarReloadItem);
			if([usedOrder containsObject:reloadItemNum])
			{
				tSelf._reloadItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"arrow.clockwise" withConfiguration:symbolConfiguration] style:UIBarButtonItemStylePlain target:nil action:@selector(_itemReceivedTap:)];
				if(placement != 0)
				{
					[tSelf._reloadItem _setWidth:60];
				}
			}

			NSNumber* clearDataItemNum = @(BrowserToolbarClearDataItem);
			if([usedOrder containsObject:clearDataItemNum])
			{
				tSelf._clearDataItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"trash" withConfiguration:symbolConfiguration] style:UIBarButtonItemStylePlain target:nil action:@selector(_itemReceivedTap:)];
				if(placement != 0)
				{
					[tSelf._clearDataItem _setWidth:60];
				}
			}
		}
		else if(preferenceManager.downloadManagerEnabled)
		{
			if(preferenceManager.previewDownloadProgressEnabled)
			{
				tSelf._downloadsItem = [[SPDownloadsBarButtonItem alloc] initWithTarget:self action:@selector(_itemReceivedTap:) placement:placement];
			}
			else
			{
				tSelf._downloadsItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"arrow.down.circle" withConfiguration:symbolConfiguration] style:UIBarButtonItemStylePlain target:nil action:@selector(_itemReceivedTap:)];

				if(placement != 0)
				{
					[tSelf._downloadsItem _setWidth:60];
				}
			}
		}
	}

	if(preferenceManager.showTabCountEnabled)
	{
		tSelf.tabCountLabel = [[UILabel alloc] init];
		tSelf.tabCountLabel.adjustsFontSizeToFitWidth = YES;
		tSelf.tabCountLabel.minimumFontSize = 0;
		tSelf.tabCountLabel.numberOfLines = 1;
		tSelf.tabCountLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		tSelf.tabCountLabel.textAlignment = NSTextAlignmentCenter;
		if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0)
		{
			//tSelf.tabCountLabel.frame = CGRectMake(8.25,7,14.5,14.5);
			if([UIScreen mainScreen].scale >= 3)
			{
				tSelf.tabCountLabel.frame = CGRectMake(9,7.66,13,13);
			}
			else
			{
				tSelf.tabCountLabel.frame = CGRectMake(9,8,13,13);
			}
		}
		else
		{
			tSelf.tabCountLabel.frame = CGRectMake(2.25,6.5,14.75,17.25);
		}
		tSelf.tabCountLabel.textColor = [UIColor blackColor];
	}

	if(preferenceManager.toolbarLeftSwipeGestureEnabled || preferenceManager.toolbarRightSwipeGestureEnabled || preferenceManager.toolbarUpDownSwipeGestureEnabled)
	{
		if(preferenceManager.toolbarLeftSwipeGestureEnabled)
		{
			UISwipeGestureRecognizer* swipeLeftRecognizer = [[UISwipeGestureRecognizer alloc]
									 initWithTarget:self action:@selector(toolbarWasSwiped:)];

			swipeLeftRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;

			[self addGestureRecognizer:swipeLeftRecognizer];
		}

		if(preferenceManager.toolbarRightSwipeGestureEnabled)
		{
			UISwipeGestureRecognizer* swipeRightRecognizer = [[UISwipeGestureRecognizer alloc]
									  initWithTarget:self action:@selector(toolbarWasSwiped:)];

			swipeRightRecognizer.direction = UISwipeGestureRecognizerDirectionRight;

			[self addGestureRecognizer:swipeRightRecognizer];
		}

		if(preferenceManager.toolbarUpDownSwipeGestureEnabled)
		{
			UISwipeGestureRecognizer* swipeUpDownRecognizer = [[UISwipeGestureRecognizer alloc]
									   initWithTarget:self action:@selector(toolbarWasSwiped:)];

			if(placement)
			{
				swipeUpDownRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
			}
			else
			{
				swipeUpDownRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
			}

			[self addGestureRecognizer:swipeUpDownRecognizer];
		}
	}

	return self;
}

%new
- (void)toolbarWasSwiped:(UISwipeGestureRecognizer*)swipe
{
	if([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive)
	{
		//CC or NC was invoked
		return;
	}

	BrowserController* browserController = browserControllerForBrowserToolbar(self);

	if(browserControllerIsShowingTabView(browserController) && !preferenceManager.gesturesInTabSwitcherEnabled)
	{
		return;
	}

	switch(swipe.direction)
	{
	case UISwipeGestureRecognizerDirectionLeft:
	{
		//Toolbar swiped left -> handle swipe
		[browserController handleGesture:preferenceManager.toolbarLeftSwipeAction];
		break;
	}

	case UISwipeGestureRecognizerDirectionRight:
	{
		//Toolbar swiped right -> handle swipe
		[browserController handleGesture:preferenceManager.toolbarRightSwipeAction];
		break;
	}

	case UISwipeGestureRecognizerDirectionDown:
	case UISwipeGestureRecognizerDirectionUp:
	{
		//Toolbar swiped up or down -> handle swipe
		[browserController handleGesture:preferenceManager.toolbarUpDownSwipeAction];
		break;
	}
	}
}

//Correctly enable / disable downloads button when needed
- (void)setEnabled:(BOOL)arg1
{
	%orig;
	if(preferenceManager.downloadManagerEnabled)
	{
		[self setDownloadsEnabled:arg1];
	}
}

%new
- (void)setDownloadsEnabled:(BOOL)enabled
{
	[tSelf._downloadsItem setEnabled:enabled];
}

%new
- (NSMutableArray*)dynamicItemsForOrder:(NSArray*)order
{
	NSMutableArray* orderM = [order mutableCopy];

	if([orderM containsObject:@(BrowserToolbarDownloadsItem)] && !preferenceManager.downloadManagerEnabled)
	{
		[orderM removeObject:@(BrowserToolbarDownloadsItem)];
	}

	NSMutableDictionary* allItems = [NSMutableDictionary new];

	id target;

	if(NSClassFromString(@"SFBarRegistration"))
	{
		SFBarRegistration* barRegistration = MSHookIvar<SFBarRegistration*>(self, "_barRegistration");

		if([orderM containsObject:@(BrowserToolbarAddTabItem)] && !MSHookIvar<UIBarButtonItem*>(barRegistration, "_newTabItem"))
		{
			UIImage* newTabIcon;

			if([UIImage respondsToSelector:@selector(ss_imageNamed:)])
			{
				newTabIcon = [UIImage ss_imageNamed:@"AddTab"];
			}
			else
			{
				newTabIcon = [UIImage imageNamed:@"AddTab"];
			}

			UIBarButtonItem* newTabItem = [[UIBarButtonItem alloc] initWithImage:newTabIcon style:UIBarButtonItemStylePlain target:barRegistration action:@selector(_itemReceivedTap:)];

			if([newTabItem respondsToSelector:@selector(_sf_setLongPressTarget:action:)])
			{
				[newTabItem _sf_setLongPressTarget:barRegistration action:@selector(_itemReceivedLongPress:)];
			}
			else if([newTabItem respondsToSelector:@selector(_sf_setTarget:longPressAction:)])
			{
				[newTabItem _sf_setTarget:barRegistration longPressAction:@selector(_itemReceivedLongPress:)];
			}

			MSHookIvar<UIBarButtonItem*>(barRegistration, "_newTabItem") = newTabItem;
		}

		for(NSInteger i = BrowserToolbarBackItem; i <= BrowserToolbarTabExposeItem; i++)
		{
			addToDict(allItems, [barRegistration UIBarButtonItemForItem:i], [NSNumber numberWithInteger:i]);
		}

		target = barRegistration;
	}
	else
	{
		addToDict(allItems, MSHookIvar<UIBarButtonItem*>(self, "_backItem"), @(BrowserToolbarBackItem));
		addToDict(allItems, MSHookIvar<UIBarButtonItem*>(self, "_forwardItem"), @(BrowserToolbarForwardItem));
		addToDict(allItems, MSHookIvar<UIBarButtonItem*>(self, "_bookmarksItem"), @(BrowserToolbarBookmarksItem));
		addToDict(allItems, MSHookIvar<UIBarButtonItem*>(self, "_actionItem"), @(BrowserToolbarShareItem));
		if([orderM containsObject:@(BrowserToolbarAddTabItem)] && !MSHookIvar<UIBarButtonItem*>(self, "_addTabItem"))
		{
			UIBarButtonItem* addTabItem;

			if(NSClassFromString(@"GestureRecognizingBarButtonItem"))
			{
				addTabItem = [[%c(GestureRecognizingBarButtonItem) alloc] initWithImage:[UIImage imageNamed:@"AddTab"] style:UIBarButtonItemStylePlain target:browserControllerForBrowserToolbar(self) action:@selector(addTabFromButtonBar)];
				UILongPressGestureRecognizer* recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_addTabLongPressRecognized:)];
				recognizer.allowableMovement = 3.0;
				[((GestureRecognizingBarButtonItem*)addTabItem) setGestureRecognizer:recognizer];
			}
			else
			{
				addTabItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"AddTab"] style:UIBarButtonItemStylePlain target:browserControllerForBrowserToolbar(self) action:@selector(addTabFromButtonBar)];
				[addTabItem _sf_setLongPressTarget:self action:@selector(_addTabLongPressRecognized:)];
			}

			MSHookIvar<UIBarButtonItem*>(self, "_addTabItem") = addTabItem;
		}
		addToDict(allItems, MSHookIvar<UIBarButtonItem*>(self, "_addTabItem"), @(BrowserToolbarAddTabItem));
		if(!MSHookIvar<UIBarButtonItem*>(self, "_tabExposeItem"))	//needed on iOS 9 and below
		{
			MSHookIvar<UIBarButtonItem*>(self, "_tabExposeItem") = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"TabButton"] style:UIBarButtonItemStylePlain target:browserControllerForBrowserToolbar(self) action:@selector(showTabsFromButtonBar)];
		}
		addToDict(allItems, MSHookIvar<UIBarButtonItem*>(self, "_tabExposeItem"), @(BrowserToolbarTabExposeItem));

		target = self;
	}

	for(NSNumber* itemNumber in orderM)
	{
		NSInteger itemValue = [itemNumber integerValue];
		UIBarButtonItem* item = [allItems objectForKey:itemNumber];

		switch(itemValue)
		{
			case BrowserToolbarBackItem:
			case BrowserToolbarForwardItem:
			case BrowserToolbarShareItem:
			{
				if([item isSystemItem])
				{
					NSUInteger itemIndex = [orderM indexOfObject:itemNumber];

					NSInteger alignment = 0;

					if(itemIndex == 0)	//Align first button to the left
					{
						alignment = -1;
					}
					else if(itemIndex == orderM.count - 1)	//Align last button to the right
					{
						alignment = 1;
					}

					UIBarButtonItem* newItem = unsystemifiedBarButtonItem(item, 25, alignment);
					updateToolbarConnectionWithBarButtonItem(newItem, self, itemValue);

					addToDict(allItems, newItem, itemNumber);
				}

				break;
			}
			case BrowserToolbarBookmarksItem:
			case BrowserToolbarTabExposeItem:
			case BrowserToolbarAddTabItem:
			{
				if(item.image.size.width < 25)
				{
					item.image = [item.image imageWithWidth:25 alignment:0];
				}
				item.imageInsets = UIEdgeInsetsMake(item.imageInsets.top, 0, item.imageInsets.bottom, 0);
				break;
			}
			case BrowserToolbarDownloadsItem:
			{
				if(!tSelf._downloadsItem)
				{
					if(preferenceManager.previewDownloadProgressEnabled)
					{
						tSelf._downloadsItem = [[SPDownloadsBarButtonItem alloc] initWithTarget:browserControllerForBrowserToolbar(self) action:@selector(downloadsFromButtonBar)];
					}
					else
					{
						tSelf._downloadsItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"DownloadsButton" inBundle:SPBundle compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain target:browserControllerForBrowserToolbar(self) action:@selector(downloadsFromButtonBar)];
					}
				}

				addToDict(allItems, tSelf._downloadsItem, itemNumber);
				break;
			}
			case BrowserToolbarReloadItem:
			{
				UIImage* itemImage;
				[UIBarButtonItem _getSystemItemStyle:nil title:nil image:&itemImage selectedImage:nil action:nil forBarStyle:0 landscape:NO alwaysBordered:NO usingSystemItem:UIBarButtonSystemItemRefresh usingItemStyle:0];

				UIButton* reloadButton = [UIButton buttonWithType:UIButtonTypeSystem];

				if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0)
				{
					reloadButton.frame = CGRectMake(0,0,35,44);
				}
				else
				{
					reloadButton.frame = CGRectMake(0,0,25,25);
				}

				[reloadButton setImage:itemImage forState:UIControlStateNormal];
				[reloadButton addTarget:navigationBarForBrowserController(browserControllerForBrowserToolbar(self)) action:@selector(_reloadButtonPressed) forControlEvents:UIControlEventTouchUpInside];

				if([navigationBarForBrowserController(browserControllerForBrowserToolbar(self)) respondsToSelector:@selector(_reloadButtonLongPressed:)])
				{
					UILongPressGestureRecognizer* longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:navigationBarForBrowserController(browserControllerForBrowserToolbar(self)) action:@selector(_reloadButtonLongPressed:)];
					[reloadButton addGestureRecognizer:longPressGestureRecognizer];
				}

				tSelf._reloadItem = [[UIBarButtonItem alloc] initWithCustomView:reloadButton];

				addToDict(allItems, tSelf._reloadItem, itemNumber);
				break;
			}
			case BrowserToolbarClearDataItem:
			{
				UIImage* itemImage;
				[UIBarButtonItem _getSystemItemStyle:nil title:nil image:&itemImage selectedImage:nil action:nil forBarStyle:0 landscape:NO alwaysBordered:NO usingSystemItem:UIBarButtonSystemItemTrash usingItemStyle:0];

				if(itemImage.size.width < 25)
				{
					itemImage = [itemImage imageWithWidth:25 alignment:0];
				}

				tSelf._clearDataItem = [[UIBarButtonItem alloc] initWithImage:itemImage style:UIBarButtonItemStylePlain target:browserControllerForBrowserToolbar(self) action:@selector(clearData)];
				addToDict(allItems, tSelf._clearDataItem, itemNumber);
				break;
			}
		}
	}

	NSMutableArray* dynamicItems = [NSMutableArray new];

	UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

	if(MSHookIvar<NSInteger>(self, "_placement"))	//Bottom Toolbar
	{
		for(NSNumber* num in orderM)
		{
			if(![num isEqual:orderM.firstObject])
			{
				[dynamicItems addObject:flexibleSpace];
			}

			UIBarButtonItem* item = [allItems objectForKey:num];

			[dynamicItems addObject:item];
		}
	}
	else	//Top Toolbar with URL bar (No flexible spaces possible because the URL bar needs to always be in the middle)
	{
		CGFloat toolbarMargin = 20;	//20 left space

		UIWindow* window = [UIApplication sharedApplication].keyWindow;

		if([window respondsToSelector:@selector(_sf_bottomUnsafeAreaFrameForToolbar)])
		{
			if(window._sf_bottomUnsafeAreaFrameForToolbar.origin.x > toolbarMargin)
			{
				toolbarMargin = window._sf_bottomUnsafeAreaFrameForToolbar.origin.x;
			}
		}

		toolbarMargin += 20;	//20 right space

		CGFloat availableSpace = (tSelf.URLFieldHorizontalMargin - toolbarMargin);

		if(availableSpace > 150)
		{
			availableSpace = 150;
		}

		NSUInteger beforeBarCount = 0, afterBarCount = 0;
		NSArray *beforeBarOrder, *afterBarOrder;

		if([orderM containsObject:@(BrowserToolbarSearchBarSpace)])
		{
			beforeBarCount = [orderM indexOfObject:@(BrowserToolbarSearchBarSpace)];
			afterBarCount = orderM.count - beforeBarCount - 1;

			beforeBarOrder = [orderM subarrayWithRange:NSMakeRange(0,beforeBarCount)];
			afterBarOrder = [orderM subarrayWithRange:NSMakeRange(beforeBarCount+1,afterBarCount)];
		}
		else
		{
			beforeBarCount = [orderM count];
			beforeBarOrder = [orderM copy];
		}

		NSInteger spaceCountBefore = beforeBarCount;
		NSInteger spaceCountAfter = afterBarCount;

		if(beforeBarCount > 2)
		{
			spaceCountBefore--;
		}
		else if(beforeBarCount == 1)
		{
			spaceCountBefore++;
		}

		if(afterBarCount > 2)
		{
			spaceCountAfter--;
		}
		else if(afterBarCount == 1)
		{
			spaceCountAfter++;
		}

		UIBarButtonItem* beforeBarSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
		CGFloat beforeSpaceWidth = (availableSpace - (beforeBarCount * 25)) / spaceCountBefore;

		beforeSpaceWidth -= 10;	//Fixed space is always 10 points bigger than it should be

		if(beforeSpaceWidth < 0)
		{
			beforeSpaceWidth = 0;
		}

		[beforeBarSpace setWidth:beforeSpaceWidth];

		UIBarButtonItem* afterBarSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
		CGFloat afterSpaceWidth = (availableSpace - (afterBarCount * 25)) / spaceCountAfter;

		afterSpaceWidth -= 10;	//Fixed space is always 10 points bigger than it should be

		if(afterSpaceWidth < 0)
		{
			afterSpaceWidth = 0;
		}

		[afterBarSpace setWidth:afterSpaceWidth];

		for(NSNumber* itemNum in beforeBarOrder)
		{
			if(itemNum != beforeBarOrder.firstObject || beforeBarOrder.count <= spaceCountBefore)
			{
				[dynamicItems addObject:beforeBarSpace];
			}

			[dynamicItems addObject:[allItems objectForKey:itemNum]];
		}

		if(beforeBarOrder.count == 1)
		{
			[dynamicItems addObject:beforeBarSpace];
		}

		UIBarButtonItem* noSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
		[noSpace setWidth:0];
		[dynamicItems addObject:noSpace];
		[dynamicItems addObject:flexibleSpace];
		[dynamicItems addObject:noSpace];

		if(afterBarOrder.count == 1)
		{
			[dynamicItems addObject:afterBarSpace];
		}

		for(NSNumber* itemNum in afterBarOrder)
		{
			[dynamicItems addObject:[allItems objectForKey:itemNum]];

			if(itemNum != afterBarOrder.lastObject || afterBarOrder.count <= spaceCountAfter)
			{
				[dynamicItems addObject:afterBarSpace];
			}
		}
	}

	return dynamicItems;
}

- (NSMutableArray *)defaultItems
{
	if(preferenceManager.bottomToolbarCustomOrderEnabled || preferenceManager.topToolbarCustomOrderEnabled || preferenceManager.downloadManagerEnabled)
	{
		NSMutableDictionary* defaultItemsForToolbarSize = MSHookIvar<NSMutableDictionary*>(self, "_defaultItemsForToolbarSize");

		NSMutableArray* defaultItems = defaultItemsForToolbarSize[@(tSelf.toolbarSize)];

		NSInteger placement = MSHookIvar<NSInteger>(self, "_placement");

		if(!defaultItems)
		{
			if(placement && preferenceManager.bottomToolbarCustomOrderEnabled && preferenceManager.bottomToolbarCustomOrder)
			{
				defaultItems = [self dynamicItemsForOrder:preferenceManager.bottomToolbarCustomOrder];
			}
			else if(!placement && preferenceManager.topToolbarCustomOrderEnabled && preferenceManager.topToolbarCustomOrder)
			{
				defaultItems = [self dynamicItemsForOrder:preferenceManager.topToolbarCustomOrder];
			}
			else if(preferenceManager.downloadManagerEnabled)
			{
				if(placement)	//Bottom Bar
				{
					BOOL tabBarTweakActive = NO;

					if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_12_0)
					{
						tabBarTweakActive = [self respondsToSelector:@selector(addTabItemManual)];
					}
					else
					{
						if([browserControllerForBrowserToolbar(self) respondsToSelector:@selector(_shouldShowTabBar)])
						{
							tabBarTweakActive = [browserControllerForBrowserToolbar(self) _shouldShowTabBar] && [browserControllers() count] <= 1;
						}
						else
						{
							[browserControllerForBrowserToolbar(self) updateUsesTabBar];
							tabBarTweakActive = browserControllerForBrowserToolbar(self).tabController.usesTabBar;
						}
					}

					if(tabBarTweakActive)
					{
						defaultItems = [self dynamicItemsForOrder:@[@(BrowserToolbarBackItem), @(BrowserToolbarForwardItem), @(BrowserToolbarShareItem), @(BrowserToolbarBookmarksItem), @(BrowserToolbarDownloadsItem), @(BrowserToolbarTabExposeItem), @(BrowserToolbarAddTabItem)]];
					}
					else
					{
						defaultItems = [self dynamicItemsForOrder:@[@(BrowserToolbarBackItem), @(BrowserToolbarForwardItem), @(BrowserToolbarShareItem), @(BrowserToolbarBookmarksItem), @(BrowserToolbarDownloadsItem), @(BrowserToolbarTabExposeItem)]];
					}
				}
				else	//Top Bar
				{
					defaultItems = [self dynamicItemsForOrder:@[@(BrowserToolbarBackItem), @(BrowserToolbarForwardItem), @(BrowserToolbarBookmarksItem), @(BrowserToolbarSearchBarSpace), @(BrowserToolbarDownloadsItem), @(BrowserToolbarShareItem), @(BrowserToolbarAddTabItem), @(BrowserToolbarTabExposeItem)]];
				}
			}
			else
			{
				defaultItems = %orig;
			}

			defaultItemsForToolbarSize[@(tSelf.toolbarSize)] = defaultItems;
		}

		return defaultItems;
	}

	return %orig;
}

%new
- (void)updateTabCount
{
	if(tSelf.tabCountLabel)
	{
		void (^updateBlock)(void) = ^
		{
			UIBarButtonItem* tabExposeItem;

			if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_11_0)
			{
				if(tSelf.replacementToolbar)
				{
					return;
				}
			}

			if([self respondsToSelector:@selector(_tabExposeItemLayer)])
			{
				tabExposeItem = MSHookIvar<UIBarButtonItem*>(self, "_tabExposeItem");
			}
			else
			{
				SFBarRegistration* barRegistration = MSHookIvar<SFBarRegistration*>(self, "_barRegistration");
				tabExposeItem = [barRegistration UIBarButtonItemForItem:5];
			}

			if(!tabExposeItem)
			{
				return;
			}

			//Adding the label as a subview causes issues so we have to directly modify the image!

			//Save the original image if we don't have it already
			if(!tSelf.tabExposeImage)
			{
				tSelf.tabExposeImage = [tabExposeItem image];
			}

			TabController* tabController = browserControllerForBrowserToolbar(self).tabController;

			NSUInteger newTabCount;

			if([tabController respondsToSelector:@selector(numberOfCurrentNonHiddenTabs)])
			{
				newTabCount = tabController.numberOfCurrentNonHiddenTabs;
			}
			else
			{
				newTabCount = [browserControllerForBrowserToolbar(self).tabController.currentTabDocuments count];
			}

			if(newTabCount == 0)
			{
				newTabCount = 1;
			}

			NSString* newText = [NSString stringWithFormat:@"%llu", (unsigned long long)newTabCount];

			if(![tSelf.tabCountLabel.text isEqualToString:newText])	//If label changed, update image
			{
				//Set current label count as text
				tSelf.tabCountLabel.text = newText;

				//Convert label to image
				UIGraphicsBeginImageContextWithOptions(tSelf.tabExposeImage.size, NO, 0.0);
				[tSelf.tabCountLabel.layer renderInContext:UIGraphicsGetCurrentContext()];
				UIImage* labelImg = UIGraphicsGetImageFromCurrentImageContext();
				UIGraphicsEndImageContext();

				//Add labelImage to buttonImage
				UIGraphicsBeginImageContextWithOptions(tSelf.tabExposeImage.size, NO, 0.0);
				CGRect rect = CGRectMake(0,0,tSelf.tabExposeImage.size.width,tSelf.tabExposeImage.size.height);
				[tSelf.tabExposeImage drawInRect:rect];
				[labelImg drawInRect:CGRectMake(tSelf.tabCountLabel.frame.origin.x,tSelf.tabCountLabel.frame.origin.y,tSelf.tabExposeImage.size.width,tSelf.tabExposeImage.size.height)];
				tSelf.tabExposeImageWithCount = UIGraphicsGetImageFromCurrentImageContext();
				UIGraphicsEndImageContext();
			}

			//Apply image with count
			[tabExposeItem setImage:tSelf.tabExposeImageWithCount];
		};

		if([NSThread isMainThread])
		{
			updateBlock();
		}
		else
		{
			//Execute in main thread if we are not in one already
			dispatch_async(dispatch_get_main_queue(), updateBlock);
		}
	}
}

- (void)layoutSubviews
{
	%orig;

	if(tSelf.tabCountLabel)
	{
		[self updateTabCount];
	}
}

%end

void initBrowserToolbar()
{
	Class ToolbarClass;
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0)
	{
		ToolbarClass = objc_getClass("_SFToolbar");
	}
	else
	{
		ToolbarClass = objc_getClass("BrowserToolbar");
	}

	%init(BrowserToolbar=ToolbarClass);
}
