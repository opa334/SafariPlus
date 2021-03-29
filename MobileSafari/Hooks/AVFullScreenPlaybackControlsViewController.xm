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

//Hooks for iOS 10 and below

#import "../SafariPlus.h"
#import "Extensions.h"

#import "../Util.h"
#import "../Defines.h"
#import "../Classes/SPDownloadInfo.h"
#import "../Classes/SPDownloadManager.h"
#import "../Classes/SPPreferenceManager.h"
#import "../Classes/SPLocalizationManager.h"
#import "../Classes/UIButton+ActivityIndicator.h"

#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVPlayer.h>
#import <AVFoundation/AVPlayerItem.h>
#import <AVKit/AVPlayerViewController.h>
#import <WebKit/WKNavigationResponse.h>

@interface UIView ()
- (void)_setDrawsAsBackdropOverlay:(BOOL)arg1;
@end

%hook AVFullScreenPlaybackControlsViewController

%property (nonatomic,retain) AVButton *downloadButton;
%property (nonatomic,retain) NSMutableArray *additionalLayoutConstraints;

- (void)loadView
{
	%orig;

	if(preferenceManager.downloadManagerEnabled && preferenceManager.videoDownloadingEnabled)
	{
		//Get asset
		AVAsset* currentPlayerAsset = self.playerViewController.player.currentItem.asset;

		//Check if video is online (and not a local file)
		if(![currentPlayerAsset isKindOfClass:AVURLAsset.class])
		{
			self.downloadButton = [%c(AVButton) buttonWithType:UIButtonTypeCustom];
			[self.downloadButton setUpActivityIndicator];
			self.downloadButton.translatesAutoresizingMaskIntoConstraints = NO;
			UIImage* buttonImage = [UIImage imageNamed:@"VideoDownloadButton" inBundle:SPBundle compatibleWithTraitCollection:nil];
			[self.downloadButton setImage:buttonImage forState:UIControlStateNormal];
			[self.downloadButton setImage:[UIImage inverseColor:buttonImage] forState:UIControlStateHighlighted];
			[self.downloadButton addTarget:self action:@selector(downloadButtonPressed) forControlEvents:UIControlEventTouchUpInside];
			[self.downloadButton _setDrawsAsBackdropOverlay:YES];

			UIView* lowerControlsRightSubContainerView = MSHookIvar<UIView*>(self, "_lowerControlsRightSubContainerView");
			UIView* backdropContentView = [lowerControlsRightSubContainerView superview];

			[backdropContentView addSubview:self.downloadButton];
		}
	}
}

- (void)updateViewConstraints
{
	%orig;

	if(self.downloadButton)
	{
		BOOL bottomControlsSingleRowLayoutPossible = MSHookIvar<BOOL>(self, "_bottomControlsSingleRowLayoutPossible");
		UIView* lowerControlsRightSubContainerView = MSHookIvar<UIView*>(self, "_lowerControlsRightSubContainerView");
		UIView* backdropContentView = [lowerControlsRightSubContainerView superview];

		if(!self.additionalLayoutConstraints)
		{
			self.additionalLayoutConstraints = [NSMutableArray new];
		}
		else
		{
			[backdropContentView removeConstraints:self.additionalLayoutConstraints];
			[self.additionalLayoutConstraints removeAllObjects];
		}

		NSDictionary* views =
			@{
				@"downloadButton" : self.downloadButton,
				@"lowerControlsRightSubContainerView" : lowerControlsRightSubContainerView
		};

		if(bottomControlsSingleRowLayoutPossible)
		{
			[self.additionalLayoutConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[downloadButton(22)]-25-[lowerControlsRightSubContainerView]" options:0 metrics:nil views:views]];
			[self.additionalLayoutConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-14-[downloadButton(22)]" options:0 metrics:nil views:views]];
		}
		else
		{
			[self.additionalLayoutConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[downloadButton(22)]-15-|" options:0 metrics:nil views:views]];
			[self.additionalLayoutConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-11-[downloadButton(22)]" options:0 metrics:nil views:views]];
		}

		[backdropContentView addConstraints:self.additionalLayoutConstraints];
	}
}

%new
- (void)downloadButtonPressed
{
	SPDownloadInfo* downloadInfo = [[SPDownloadInfo alloc] init];
	downloadInfo.sourceVideo = self;
	downloadInfo.presentationController = self;
	downloadInfo.sourceRect = [[self.downloadButton superview] convertRect:self.downloadButton.frame toView:self.view];

	[downloadManager prepareVideoDownloadForDownloadInfo:downloadInfo];
}

%end

void initAVFullScreenPlaybackControlsViewController()
{
	if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_11_0)
	{
		%init();
	}
}
