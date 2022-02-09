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
#import "Extensions.h"

#import "../Defines.h"
#import "../Util.h"
#import "../Classes/SPLocalizationManager.h"
#import "../Classes/SPPreferenceManager.h"

@interface ToggleForceHTTPSUIActivity : UIActivity
@property (nonatomic, assign) BOOL isException;
@end

%group iOS8

%subclass ToggleForceHTTPSUIActivity : UIActivity

%property (nonatomic, assign) BOOL isException;

- (BOOL)canPerformWithActivityItems:(id)arg1
{
	return YES;
}

- (id)activityImage
{
	UIImage* activityImage = [UIImage imageNamed:@"AddTab"];

	if(!self.isException)
	{
		return activityImage;
	}

	return [activityImage imageRotatedByDegrees:45.0];
}

- (NSString*)activityTitle
{
	if(self.isException)
	{
		return [localizationManager localizedSPStringForKey:@"REMOVE_FROM_FORCE_HTTPS_EXCEPTIONS"];
	}
	else
	{
		return [localizationManager localizedSPStringForKey:@"ADD_TO_FORCE_HTTPS_EXCEPTIONS"];
	}
}

- (NSString*)activityType
{
	return @"com.opa334.safariplus.activity.toggleForceHTTPS";
}

%end

%hook BookmarkFavoritesActionsView

%property (nonatomic,retain) BookmarkFavoritesActionButton *toggleForceHTTPSButton;

- (BookmarkFavoritesActionsView*)initWithFrame:(CGRect)arg1
{
	BookmarkFavoritesActionsView* orig = %orig;

	if(preferenceManager.forceHTTPSEnabled)
	{
		ToggleForceHTTPSUIActivity* activity = [[%c(ToggleForceHTTPSUIActivity) alloc] init];

		TabDocument* tabDocument = browserControllers().firstObject.tabController.activeTabDocument;

		activity.isException = [preferenceManager isURLOnHTTPSExceptionsList:[tabDocument URL]];

		orig.toggleForceHTTPSButton = [[%c(BookmarkFavoritesActionButton) alloc] init];
		[orig.toggleForceHTTPSButton configureWithActivity:activity];
		[orig.toggleForceHTTPSButton addTarget:orig action:@selector(forceHTTPSToggleButtonPressed) forControlEvents:UIControlEventTouchUpInside];

		NSMutableArray* buttons = MSHookIvar<NSMutableArray*>(self, "_buttons");
		[orig addSubview:orig.toggleForceHTTPSButton];
		[buttons addObject:orig.toggleForceHTTPSButton];
	}

	return orig;
}

- (void)layoutSubviews
{
	%orig;

	if(preferenceManager.forceHTTPSEnabled)
	{
		BookmarkFavoritesActionButton* requestDesktopSiteButton = MSHookIvar<BookmarkFavoritesActionButton*>(self, "_requestDesktopSiteButton");
		self.toggleForceHTTPSButton.frame = CGRectMake(requestDesktopSiteButton.frame.origin.x, requestDesktopSiteButton.frame.origin.y + requestDesktopSiteButton.frame.size.height, requestDesktopSiteButton.frame.size.width, requestDesktopSiteButton.frame.size.height);
		self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, requestDesktopSiteButton.frame.origin.y + (requestDesktopSiteButton.frame.size.height * 2));
	}
}

%new
- (void)forceHTTPSToggleButtonPressed
{
	TabDocument* tabDocument = browserControllers().firstObject.tabController.activeTabDocument;

	NSURL* activeURL = [tabDocument URL];

	if(activeURL)
	{
		if([preferenceManager isURLOnHTTPSExceptionsList:activeURL])
		{
			[preferenceManager removeURLFromHTTPSExceptionsList:activeURL];
			[tabDocument reload];
		}
		else
		{
			[preferenceManager addURLToHTTPSExceptionsList:activeURL];
			[tabDocument loadURL:[activeURL httpURL] userDriven:NO];
		}

		[browserControllers().firstObject setFavoritesState:0 animated:YES];
	}
}

%end

%end

void initBookmarkFavoritesActionsView()
{
	if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_9_0)
	{
		%init(iOS8);
	}
}
