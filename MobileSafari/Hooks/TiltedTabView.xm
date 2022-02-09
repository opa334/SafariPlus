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

#import "../Classes/SPPreferenceManager.h"
#import "../Classes/SPLocalizationManager.h"

#import "../Defines.h"
#import "../Util.h"

#import <libundirect/libundirect_dynamic.h>
#import <libundirect/libundirect_hookoverwrite.h>

CGRect calculateLockButtonHitRect(UIScrollView* scrollView, TabThumbnailView* contentView)
{
	CGPoint midPointLockButton = CGPointMake(CGRectGetMidX(contentView.lockButton.bounds), CGRectGetMidY(contentView.lockButton.bounds));
	CGPoint midPointLockButtonScrollView = [contentView.lockButton convertPoint:midPointLockButton toView:scrollView];
	CGRect lockButtonHitRect = CGRectMake(midPointLockButtonScrollView.x - 22, midPointLockButtonScrollView.y - 22, 44, 44);
	return lockButtonHitRect;
}

%hook TiltedTabView

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
	if(preferenceManager.lockedTabsEnabled)
	{
		if(![self valueForKey:@"_editedCloudTabItemView"])
		{
			UIScrollView* scrollView = [self valueForKey:@"_scrollView"];
			CGPoint pointInScrollView = [self convertPoint:point toView:scrollView];
			for(TiltedTabItem* item in self.items)
			{
				if([item respondsToSelector:@selector(layoutInfo)])
				{
					CGRect lockButtonHitRect = calculateLockButtonHitRect(scrollView, item.layoutInfo.contentView);
					if(CGRectContainsPoint(lockButtonHitRect, pointInScrollView))
					{
						return item.layoutInfo.contentView.lockButton;
					}
				}
				else
				{
					// iOS 8
					CGRect lockButtonHitRect = calculateLockButtonHitRect(scrollView, item.contentView);
					if(CGRectContainsPoint(lockButtonHitRect, pointInScrollView))
					{
						return item.contentView.lockButton;
					}
				}
			}
		}
	}

	return %orig;
}

- (TiltedTabItem*)_tiltedTabItemForLocation:(CGPoint)location
{
	TiltedTabItem* item = %orig;

	if(preferenceManager.lockedTabsEnabled)
	{
		if(item)
		{
			UIScrollView* scrollView = [self valueForKey:@"_scrollView"];

			CGRect lockButtonHitRect;

			if([item respondsToSelector:@selector(layoutInfo)])
			{
				lockButtonHitRect = calculateLockButtonHitRect(scrollView, item.layoutInfo.contentView);
			}
			else
			{
				// iOS 8
				lockButtonHitRect = calculateLockButtonHitRect(scrollView, item.contentView);
			}

			if(CGRectContainsPoint(lockButtonHitRect, location))
			{
				return nil;
			}
		}
	}

	return item;
}

%new
- (void)_lockButtonPressed:(UIButton*)button
{
	for(TiltedTabItem* item in self.items)
	{
		if([item respondsToSelector:@selector(contentView)])
		{
			if(item.contentView.lockButton == button)
			{
				[self.delegate toggleLockedStateForItem:item];
			}
		}
		else
		{
			if(item.layoutInfo.contentView.lockButton == button)
			{
				[self.delegate toggleLockedStateForItem:item];
			}
		}
	}
}

- (void)_tabSelectionRecognized:(UITapGestureRecognizer*)recognizer
{
	if(preferenceManager.lockedTabsEnabled && preferenceManager.biometricProtectionEnabled && preferenceManager.biometricProtectionAccessLockedTabEnabled)
	{
		BOOL iForgotWhatThisWasForButItCrashesOnIOS8;

		if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_9_0)
		{
			iForgotWhatThisWasForButItCrashesOnIOS8 = YES;
		}
		else
		{
			iForgotWhatThisWasForButItCrashesOnIOS8 = MSHookIvar<NSInteger>(self, "_currentTabPreviewState") != 2;
		}

		if(iForgotWhatThisWasForButItCrashesOnIOS8)
		{
			TiltedTabItem* tappedItem = [self _tiltedTabItemForLocation:[recognizer locationInView:MSHookIvar<UIView*>(self, "_scrollView")]];

			if([self.delegate currentItemForTiltedTabView:self] != tappedItem)
			{
				TabDocument* tabDocument = tabDocumentForItem(self.delegate, tappedItem);

				if(tabDocument.locked)
				{
					requestAuthentication([localizationManager localizedSPStringForKey:@"ACCESS_LOCKED_TAB"], ^
					{
						tabDocument.accessAuthenticated = YES;
						if([self.delegate respondsToSelector:@selector(tabCollectionView:didSelectItem:)])
						{
							[self.delegate tabCollectionView:self didSelectItem:tappedItem];
						}
						else
						{
							[self.delegate tiltedTabView:self didSelectItem:tappedItem];
						}
						if([self respondsToSelector:@selector(dismissAnimated:)])
						{
							[self dismissAnimated:YES];
						}
						else
						{
							[self setPresented:NO animated:YES];
						}
					});

					return;
				}
			}
		}
	}

	%orig;
}

%group iOS9Down

- (void)_updateItemsInvolvedInAnimation
{
	NSArray* itemsInvolvedInAnimation = MSHookIvar<NSArray*>(self, "_itemsInvolvedInAnimation");

	for(TiltedTabItem* item in itemsInvolvedInAnimation)
	{
		[item.contentView.lockButton removeTarget:self action:@selector(_lockButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	}

	%orig;

	itemsInvolvedInAnimation = MSHookIvar<NSArray*>(self, "_itemsInvolvedInAnimation");

	for(TiltedTabItem* item in itemsInvolvedInAnimation)
	{
		[item.contentView.lockButton addTarget:self action:@selector(_lockButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		item.contentView.lockButton.selected = tabDocumentForItem(self.delegate, item).locked;
	}
}

%end

%end

void initTiltedTabView()
{
	%init();

	if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_10_0)
	{
		%init(iOS9Down);
	}
}
