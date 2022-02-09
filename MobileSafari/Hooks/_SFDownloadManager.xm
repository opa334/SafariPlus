#import "../Defines.h"
#import "../SafariPlus.h"
#import "../Classes/SPPreferenceManager.h"
#import "../Util.h"

%hook _SFDownloadManager

- (void)downloadShouldContinueAfterReceivingResponse:(_SFDownload*)download decisionHandler:(void (^)(BOOL))decisionHandler
{
	if(preferenceManager.skipDownloadDialog)
	{
		NSDictionary* downloadsToDeferAdding = [self valueForKey:@"_downloadsToDeferAdding"];
		if([downloadsToDeferAdding objectForKey:download])
		{
			[self _addDownload:download];
			decisionHandler(YES);
			return;
		}
	}

	%orig;
}

%end

void init_SFDownloadManager()
{
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0)
	{
		%init();
	}
}