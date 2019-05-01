// BookmarkFavoritesActionsView.xm
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
