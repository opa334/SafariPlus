#import "../SafariPlus.h"
#import "../Defines.h"
#import "../Util.h"
#import "../Classes/SPPreferenceManager.h"

#define cSelf ((SafariWebView*)self)

//static BOOL fakeUserAgent = YES;

/*%hook NSUserDefaults

   - (id)objectForKey:(NSString*)key
   {
        if(fakeUserAgent && (preferenceManager.desktopButtonEnabled || preferenceManager.customUserAgentEnabled) && [key isEqualToString:@"UserAgent"])
        {
                NSLog(@"old code");
                return @"FAKE";
        }

        return %orig;
   }

   %end

   //Only used if SafariServices exists (iOS 9 and above)
   NSString *(*orig_SFCustomUserAgentStringIfNeeded)();

   NSString* custom_SFCustomUserAgentStringIfNeeded()
   {
        if(fakeUserAgent && (preferenceManager.desktopButtonEnabled || preferenceManager.customUserAgentEnabled))
        {
                NSLog(@"faked user agent");
                return @"FAKE";
        }

        NSLog(@"???");

        return orig_SFCustomUserAgentStringIfNeeded();
   }*/

%hook SafariWebView

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
		//Calling reload on webView does apply the user agent on iOS 11.3 and above, no idea why, this is the proper fix for it
		[cSelf evaluateJavaScript:@"window.location.reload(true)" completionHandler:nil];
	}
	else
	{
		[cSelf reload];
	}

	//[[cSelf _currentContentView] _zoomOutWithOrigin:CGPointMake(0,0)];
}

/*- (void)_setCustomUserAgent:(NSString*)customUserAgent
   {
        if([customUserAgent isEqualToString:@"FAKE"] && (preferenceManager.desktopButtonEnabled || preferenceManager.customUserAgentEnabled))
        {
                [self sp_updateCustomUserAgent];
        }
        else
        {
                %orig;
        }
   }

   - (void)setCustomUserAgent:(NSString*)customUserAgent
   {
        if([customUserAgent isEqualToString:@"FAKE"] && (preferenceManager.desktopButtonEnabled || preferenceManager.customUserAgentEnabled))
        {
                [self sp_updateCustomUserAgent];
        }
        else
        {
                %orig;
        }
   }*/

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
