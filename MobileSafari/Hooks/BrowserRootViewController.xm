// BrowserRootViewController.xm
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

#import "../Shared.h"
#import "../Classes/SPPreferenceManager.h"
#import "../Classes/SPLocalizationManager.h"

%hook BrowserRootViewController

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion
{
	if(preferenceManager.forceHTTPSEnabled)
	{
		//Apple made it really hard to get a reference to the reload options alertcontroller ;)
		if([viewControllerToPresent.view.accessibilityIdentifier isEqualToString:@"ReloadOptionsAlert"])
		{
			UIAlertController* reloadOptionsAlertController = (UIAlertController*)viewControllerToPresent;

			TabDocument* activeDocument;

			if([self respondsToSelector:@selector(browserController)])
			{
				activeDocument = self.browserController.tabController.activeTabDocument;
			}
			else
			{
				activeDocument = browserControllers().firstObject.tabController.activeTabDocument;
			}

			NSURL* activeURL = [activeDocument URL];

			if([preferenceManager isURLOnHTTPSExceptionsList:activeURL])
			{
				UIAlertAction* removeFromExceptionsAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"REMOVE_FROM_FORCE_HTTPS_EXCEPTIONS"]
									     style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
				{
					[preferenceManager removeURLFromHTTPSExceptionsList:activeURL];
					[activeDocument reload];
				}];

				[reloadOptionsAlertController addAction:removeFromExceptionsAction];
			}
			else
			{
				UIAlertAction* addToExceptionsAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"ADD_TO_FORCE_HTTPS_EXCEPTIONS"]
									style:UIAlertActionStyleDefault handler:^(UIAlertAction* action)
				{
					[preferenceManager addURLToHTTPSExceptionsList:activeURL];
					[activeDocument loadURL:[activeURL httpURL] userDriven:NO];
				}];

				[reloadOptionsAlertController addAction:addToExceptionsAction];
			}
		}
	}

	%orig;
}

%end

void initBrowserRootViewController()
{
	%init();
}
