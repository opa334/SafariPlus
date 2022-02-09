// Copyright (c) 2017-2021 Lars Fröder

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
- (void)sp_setUpDownloadButton
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

		[self.downloadButton addTarget:self action:@selector(sp_downloadButtonPressed)
		 forControlEvents:UIControlEventTouchUpInside];

		if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_13_0)
		{
			[%c(AVBackdropView) applySecondaryGlyphTintToView:self.downloadButton];
		}

		self.downloadButton.included = NO;
		self.downloadButton.collapsed = YES;
		if([self.downloadButton respondsToSelector:@selector(layoutAttributes)])
		{
			self.downloadButton.layoutAttributes.displayPriority = 2;
		}

		if([self respondsToSelector:@selector(defaultDisplayModeControls)])
		{
			[self setValue:[self.defaultDisplayModeControls arrayByAddingObject:self.downloadButton] forKey:@"_defaultDisplayModeControls"];
		}
		else // ios 11
		{
			[self.screenModeControls.stackView addArrangedSubview:self.downloadButton];
		}
	}
}


%new
- (void)sp_downloadButtonPressed
{
	AVPlaybackControlsController* playbackControlsController = [self sp_getPlaybackControlsController];

	SPDownloadInfo* downloadInfo = [[SPDownloadInfo alloc] init];
	downloadInfo.sourceVideo = self;
	downloadInfo.presentationController = playbackControlsController.playerViewController.fullScreenViewController;
	downloadInfo.sourceRect = [[self.downloadButton superview] convertRect:self.downloadButton.frame toView:downloadInfo.presentationController.view];

	[downloadManager prepareVideoDownloadForDownloadInfo:downloadInfo sourceWindow:self.window];
}

%new
- (AVPlaybackControlsController*)sp_getPlaybackControlsController
{
	if([self respondsToSelector:@selector(transportControlsView)])
	{
		return self.transportControlsView.delegate; //iOS >= 12
	}
	else
	{
		return self.delegate.delegate; //iOS 11
	}
}

%new
- (void)sp_playbackControlsAdditionalUpdatesWithoutAnimation:(BOOL)withoutAnimation
{
	if(preferenceManager.downloadManagerEnabled && preferenceManager.videoDownloadingEnabled)
	{
		if([[self sp_getPlaybackControlsController].playerController isKindOfClass:[%c(WebAVPlayerController) class]])
		{
			void (^updateBlock)(void) = ^
			{
				self.downloadButton.included = YES;
				self.downloadButton.collapsed = NO;
				[self setNeedsLayout];
			};

			if(withoutAnimation)
			{
				[UIView performWithoutAnimation:updateBlock];
			}
			else
			{
				updateBlock();
			}
		}
	}
}

- (void)layoutSubviews
{
	%orig;

	if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_13_0)
	{
		[self sp_playbackControlsAdditionalUpdatesWithoutAnimation:NO];	
	}

	self.downloadButton.extrinsicContentSize = self.doneButton.extrinsicContentSize;

	return;
}

%group iOS13_to_13_7

- (void)_updatePlaybackControlsContainerVisibility:(/*^block*/id)arg1
{
	%orig;
	[self sp_playbackControlsAdditionalUpdatesWithoutAnimation:YES];
}

%end

%group iOS14Up

- (void)_updatePlaybackControlsContainerVisibilityAnimated:(BOOL)animated additionalActions:(/*^block*/id)arg2
{
	%orig;
	[self sp_playbackControlsAdditionalUpdatesWithoutAnimation:YES];
}

%end

%group iOS13Up

- (instancetype)initWithFrame:(CGRect)arg1 styleSheet:(id)arg2
{
	self = %orig;

	[self sp_setUpDownloadButton];

	return self;
}

%end

%group iOS12_to_12_4_9

- (instancetype)initWithFrame:(CGRect)arg1 styleSheet:(id)arg2 captureView:(id)arg3	
{
	self = %orig;

	[self sp_setUpDownloadButton];

	return self;
}

%end

%group iOS11_3_to_11_4_1

- (instancetype)initWithFrame:(CGRect)frame
{
	self = %orig;

	[self sp_setUpDownloadButton];

	return self;
}

%end

%group iOS11_0_to_11_2_6

- (instancetype)init
{
	self = %orig;

	[self sp_setUpDownloadButton];

	return self;
}

%end

%end

void initAVPlaybackControlsView()
{
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0)
	{
		if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_11_3)
		{
			%init(iOS11_0_to_11_2_6);
		}
		else if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_12_0)
		{
			%init(iOS11_3_to_11_4_1);
		}
		else if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_13_0)
		{
			%init(iOS12_to_12_4_9);
		}
		else
		{
			%init(iOS13Up);
		}

		if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_14_0)
		{
			%init(iOS14Up);
		}
		else if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0)
		{
			%init(iOS13_to_13_7);
		}

		%init()
	}
}
