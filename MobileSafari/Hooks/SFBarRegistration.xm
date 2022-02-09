// Copyright (c) 2017-2022 Lars Fröder

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
#import "../Defines.h"
#import "../Classes/SPPreferenceManager.h"
#import "../Classes/SPDownloadsBarButtonItem.h"
#import "../Classes/SPLocalizationManager.h"
#import "../Util.h"
#import "../Enums.h"
#import <objc/runtime.h>

extern "C"
{
id objc_msgSendSuper2(struct objc_super *super, SEL op, ...);
}

NSArray* barButtonItemsForSafariPlusOrderItems(NSArray* safariPlusOrder)
{
    NSMutableArray* barButtonItems = [NSMutableArray new];

    for(NSNumber* itemNum in safariPlusOrder)
    {
        [barButtonItems addObject:[NSNumber numberWithInteger:barButtonItemForSafariPlusOrderItem([itemNum integerValue])]];
    }

    return [barButtonItems copy];
}

void configureBarButtonItem(UIBarButtonItem* item, NSString* accessibilityIdentifier, NSString* title, id target, SEL longPressAction, SEL touchDownAction)
{
    if(accessibilityIdentifier)
    {
        [item setAccessibilityIdentifier:accessibilityIdentifier];
    }

    if(title)
    {
        item.title = title;
    }

    if(target && longPressAction)
    {
        if(touchDownAction)
        {
            [item _sf_setTarget:target touchDownAction:touchDownAction longPressAction:longPressAction];
        }
        else
        {
            [item _sf_setTarget:target longPressAction:longPressAction];
        }
    }
}

@interface SFBarRegistration (SafariPlus)
@property (nonatomic, retain) UIBarButtonItem *reloadItem;
@property (nonatomic, retain) UIBarButtonItem *downloadsItem;
@property (nonatomic, retain) UIBarButtonItem *clearDataItem;

- (NSOrderedSet*)orderForToolbarWithLayout:(NSInteger)layout persona:(NSUInteger)persona;
@end

%hook SFBarRegistration

%property (nonatomic, retain) UIBarButtonItem *reloadItem;
%property (nonatomic, retain) UIBarButtonItem *downloadsItem;
%property (nonatomic, retain) UIBarButtonItem *clearDataItem;

//Reimplemented order logic from stock safari (verified to produce 1:1 copies on 13.2.2)
//Additions for download bar button and custom order
%new
- (NSOrderedSet*)orderForToolbarWithLayout:(NSInteger)layout persona:(NSUInteger)persona
{
    NSArray* order;

    if(persona == 0 && layout == 2 && preferenceManager.bottomToolbarCustomOrderEnabled && preferenceManager.bottomToolbarCustomOrder)
    {
        order = barButtonItemsForSafariPlusOrderItems(preferenceManager.bottomToolbarCustomOrder);
    }
    
    if(persona == 0 && (layout == 0 || layout == 1) && preferenceManager.topToolbarCustomOrderEnabled && preferenceManager.topToolbarCustomOrder)
    {
        NSArray* topToolbarCustomOrder = preferenceManager.topToolbarCustomOrder;
        NSInteger searchBarSpaceIndex = [topToolbarCustomOrder indexOfObject:@(BrowserToolbarSearchBarSpace)];

        if(searchBarSpaceIndex != NSNotFound)
        {
            NSRange leftRange = NSMakeRange(0,searchBarSpaceIndex);
            NSRange rightRange = NSMakeRange(searchBarSpaceIndex + 1, [topToolbarCustomOrder count] - searchBarSpaceIndex - 1);

            NSRange rangeToUse;

            if(layout == 0)
            {
                rangeToUse = leftRange;
            }
            else
            {
                rangeToUse = rightRange;
            }

            order = barButtonItemsForSafariPlusOrderItems([topToolbarCustomOrder subarrayWithRange:rangeToUse]);
            
            if(layout == 1)
            {
                order = [@[@7] arrayByAddingObjectsFromArray:order];
            }
        }    
    }

    NSNumber* downloadsItemNumber = [NSNumber numberWithInteger:barButtonItemForSafariPlusOrderItem(BrowserToolbarDownloadsItem)];

    if([order containsObject:downloadsItemNumber] && !preferenceManager.downloadManagerEnabled)
    {
        NSMutableArray* orderM = [order mutableCopy];
        [orderM removeObject:downloadsItemNumber];
        order = [orderM copy];
    }

    if(!order)
    {
        switch(persona)
        {
            case 0:
            {
                switch(layout)
                {
                    case 0:
                    {
                        if(preferenceManager.downloadManagerEnabled)
                        {
                            order = @[@0,@1,@2,downloadsItemNumber];
                        }
                        else
                        {
                            order = @[@0,@1,@2];
                        }
                        break;
                    }
                    case 1:
                    {
                        order = @[@7,@3,@4,@5];
                        break;
                    }
                    case 2:
                    {
                        if(preferenceManager.downloadManagerEnabled)
                        {
                            order = @[@0,@1,@3,@2,downloadsItemNumber,@5];
                        }
                        else
                        {
                            order = @[@0,@1,@3,@2,@5];
                        }
                        break;
                    }
                }
                break;
            }

            case 1:
            {
                switch(layout)
                {
                    case 0:
                    {
                        order = @[@0,@1];
                        break;
                    }
                    case 1:
                    {
                        order = @[@3,@6];
                        break;
                    }
                    case 2:
                    {
                        order = @[@0,@1,@3,@6];
                        break;
                    }
                }
                break;
            }
            
            case 2:
            {
                switch(layout)
                {
                    case 0:
                    {
                        order = @[@0,@1];
                        break;
                    }
                    case 1:
                    {
                        order = @[@3];
                        break;
                    }
                    case 2:
                    {
                        order = @[@0,@1,@-100,@-101,@3];
                        break;
                    }
                }
            }
            break;
        }
    }

    if(!order)
    {
        order = @[];
    }

    return [NSOrderedSet orderedSetWithArray:order];
}

/*

0: back
1: forward
2: bookmarks
3: share
4: add tab
5: tabs
6: open in safari
7: downloads button

*/

//Reimplemented original implementation with additions
- (instancetype)initWithBar:(_SFToolbar*)bar barManager:(id)barManager layout:(NSInteger)layout persona:(NSUInteger)persona
{
    if(!(persona == 0 && (preferenceManager.downloadManagerEnabled || (preferenceManager.bottomToolbarCustomOrderEnabled && preferenceManager.bottomToolbarCustomOrder && layout == 2) || (preferenceManager.topToolbarCustomOrderEnabled && preferenceManager.topToolbarCustomOrder && layout != 2))))
    {
        return %orig;
    }

    objc_super super;
    super.receiver = self;
    super.super_class = [self class];

    self = objc_msgSendSuper2(&super, @selector(init));

    [self setValue:bar forKey:@"_bar"];
    [self setValue:barManager forKey:@"_barManager"];
    [self setValue:@(layout) forKey:@"_layout"];

    NSOrderedSet* order = [self orderForToolbarWithLayout:layout persona:persona];

    [self setValue:order forKey:@"_arrangedBarItems"];
    [self setValue:[[NSMutableSet alloc] init] forKey:@"_hiddenBarItems"];

    NSInteger itemDistribution;
    if(layout == 2)
    {
        itemDistribution = 4;
    }
    else
    {
        itemDistribution = 3;
    }
    [bar _setItemDistribution:itemDistribution];

    if([order containsObject:@0]) //back
    {
        UIBarButtonItem* backItem = [self _newBarButtonItemForSFBarItem:0];
        configureBarButtonItem(backItem, @"BackButton", [localizationManager localizedWBSStringForKey:@"Back (toolbar accessibility title)"], self, @selector(_itemReceivedLongPress:), nil);
        [self setValue:backItem forKey:@"_backItem"];
    }

    if([order containsObject:@1]) //forward
    {
        UIBarButtonItem* forwardItem = [self _newBarButtonItemForSFBarItem:1];
        configureBarButtonItem(forwardItem, @"ForwardButton", [localizationManager localizedWBSStringForKey:@"Forward (toolbar accessibility title)"], self, @selector(_itemReceivedLongPress:), nil);
        [self setValue:forwardItem forKey:@"_forwardItem"];
    }

    if([order containsObject:@2]) //bookmarks
    {
        UIBarButtonItem* bookmarksItem = [self _newBarButtonItemForSFBarItem:2];
        configureBarButtonItem(bookmarksItem, @"BookmarksButton", [localizationManager localizedWBSStringForKey:@"Bookmarks (toolbar accessibility title)"], self, @selector(_itemReceivedLongPress:), nil);
        bookmarksItem._additionalSelectionInsets = UIEdgeInsetsMake(2, 0, 3, 0);
        [self setValue:bookmarksItem forKey:@"_bookmarksItem"];
    }

    if([order containsObject:@3]) //share
    {
        UIBarButtonItem* shareItem = [self _newBarButtonItemForSFBarItem:3];
        configureBarButtonItem(shareItem, @"ShareButton", [localizationManager localizedWBSStringForKey:@"Share (toolbar accessibility title)"], self, @selector(_itemReceivedLongPress:), @selector(_itemReceivedTouchDown:));
        [self setValue:shareItem forKey:@"_shareItem"];
    }

    if([order containsObject:@4]) //add tab
    {
        UIBarButtonItem* newTabItem = [self _newBarButtonItemForSFBarItem:4];
        configureBarButtonItem(newTabItem, @"NewTabButton", [localizationManager localizedWBSStringForKey:@"New Tab (toolbar accessibility title)"], self, @selector(_itemReceivedLongPress:), nil);
        [self setValue:newTabItem forKey:@"_newTabItem"];
    }

    if([order containsObject:@5]) //tabs
    {
        UIBarButtonItem* tabExposeItem = [self _newBarButtonItemForSFBarItem:5];
        configureBarButtonItem(tabExposeItem, @"TabsButton", [localizationManager localizedWBSStringForKey:@"Tabs (toolbar accessibility title)"], self, @selector(_itemReceivedLongPress:), nil);
        [self setValue:tabExposeItem forKey:@"_tabExposeItem"];
    }

    if([order containsObject:@6]) //open in safari
    {
        UIBarButtonItem* openInSafariItem = [self _newBarButtonItemForSFBarItem:6];
        configureBarButtonItem(openInSafariItem, @"OpenInSafariButton", [localizationManager localizedWBSStringForKey:@"Open in Safari (toolbar accessibility title)"], self, @selector(_itemReceivedLongPress:), nil);
        [self setValue:openInSafariItem forKey:@"_openInSafariItem"];
    }

    if([order containsObject:@7]) //downloads
    {
        UIBarButtonItem* downloadsItem = [self _newBarButtonItemForSFBarItem:7];
        configureBarButtonItem(downloadsItem, @"DownloadsButton", nil, self, nil, nil);
        [self setValue:downloadsItem forKey:@"_downloadsItem"];
    }

    //This class is cursed so we can't create the toolbar buttons from here
    //They are instead created inside BrowserToolbar
    if(((BrowserToolbar*)bar)._downloadsItem)
    {
        ((BrowserToolbar*)bar)._downloadsItem.target = self;
    }

    if(((BrowserToolbar*)bar)._reloadItem)
    {
        ((BrowserToolbar*)bar)._reloadItem.target = self;
    }

    if(((BrowserToolbar*)bar)._clearDataItem)
    {
        ((BrowserToolbar*)bar)._clearDataItem.target = self;
    }

    /*NSInteger downloadsItem = barButtonItemForSafariPlusOrderItem(BrowserToolbarDownloadsItem);
    if([order containsObject:@(downloadsItem)])
    {
        ((BrowserToolbar*)bar).downloadsItem = [self _newBarButtonItemForSFBarItem:downloadsItem];
    }

    NSInteger reloadBarButtonItem = barButtonItemForSafariPlusOrderItem(BrowserToolbarReloadItem);
    if([order containsObject:@(reloadBarButtonItem)])
    {
        ((BrowserToolbar*)bar).reloadItem = [self _newBarButtonItemForSFBarItem:reloadBarButtonItem];
    }

    NSInteger clearDataItem = barButtonItemForSafariPlusOrderItem(BrowserToolbarClearDataItem);
    if([order containsObject:@(clearDataItem)])
    {
        ((BrowserToolbar*)bar).clearDataItem = [self _newBarButtonItemForSFBarItem:clearDataItem];
    }*/

    return self;
}

/*
- (UIBarButtonItem*)_newBarButtonItemForSFBarItem:(NSInteger)barItem
{
    if(barItem >= 10)
    {
        NSInteger safariPlusOrderItem = safariPlusOrderItemForBarButtonItem(barItem);

        NSString* systemIconName;

        UIBarButtonItem* item;

        switch(safariPlusOrderItem)
        {
            case BrowserToolbarSearchBarSpace:
            return nil;
            break;

            case BrowserToolbarDownloadsItem:
            if(preferenceManager.previewDownloadProgressEnabled)
            {
                item = [[SPDownloadsBarButtonItem alloc] initWithTarget:self action:@selector(_itemReceivedTap:) layout:MSHookIvar<NSInteger>(self, "_layout")];
                if(MSHookIvar<NSInteger>(self, "_layout") == 2)
                {
                    [item _setWidth:60];
                }
                return item;
            }
            systemIconName = @"arrow.down.circle";
            break;

            case BrowserToolbarReloadItem:
            systemIconName = @"arrow.clockwise";
            break;

            case BrowserToolbarClearDataItem:
            systemIconName = @"trash";
            break;
        }
        UIImageSymbolConfiguration* symbolConfiguration = [%c(UIImageSymbolConfiguration) configurationWithTextStyle:UIFontTextStyleBody scale:UIImageSymbolScaleLarge];
        symbolConfiguration = [symbolConfiguration configurationWithTraitCollection:[UITraitCollection traitCollectionWithPreferredContentSizeCategory:UIContentSizeCategoryMedium]];

        item = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:systemIconName withConfiguration:symbolConfiguration] style:UIBarButtonItemStylePlain target:self action:@selector(_itemReceivedTap:)];
        if(MSHookIvar<NSInteger>(self, "_layout") == 2)
        {
            [item _setWidth:60];
        }
        return item;
    }
    else
    {
        return %orig;
    }
}*/

- (UIBarButtonItem*)_UIBarButtonItemForBarItem:(NSInteger)barItem
{
    if(barItem >= 10)
    {
        _SFToolbar* bar = [self valueForKey:@"_bar"];
        if(barItem == barButtonItemForSafariPlusOrderItem(BrowserToolbarDownloadsItem))
        {
            return ((BrowserToolbar*)bar)._downloadsItem;
        }
        else if(barItem == barButtonItemForSafariPlusOrderItem(BrowserToolbarReloadItem))
        {
            return ((BrowserToolbar*)bar)._reloadItem;
        }
        else if(barItem == barButtonItemForSafariPlusOrderItem(BrowserToolbarClearDataItem))
        {
            return ((BrowserToolbar*)bar)._clearDataItem;
        }
    }

    return %orig;
}

- (NSInteger)_barItemForUIBarButtonItem:(UIBarButtonItem*)item
{
    _SFToolbar* bar = [self valueForKey:@"_bar"];
    if(item == ((BrowserToolbar*)bar)._downloadsItem)
    {
        return barButtonItemForSafariPlusOrderItem(BrowserToolbarDownloadsItem);
    }
    else if(item == ((BrowserToolbar*)bar)._reloadItem)
    {
        return barButtonItemForSafariPlusOrderItem(BrowserToolbarReloadItem);
    }
    else if (item == ((BrowserToolbar*)bar)._clearDataItem)
    {
        return barButtonItemForSafariPlusOrderItem(BrowserToolbarClearDataItem);
    }

    return %orig;
}

- (void)_itemReceivedTap:(UIBarButtonItem*)item
{
    NSInteger barItem = [self _barItemForUIBarButtonItem:item];

    if(barItem >= 10)
    {
        NSInteger spOrderItem = safariPlusOrderItemForBarButtonItem(barItem);
        BrowserToolbar* toolbar = [self valueForKey:@"_bar"];

        switch(spOrderItem)
        {
            case BrowserToolbarDownloadsItem:
            {
                [browserControllerForBrowserToolbar(toolbar) downloadsFromButtonBar];
                break;
            }
            case BrowserToolbarReloadItem:
            {
                [navigationBarForBrowserController(browserControllerForBrowserToolbar(toolbar)) _reloadButtonPressed];
                break;
            }
            case BrowserToolbarClearDataItem:
            {
                [browserControllerForBrowserToolbar(toolbar) clearData];
                break;
            }
        }
        return;
    }

    %orig;
}

%end

void initSFBarRegistration()
{
    if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0)
    {
        %init;
    }
}