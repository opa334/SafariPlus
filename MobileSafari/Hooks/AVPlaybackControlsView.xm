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

//Hooks for iOS 11 and above

#import "../SafariPlus.h"

#import "../Defines.h"
#import "../Util.h"
#import "../Classes/SPPreferenceManager.h"
#import "../Classes/SPLocalizationManager.h"
#import "../Classes/SPDownloadManager.h"
#import "../Classes/SPDownloadInfo.h"
#import "../Classes/UIButton+ActivityIndicator.h"

%hook AVPlaybackControlsView

%property (nonatomic,retain) AVButton *downloadButton;

%new
- (void)setUpDownloadButton
{
	if(preferenceManager.downloadManagerEnabled && preferenceManager.videoDownloadingEnabled && !self.downloadButton)
	{
		if([%c(AVButton) respondsToSelector:@selector(buttonWithAccessibilityIdentifier:)])
		{
			self.downloadButton = [%c(AVButton) buttonWithAccessibilityIdentifier:@"Download"];
		}
		else
		{
			self.downloadButton = [%c(AVButton) buttonWithType:UIButtonTypeCustom];
		}
		[self.downloadButton setUpActivityIndicator];

		UIImage* downloadImage;

		if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0)
		{
			downloadImage = [UIImage systemImageNamed:@"arrow.down.circle"];
		}
		else
		{
			downloadImage = [[UIImage imageNamed:@"VideoDownloadButtonModern" inBundle:SPBundle compatibleWithTraitCollection:nil]
				imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		}		

		[self.downloadButton setImage:downloadImage forState:UIControlStateNormal];

		[self.downloadButton addTarget:self action:@selector(downloadButtonPressed)
		 forControlEvents:UIControlEventTouchUpInside];

		self.downloadButton.adjustsImageWhenHighlighted = NO;
		self.downloadButton.translatesAutoresizingMaskIntoConstraints = NO;
		[self.downloadButton.widthAnchor constraintEqualToConstant:60].active = true;

		if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_13_0)
		{
			[%c(AVBackdropView) applySecondaryGlyphTintToView:self.downloadButton];
		}
	}
}

- (void)layoutSubviews
{
	%orig;
	if(preferenceManager.downloadManagerEnabled && preferenceManager.videoDownloadingEnabled)
	{
		AVPlaybackControlsController* playbackControlsController;

		if([self respondsToSelector:@selector(delegate)])
		{
			playbackControlsController = self.delegate.delegate;
		}
		else
		{
			playbackControlsController = self.transportControlsView.delegate;	//iOS 12
		}

		if([playbackControlsController.playerController isKindOfClass:[%c(WebAVPlayerController) class]])
		{
			UIStackView* stackView;

			if([self.screenModeControls respondsToSelector:@selector(stackView)])
			{
				stackView = self.screenModeControls.stackView;
			}
			else
			{
				stackView = self.screenModeControls.contentView;
			}

			if(![stackView.arrangedSubviews containsObject:self.downloadButton])
			{
				[stackView addArrangedSubview:self.downloadButton];
			}

			if(self.downloadButton.hidden)	//Solve a layout issue caused by hacky solutions with more hacky solutions
			{
				AVPlaybackControlsView* __weak weakSelf = self;
				dispatch_async(dispatch_get_main_queue(),^
				{
					AVPlaybackControlsView* strongSelf = weakSelf;
					if (strongSelf)
					{
						strongSelf.downloadButton.included = YES;
						strongSelf.downloadButton.hidden = NO;
					}
				});
			}
		}
	}
}

%new
- (void)downloadButtonPressed
{
	AVPlaybackControlsController* playbackControlsController;

	if([self respondsToSelector:@selector(delegate)])
	{
		playbackControlsController = self.delegate.delegate;
	}
	else
	{
		playbackControlsController = self.transportControlsView.delegate;	//iOS 12
	}

	SPDownloadInfo* downloadInfo = [[SPDownloadInfo alloc] init];
	downloadInfo.sourceVideo = self;
	downloadInfo.presentationController = playbackControlsController.playerViewController.fullScreenViewController;
	downloadInfo.sourceRect = [[self.downloadButton superview] convertRect:self.downloadButton.frame toView:downloadInfo.presentationController.view];

	[downloadManager prepareVideoDownloadForDownloadInfo:downloadInfo];
}

- (instancetype)initWithFrame:(CGRect)arg1 styleSheet:(id)arg2	//iOS 13 and above
{
	self = %orig;

	[self setUpDownloadButton];

	return self;
}

- (instancetype)initWithFrame:(CGRect)arg1 styleSheet:(id)arg2 captureView:(id)arg3	//iOS 12 and above
{
	self = %orig;

	[self setUpDownloadButton];

	return self;
}

- (instancetype)initWithFrame:(CGRect)frame	//iOS 11.3 - 11.4.1
{
	self = %orig;

	[self setUpDownloadButton];

	return self;
}

- (instancetype)init	//iOS 11.0 - 11.2.6
{
	self = %orig;

	[self setUpDownloadButton];

	return self;
}

%end

void initAVPlaybackControlsView()
{
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0)
	{
		%init()
	}
}
