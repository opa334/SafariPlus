// Copyright (c) 2017-2020 Lars Fröder

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

//Hooks for HTML5 video player

#import "../SafariPlus.h"

#import "../Defines.h"
#import "../Util.h"
#import "../Classes/SPPreferenceManager.h"
#import "../Classes/SPLocalizationManager.h"
#import "../Classes/SPDownloadManager.h"
#import "../Classes/SPDownloadInfo.h"
#import "../Classes/UIButton+ActivityIndicator.h"

%hook WKFullScreenViewController

%property (nonatomic, retain) _WKExtrinsicButton *downloadButton;

%new
- (void)downloadButtonPressed
{
	SPDownloadInfo* downloadInfo = [[SPDownloadInfo alloc] init];
	downloadInfo.sourceVideo = self;
	downloadInfo.presentationController = self;
	downloadInfo.sourceRect = [[self.downloadButton superview] convertRect:self.downloadButton.frame toView:self.view];

	[downloadManager prepareVideoDownloadForDownloadInfo:downloadInfo];
}

- (void)loadView
{
	%orig;

	if(preferenceManager.downloadManagerEnabled && preferenceManager.videoDownloadingEnabled)
	{
		WKFullscreenStackView* stackView = ((NSValue*)[self valueForKey:@"_stackView"]).nonretainedObjectValue;

		self.downloadButton = [%c(_WKExtrinsicButton) buttonWithType:UIButtonTypeSystem];
		[self.downloadButton setUpActivityIndicator];
		self.downloadButton.translatesAutoresizingMaskIntoConstraints = NO;
		self.downloadButton.adjustsImageWhenHighlighted = NO;
		[self.downloadButton.widthAnchor constraintEqualToConstant:60].active = true;
		[self.downloadButton setImage:[[UIImage imageNamed:@"VideoDownloadButtonModern"
						inBundle:SPBundle compatibleWithTraitCollection:nil]
					       imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
		self.downloadButton.tintColor = [UIColor whiteColor];
		[self.downloadButton sizeToFit];
		[self.downloadButton addTarget:self action:@selector(downloadButtonPressed) forControlEvents:UIControlEventTouchUpInside];

		[stackView addArrangedSubview:self.downloadButton applyingMaterialStyle:0 tintEffectStyle:1];
	}
}

%end

void initWKFullScreenViewController()
{
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_12_0)
	{
		%init()
	}
}
