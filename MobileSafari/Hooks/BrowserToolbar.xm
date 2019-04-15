// BrowserToolbar.xm
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

#import "../SafariPlus.h"

#import "../Classes/SPPreferenceManager.h"
#import "../Defines.h"
#import "../Shared.h"
#import "../Enums.h"

//Turns a system bar button item into a non-system one
//Needed because system items act weird and can't be modified that easily
static __kindof UIBarButtonItem* unsystemifiedBarButtonItem(__kindof UIBarButtonItem* oldItem, CGFloat width, NSInteger alignment, BOOL setLongPress, BOOL setTouchDown)
{
	UIImage* itemImage;
	[UIBarButtonItem _getSystemItemStyle:nil title:nil image:&itemImage selectedImage:nil action:nil forBarStyle:0 landscape:NO alwaysBordered:NO usingSystemItem:oldItem.systemItem usingItemStyle:0];

	UIImage* newImage = [itemImage imageWithWidth:width alignment:alignment];

	UIBarButtonItem* newItem = [[(__kindof UIBarButtonItem*)[oldItem class] alloc] initWithImage:newImage style:UIBarButtonItemStylePlain target:oldItem.target action:oldItem.action];

	if(setLongPress)
	{
		if([newItem respondsToSelector:@selector(setGestureRecognizer:)])
		{
			[((GestureRecognizingBarButtonItem*)newItem) setGestureRecognizer:((GestureRecognizingBarButtonItem*)oldItem).gestureRecognizer];
		}
		else if([newItem respondsToSelector:@selector(_sf_setLongPressTarget:action:)])
		{
			[newItem _sf_setLongPressTarget:oldItem.target action:@selector(_itemReceivedLongPress:)];
		}
		else if([newItem respondsToSelector:@selector(_sf_setTarget:touchDownAction:longPressAction:)])
		{
			if(setTouchDown)
			{
				[newItem _sf_setTarget:oldItem.target touchDownAction:@selector(_itemReceivedTouchDown:) longPressAction:@selector(_itemReceivedLongPress:)];
			}
			else if([newItem respondsToSelector:@selector(_sf_setTarget:longPressAction:)])
			{
				[newItem _sf_setTarget:oldItem.target longPressAction:@selector(_itemReceivedLongPress:)];
			}
		}
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
%property (nonatomic,retain) UILabel *tabCountLabel;
%property (nonatomic,retain) UIImage *tabExposeImage;

//Correctly enable / disable downloads button when needed
- (void)setEnabled:(BOOL)arg1
{
	%orig;
	if(preferenceManager.enhancedDownloadsEnabled)
	{
		[self setDownloadsEnabled:arg1];
	}
}

%new
- (void)setDownloadsEnabled:(BOOL)enabled
{
	[self._downloadsItem setEnabled:enabled];
}

%new
- (NSMutableArray*)dynamicItemsForOrder:(NSArray*)order
{
	NSMutableArray* orderM = [order mutableCopy];

	if([orderM containsObject:@(BrowserToolbarDownloadsItem)] && !preferenceManager.enhancedDownloadsEnabled)
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
				addTabItem = [[%c(GestureRecognizingBarButtonItem) alloc] initWithImage:[UIImage imageNamed:@"AddTab"] style:UIBarButtonItemStylePlain target:self.browserDelegate action:@selector(addTabFromButtonBar)];
				UILongPressGestureRecognizer* recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_addTabLongPressRecognized:)];
				recognizer.allowableMovement = 3.0;
				[((GestureRecognizingBarButtonItem*)addTabItem) setGestureRecognizer:recognizer];
			}
			else
			{
				addTabItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"AddTab"] style:UIBarButtonItemStylePlain target:self.browserDelegate action:@selector(addTabFromButtonBar)];
				[addTabItem _sf_setLongPressTarget:self action:@selector(_addTabLongPressRecognized:)];
			}

			MSHookIvar<UIBarButtonItem*>(self, "_addTabItem") = addTabItem;
		}
		addToDict(allItems, MSHookIvar<UIBarButtonItem*>(self, "_addTabItem"), @(BrowserToolbarAddTabItem));
		if(!MSHookIvar<UIBarButtonItem*>(self, "_tabExposeItem"))	//needed on iOS 9 and below
		{
			MSHookIvar<UIBarButtonItem*>(self, "_tabExposeItem") = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"TabButton"] style:UIBarButtonItemStylePlain target:self.browserDelegate action:@selector(showTabsFromButtonBar)];
		}
		addToDict(allItems, MSHookIvar<UIBarButtonItem*>(self, "_tabExposeItem"), @(BrowserToolbarTabExposeItem));

		target = self;
	}

	if([orderM containsObject:@(BrowserToolbarDownloadsItem)])
	{
		if(!self._downloadsItem)
		{
			self._downloadsItem = [[UIBarButtonItem alloc] initWithImage:[UIImage
										      imageNamed:@"DownloadsButton.png" inBundle:SPBundle
										      compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain
					       target:self.browserDelegate action:@selector(downloadsFromButtonBar)];
		}

		addToDict(allItems, self._downloadsItem, @(BrowserToolbarDownloadsItem));
	}

	if([orderM containsObject:@(BrowserToolbarBackItem)])
	{
		UIBarButtonItem* backItem = [allItems objectForKey:@(BrowserToolbarBackItem)];

		if([backItem isSystemItem])
		{
			NSUInteger backItemIndex = [orderM indexOfObject:@(BrowserToolbarBackItem)];

			NSInteger alignment = 0;

			if(backItemIndex == 0)	//Align first button to the left
			{
				alignment = -1;
			}
			else if(backItemIndex == orderM.count - 1)	//Align last button to the right
			{
				alignment = 1;
			}

			UIBarButtonItem* newBackItem = unsystemifiedBarButtonItem(backItem, 25, alignment, YES, NO);

			[allItems setObject:newBackItem forKey:@(BrowserToolbarBackItem)];

			MSHookIvar<UIBarButtonItem*>(target, "_backItem") = newBackItem;
		}
	}

	if([orderM containsObject:@(BrowserToolbarForwardItem)])
	{
		UIBarButtonItem* forwardItem = [allItems objectForKey:@(BrowserToolbarForwardItem)];

		if([forwardItem isSystemItem])
		{
			NSUInteger forwardItemIndex = [orderM indexOfObject:@(BrowserToolbarForwardItem)];

			NSInteger alignment = 0;

			if(forwardItemIndex == 0)	//Align first button to the left
			{
				alignment = -1;
			}
			else if(forwardItemIndex == orderM.count - 1)	//Align last button to the right
			{
				alignment = 1;
			}

			UIBarButtonItem* newForwardItem = unsystemifiedBarButtonItem(forwardItem, 25, alignment, YES, NO);

			[allItems setObject:newForwardItem forKey:@(BrowserToolbarForwardItem)];

			MSHookIvar<UIBarButtonItem*>(target, "_forwardItem") = newForwardItem;
		}
	}

	if([orderM containsObject:@(BrowserToolbarShareItem)])
	{
		UIBarButtonItem* shareItem = [allItems objectForKey:@(BrowserToolbarShareItem)];

		if([shareItem isSystemItem])
		{
			NSUInteger shareItemIndex = [orderM indexOfObject:@(BrowserToolbarShareItem)];

			NSInteger alignment = 0;

			if(shareItemIndex == 0)	//Align first button to the left
			{
				alignment = -1;
			}
			else if(shareItemIndex == orderM.count - 1)	//Align last button to the right
			{
				alignment = 1;
			}

			UIBarButtonItem* newShareItem = unsystemifiedBarButtonItem(shareItem, 25, alignment, YES, YES);

			[allItems setObject:newShareItem forKey:@(BrowserToolbarShareItem)];

			if(NSClassFromString(@"SFBarRegistration"))
			{
				MSHookIvar<UIBarButtonItem*>(target, "_shareItem") = newShareItem;
			}
			else
			{
				MSHookIvar<UIBarButtonItem*>(target, "_actionItem") = newShareItem;
			}
		}
	}

	if([orderM containsObject:@(BrowserToolbarBookmarksItem)])
	{
		UIBarButtonItem* bookmarksItem = [allItems objectForKey:@(BrowserToolbarBookmarksItem)];
		bookmarksItem.imageInsets = UIEdgeInsetsMake(bookmarksItem.imageInsets.top, 0, bookmarksItem.imageInsets.bottom, 0);
	}

	if([orderM containsObject:@(BrowserToolbarTabExposeItem)])
	{
		UIBarButtonItem* tabExposeItem = [allItems objectForKey:@(BrowserToolbarTabExposeItem)];
		tabExposeItem.imageInsets = UIEdgeInsetsMake(tabExposeItem.imageInsets.top, 0, tabExposeItem.imageInsets.bottom, 0);
	}

	if([orderM containsObject:@(BrowserToolbarAddTabItem)])
	{
		UIBarButtonItem* addTabItem = [allItems objectForKey:@(BrowserToolbarAddTabItem)];

		addTabItem.image = [addTabItem.image imageWithWidth:25 alignment:0];

		addTabItem.imageInsets = UIEdgeInsetsMake(addTabItem.imageInsets.top, 0, addTabItem.imageInsets.bottom, 0);
	}

	NSMutableArray* dynamicItems = [NSMutableArray new];

	UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

	if(MSHookIvar<NSInteger>(self, "_placement"))	//Bottom Toolbar
	{
		BOOL first = YES;

		for(NSNumber* num in orderM)
		{
			if(!first)
			{
				[dynamicItems addObject:flexibleSpace];
			}
			else
			{
				first = NO;
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

		CGFloat availableSpace = (self.URLFieldHorizontalMargin - toolbarMargin);

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

//Add downloads button to toolbar
- (NSMutableArray *)defaultItems
{
	if(preferenceManager.bottomToolbarCustomOrderEnabled || preferenceManager.topToolbarCustomOrderEnabled)
	{
		NSMutableDictionary* defaultItemsForToolbarSize = MSHookIvar<NSMutableDictionary*>(self, "_defaultItemsForToolbarSize");

		NSMutableArray* defaultItems = defaultItemsForToolbarSize[@(self.toolbarSize)];

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
			else
			{
				defaultItems = %orig;
			}

			defaultItemsForToolbarSize[@(self.toolbarSize)] = defaultItems;
		}

		return defaultItems;
	}


	return %orig;
	/*if(preferenceManager.enhancedDownloadsEnabled)
	   {
	        NSMutableArray* orig = %orig;

	        if(![orig containsObject:self._downloadsItem])
	        {
	                if(!self._downloadsItem)
	                {
	                        self._downloadsItem = [[UIBarButtonItem alloc] initWithImage:[UIImage
	                                                                                      imageNamed:@"DownloadsButton.png" inBundle:SPBundle
	                                                                                      compatibleWithTraitCollection:nil] style:UIBarButtonItemStylePlain
	                                               target:self.browserDelegate action:@selector(downloadsFromButtonBar)];
	                }

	                NSInteger placement = MSHookIvar<NSInteger>(self, "_placement");

	                //Landscape on newer devices, portrait + landscape on iOS 8 iPads
	                if(placement == 0 || (IS_PAD && kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_9_0))
	                {
	                        //iPads
	                        if(IS_PAD)
	                        {
	                                ((UIBarButtonItem*)orig[10]).width = ((UIBarButtonItem*)orig[10]).width / 3;
	                                ((UIBarButtonItem*)orig[12]).width = ((UIBarButtonItem*)orig[12]).width / 3;
	                        }
	                        else
	                        {
	                                //Plus iPhones
	                                if([orig count] > 14)
	                                {
	                                        ((UIBarButtonItem*)orig[10]).width = ((UIBarButtonItem*)orig[10]).width / 10;
	                                        ((UIBarButtonItem*)orig[12]).width = ((UIBarButtonItem*)orig[12]).width / 10;
	                                        ((UIBarButtonItem*)orig.lastObject).width = 0;
	                                }
	                                //Non plus iPhones
	                                else
	                                {
	                                        ((UIBarButtonItem*)orig[10]).width = 0;
	                                        ((UIBarButtonItem*)orig[12]).width = 0;
	                                }
	                        }

	                        [orig insertObject:orig[10] atIndex:8];
	                        [orig insertObject:self._downloadsItem atIndex:8];
	                }
	                //Portrait mode on all iPhones, landscape on smaller iPhones + split view on smaller iPads
	                else
	                {
	                        UIBarButtonItem* flexibleSpace = [[UIBarButtonItem alloc]
	                                                          initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
	                                                          target:nil action:nil];

	                        BrowserController* browserController = self.browserDelegate;

	                        BOOL tabBarTweakActive = NO;

	                        if([browserController respondsToSelector:@selector(_shouldShowTabBar)])
	                        {
	                                tabBarTweakActive = [browserController _shouldShowTabBar] && [browserControllers() count] <= 1;
	                        }
	                        else
	                        {
	                                //Unfortunately there isn't a better way to detect this reliably :/
	                                [browserController updateUsesTabBar];

	                                tabBarTweakActive = browserController.tabController.usesTabBar;
	                        }

	                        if(tabBarTweakActive)
	                        {
	                                orig = [@[orig[1], flexibleSpace, flexibleSpace,
	                                          orig[4], flexibleSpace, orig[7], flexibleSpace, orig[10], flexibleSpace, self._downloadsItem,
	                                          flexibleSpace, orig[13]] mutableCopy];

	                                if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_2)
	                                {
	                                        if([self respondsToSelector:@selector(addTabItemManual)])
	                                        {
	                                                [orig addObject:flexibleSpace];
	                                                [orig addObject:self.addTabItemManual];
	                                        }
	                                }
	                                else
	                                {
	                                        //Add FullSafari button to final array
	                                        //Code from https://github.com/Bensge/FullSafari/blob/master/Tweak.xm
	                                        GestureRecognizingBarButtonItem *addTabItem = [self valueForKey:@"_addTabItem"];

	                                        if(!addTabItem || ![orig containsObject:addTabItem])
	                                        {
	                                                if(!addTabItem)
	                                                {
	                                                        addTabItem = [[%c(GestureRecognizingBarButtonItem) alloc] initWithImage:[UIImage imageNamed:@"AddTab"] style:0 target:self.browserDelegate action:@selector(addTabFromButtonBar)];
	                                                        UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_addTabLongPressRecognized:)];
	                                                        recognizer.allowableMovement = 3.0;
	                                                        addTabItem.gestureRecognizer = recognizer;
	                                                }
	                                                [orig addObject:flexibleSpace];
	                                                [orig addObject:addTabItem];
	                                        }
	                                }
	                        }
	                        else
	                        {
	                                UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc]
	                                                               initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
	                                                               target:nil action:nil];

	                                UIBarButtonItem *fixedSpaceHalf = [[UIBarButtonItem alloc]
	                                                                   initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
	                                                                   target:nil action:nil];

	                                UIBarButtonItem *fixedSpaceTwo = [[UIBarButtonItem alloc]
	                                                                  initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
	                                                                  target:nil action:nil];

	                                fixedSpace.width = 15;
	                                fixedSpaceHalf.width = 7.5f;
	                                fixedSpaceTwo.width = 6;

	                                orig = [@[orig[1], fixedSpace, flexibleSpace,
	                                          fixedSpaceHalf, orig[4], fixedSpaceHalf, flexibleSpace, fixedSpaceTwo,
	                                          orig[7], flexibleSpace, orig[10], flexibleSpace, self._downloadsItem,
	                                          flexibleSpace, orig[13]] mutableCopy];
	                        }
	                }

	                NSMutableDictionary* defaultItemsForToolbarSize =
	                        MSHookIvar<NSMutableDictionary*>(self, "_defaultItemsForToolbarSize");

	                //Save items to dictionary
	                defaultItemsForToolbarSize[@(self.toolbarSize)] = orig;

	                return orig;
	        }
	   }

	   return %orig;*/
}

- (instancetype)initWithPlacement:(NSInteger)placement
{
	BrowserToolbar* orig = %orig;

	if(preferenceManager.showTabCountEnabled)
	{
		orig.tabCountLabel = [[UILabel alloc] init];
		orig.tabCountLabel.adjustsFontSizeToFitWidth = YES;
		orig.tabCountLabel.minimumFontSize = 0;
		orig.tabCountLabel.numberOfLines = 1;
		orig.tabCountLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		orig.tabCountLabel.textAlignment = UITextAlignmentCenter;
		orig.tabCountLabel.frame = CGRectMake(2.25,6.5,14.75,17.25);
		orig.tabCountLabel.textColor = [UIColor blackColor];
	}

	return orig;
}

- (void)layoutSubviews
{
	%orig;

	if(preferenceManager.showTabCountEnabled)
	{
		[self updateTabCount];
	}
}

%new
- (void)updateTabCount
{
	if(self.tabCountLabel)
	{
		void (^updateBlock)(void) = ^
		{
			if(self.replacementToolbar || !self.tabCountLabel)
			{
				return;
			}

			UIBarButtonItem* tabExposeItem;

			if([self respondsToSelector:@selector(_tabExposeItemLayer)])
			{
				tabExposeItem = MSHookIvar<UIBarButtonItem*>(self, "_tabExposeItem");
			}
			else
			{
				SFBarRegistration* barRegistration = MSHookIvar<SFBarRegistration*>(self, "_barRegistration");
				tabExposeItem = [barRegistration UIBarButtonItemForItem:5];
			}

			//Adding the label as a subview causes issues so we have to directly modify the image!

			//Save the original image if we don't have it already
			if(!self.tabExposeImage)
			{
				self.tabExposeImage = [tabExposeItem image];
			}

			//Set current label count as text
			self.tabCountLabel.text = [NSString stringWithFormat:@"%lli", (long long)[self.browserDelegate.tabController.currentTabDocuments count]];

			//Convert label to image
			UIGraphicsBeginImageContextWithOptions(self.tabExposeImage.size, NO, 0.0);
			[self.tabCountLabel.layer renderInContext:UIGraphicsGetCurrentContext()];
			UIImage* labelImg = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();

			//Add labelImage to buttonImage
			UIGraphicsBeginImageContextWithOptions(self.tabExposeImage.size, NO, 0.0);
			CGRect rect = CGRectMake(0,0,self.tabExposeImage.size.width,self.tabExposeImage.size.height);
			[self.tabExposeImage drawInRect:rect];
			[labelImg drawInRect:CGRectMake(self.tabCountLabel.frame.origin.x,self.tabCountLabel.frame.origin.y,self.tabExposeImage.size.width,self.tabExposeImage.size.height)];
			UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();

			//Apply new image
			[tabExposeItem setImage:newImage];
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

%end

void initBrowserToolbar()
{
	%init();
}
