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

#import "../Util.h"
#import "../Classes/SPPreferenceManager.h"
#import "../Classes/SPLocalizationManager.h"

#if !NO_CEPHEI || SIMJECT

%hook BrowserRootViewController

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion
{
	//Apple made it really hard to get a reference to the reload options alertcontroller ;)
	if(preferenceManager.forceHTTPSEnabled)
	{
		if([NSStringFromClass(viewControllerToPresent.class) isEqualToString:@"_SFSettingsAlertController"])
		{
			_SFSettingsAlertController* settingsAlertController = (_SFSettingsAlertController*)viewControllerToPresent;

			TabDocument* activeDocument = self.browserController.tabController.activeTabDocument;

			NSURL* activeURL = [activeDocument URL];

			NSMutableArray* items;

			if([settingsAlertController respondsToSelector:@selector(_rootContentController)])
			{
				items = [[settingsAlertController _rootContentController] valueForKey:@"_items"];
			}
			else
			{
				items = [settingsAlertController valueForKey:@"_items"];
			}			

			if([preferenceManager isURLOnHTTPSExceptionsList:activeURL])
			{
				_SFSettingsAlertItem* removeFromExceptionsButton = [%c(_SFSettingsAlertItem) buttonWithTitle:[localizationManager localizedSPStringForKey:@"REMOVE_FROM_FORCE_HTTPS_EXCEPTIONS"] textStyle:UIFontTextStyleBody icon:[UIImage systemImageNamed:@"minus"] handler:^
				{
					[preferenceManager removeURLFromHTTPSExceptionsList:activeURL];
					[activeDocument reload];
					[settingsAlertController dismissViewControllerAnimated:YES completion:nil];
				}];

				[items insertObject:removeFromExceptionsButton atIndex:[items count] - 1];
			}
			else
			{
				_SFSettingsAlertItem* addToExceptionsButton = [%c(_SFSettingsAlertItem) buttonWithTitle:[localizationManager localizedSPStringForKey:@"ADD_TO_FORCE_HTTPS_EXCEPTIONS"] textStyle:UIFontTextStyleBody icon:[UIImage systemImageNamed:@"plus"] handler:^
				{
					[preferenceManager addURLToHTTPSExceptionsList:activeURL];
					[activeDocument loadURL:[activeURL httpURL] userDriven:NO];
					[settingsAlertController dismissViewControllerAnimated:YES completion:nil];
				}];

				[items insertObject:addToExceptionsButton atIndex:[items count] - 1];
			}
		}
		else if([viewControllerToPresent.view.accessibilityIdentifier isEqualToString:@"ReloadOptionsAlert"])
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

#endif

void initBrowserRootViewController()
{
	#if !NO_CEPHEI || SIMJECT
	%init();
	#endif
}
