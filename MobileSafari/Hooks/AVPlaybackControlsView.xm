// AVPlaybackControlsView.xm
// (c) 2017 - 2019 opa334

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

//Hooks for iOS 11 and above

#import "../SafariPlus.h"

#import "../Defines.h"
#import "../Shared.h"
#import "../Classes/SPPreferenceManager.h"
#import "../Classes/SPLocalizationManager.h"
#import "../Classes/SPDownloadManager.h"
#import "../Classes/SPDownloadInfo.h"
#import "../Classes/AVActivityButton.h"

%hook AVPlaybackControlsView

%property (nonatomic,retain) AVActivityButton *downloadButton;

%new
- (void)setUpDownloadButton
{
	if(preferenceManager.enhancedDownloadsEnabled && preferenceManager.videoDownloadingEnabled && !self.downloadButton)
	{
		self.downloadButton = [%c(AVActivityButton) buttonWithType:UIButtonTypeCustom];

		[self.downloadButton setImage:[[UIImage imageNamed:@"VideoDownloadButton.png"
						inBundle:SPBundle compatibleWithTraitCollection:nil]
					       imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
		 forState:UIControlStateNormal];

		[self.downloadButton addTarget:self action:@selector(downloadButtonPressed)
		 forControlEvents:UIControlEventTouchUpInside];

		self.downloadButton.adjustsImageWhenHighlighted = NO;
		[self.downloadButton.widthAnchor constraintEqualToConstant:60].active = true;

		self.downloadButton.tintColor = [UIColor colorWithWhite:1 alpha:0.55];
	}
}

- (void)layoutSubviews
{
	%orig;
	if(preferenceManager.enhancedDownloadsEnabled && preferenceManager.videoDownloadingEnabled)
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
	downloadInfo.sourceRect = [self.screenModeControls.contentView convertRect:self.downloadButton.frame toView:playbackControlsController.playerViewController.fullScreenViewController.view];

	[downloadManager prepareVideoDownloadForDownloadInfo:downloadInfo];
}

%new
- (void)setBackgroundPlaybackActiveWithCompletion:(void (^)(void))completion
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

	WebAVPlayerController* playerController = (WebAVPlayerController*)playbackControlsController.playerController;

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

- (id)initWithFrame:(CGRect)arg1 styleSheet:(id)arg2 captureView:(id)arg3	//iOS 12 and above
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
