// AVFullScreenPlaybackControlsViewController.xm
// (c) 2018 opa334

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

//Hooks for iOS 10 and below

#import "../SafariPlus.h"

#import "../Shared.h"
#import "../Defines.h"
#import "../Classes/SPDownloadInfo.h"
#import "../Classes/SPDownloadManager.h"
#import "../Classes/SPPreferenceManager.h"
#import "../Classes/SPLocalizationManager.h"
#import "../Classes/AVActivityButton.h"

#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVPlayer.h>
#import <AVFoundation/AVPlayerItem.h>
#import <AVKit/AVPlayerViewController.h>
#import <WebKit/WKNavigationResponse.h>

@interface UIView ()
- (void)_setDrawsAsBackdropOverlay:(BOOL)arg1;
@end

%hook AVFullScreenPlaybackControlsViewController

%property(nonatomic,retain) AVActivityButton *downloadButton;
%property(nonatomic,retain) NSMutableArray *additionalLayoutConstraints;

- (void)loadView
{
	%orig;

	if(preferenceManager.enhancedDownloadsEnabled && preferenceManager.videoDownloadingEnabled)
	{
		//Get asset
		AVAsset* currentPlayerAsset = self.playerViewController.player.currentItem.asset;

		//Check if video is online (and not a local file)
		if(![currentPlayerAsset isKindOfClass:AVURLAsset.class])
		{
			self.downloadButton = [%c(AVActivityButton) buttonWithType:UIButtonTypeCustom];
			self.downloadButton.translatesAutoresizingMaskIntoConstraints = NO;
			UIImage* buttonImage = [UIImage imageNamed:@"VideoDownloadButton.png" inBundle:SPBundle compatibleWithTraitCollection:nil];
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
	downloadInfo.sourceRect = self.downloadButton.frame;

	[downloadManager prepareVideoDownloadForDownloadInfo:downloadInfo];
}

%new
- (void)setBackgroundPlaybackActiveWithCompletion: (void (^)(void))completion
{
	WebAVPlayerController* playerController = (WebAVPlayerController*)self.playerController;

	if(!playerController.playing && isnan(playerController.timing.anchorTimeStamp))
	{
		[playerController play:nil];
		[playerController pause:nil];
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), completion);
	}
	else
	{
		completion();
	}
}

%end

void initAVFullScreenPlaybackControlsViewController()
{
	if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_11_0)
	{
		%init();
	}
}
