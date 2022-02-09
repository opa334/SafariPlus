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