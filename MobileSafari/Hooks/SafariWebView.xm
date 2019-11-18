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

#import "../SafariPlus.h"
#import "../Defines.h"
#import "../Util.h"
#import "../Classes/SPPreferenceManager.h"

#import <WebKit/WKWebViewConfiguration.h>

#define cSelf ((SafariWebView*)self)

%hook SafariWebView

%new
- (void)updateFullscreenEnabledPreference
{
	if([cSelf.configuration.preferences respondsToSelector:@selector(_setFullScreenEnabled:)])
	{
		//Enable HTML5 player for YouTube, disable for any other site
		cSelf.configuration.preferences._fullScreenEnabled = [cSelf.URL.host containsString:@"youtube.com"];
	}
}

- (void)_didCommitLoadForMainFrame
{
	%orig;

	if(preferenceManager.forceNativePlayerEnabled && kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_12_0)
	{
		[self updateFullscreenEnabledPreference];
	}
}

%new
- (void)setDesktopModeState:(NSInteger)desktopModeState
{
	NSInteger prevState = cSelf.desktopModeState;

	if(prevState != desktopModeState)	//mobile
	{
		objc_setAssociatedObject(self, @selector(desktopModeState), [NSNumber numberWithInteger:desktopModeState], OBJC_ASSOCIATION_RETAIN_NONATOMIC);

		NSString* userAgentToSet = @"";

		if(desktopModeState == 1)
		{
			if(preferenceManager.customUserAgentEnabled && ![preferenceManager.customUserAgent isEqualToString:@""])
			{
				userAgentToSet = preferenceManager.customUserAgent;
			}
		}
		else if(desktopModeState == 2)	//desktop
		{
			if(preferenceManager.customDesktopUserAgentEnabled && ![preferenceManager.customDesktopUserAgent isEqualToString:@""])
			{
				userAgentToSet = preferenceManager.customDesktopUserAgent;
			}
			else
			{
				NSArray<NSString*>* userAgentComponents = [cSelf._applicationNameForUserAgent componentsSeparatedByString:@" "];

				//userAgentComponents[0] = Version/<iOS Version>
				//userAgentComponents[1] = Mobile/<Build Number> (Not needed for desktop agent)
				//userAgentComponents[2] = Safari/<Safari Version>

				NSString* webKitVersion = [userAgentComponents[2] componentsSeparatedByString:@"/"].lastObject;	//Same as Safari Version
				NSInteger macOSVersion = [[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."].firstObject integerValue] + 2;

				userAgentToSet = [NSString stringWithFormat:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_%ld_0) AppleWebKit/%@ (KHTML, like Gecko) %@ %@", (long)macOSVersion, webKitVersion, userAgentComponents[0], userAgentComponents[2]];
			}
		}

		if([cSelf respondsToSelector:@selector(_setCustomUserAgent:)])
		{
			[cSelf _setCustomUserAgent:userAgentToSet];
		}
		else
		{
			[cSelf setCustomUserAgent:userAgentToSet];
		}
	}
}

%new
- (NSInteger)desktopModeState
{
	return [objc_getAssociatedObject(self, @selector(desktopModeState)) integerValue];
}

%new
- (void)sp_updateCustomUserAgent
{
	if(preferenceManager.desktopButtonEnabled)
	{
		TabDocument* tabDocument;

		if([self respondsToSelector:@selector(delegate)])
		{
			tabDocument = cSelf.delegate;
		}
		else
		{
			tabDocument = cSelf.UIDelegate;
		}

		BrowserController* browserController = browserControllerForTabDocument(tabDocument);

		BOOL desktopButtonSelected = browserController.tabController.desktopButtonSelected;

		cSelf.desktopModeState = (NSInteger)desktopButtonSelected + 1;
	}
	else if(preferenceManager.customUserAgentEnabled && ![preferenceManager.customUserAgent isEqualToString:@""])
	{
		if([cSelf respondsToSelector:@selector(_setCustomUserAgent:)])
		{
			[cSelf _setCustomUserAgent:preferenceManager.customUserAgent];
		}
		else
		{
			[cSelf setCustomUserAgent:preferenceManager.customUserAgent];
		}
	}
}

%new
- (void)sp_applyCustomUserAgent
{
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_3)
	{
		//Calling reload on webView does not apply the user agent on iOS 11.3 and above, no idea why, this is the proper fix for it
		[cSelf evaluateJavaScript:@"window.location.reload(true)" completionHandler:nil];
	}
	else
	{
		[cSelf reload];
	}
}

%end

void initSafariWebView()
{
	Class SafariWebViewClass = NSClassFromString(@"SafariWebView");

	if(!SafariWebViewClass)
	{
		SafariWebViewClass = NSClassFromString(@"_SFWebView");
	}

	%init(SafariWebView=SafariWebViewClass);
}
