// AVPlaybackControlsView.xm
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

#import "../SafariPlus.h"

#import "../Defines.h"
#import "../Shared.h"
#import "../Classes/SPPreferenceManager.h"
#import "../Classes/SPLocalizationManager.h"
#import "../Classes/SPDownloadManager.h"
#import "../Classes/SPDownloadInfo.h"
#import "../Classes/AVActivityButton.h"

%hook AVPlaybackControlsView

%property(nonatomic,retain) AVActivityButton *downloadButton;

%new
- (void)setUpDownloadButton
{
  if(preferenceManager.enhancedDownloadsEnabled && preferenceManager.videoDownloadingEnabled)
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
    if([self.delegate.delegate.playerController isKindOfClass:[%c(WebAVPlayerController) class]])
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
    }
  }
}

%new
- (void)downloadButtonPressed
{
  SPDownloadInfo* downloadInfo = [[SPDownloadInfo alloc] init];
  downloadInfo.sourceVideo = self;
  downloadInfo.presentationController = self.delegate.delegate.playerViewController.fullScreenViewController;
  downloadInfo.sourceRect = [self.screenModeControls.contentView convertRect:self.downloadButton.frame toView:self.delegate.delegate.playerViewController.fullScreenViewController.view];

  [downloadManager prepareVideoDownloadForDownloadInfo:downloadInfo];
}

%new
- (void)setBackgroundPlaybackActiveWithCompletion:(void (^)(void))completion
{
  WebAVPlayerController* playerController = (WebAVPlayerController*)self.delegate.delegate.playerController;

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

%group iOS11_3_up

- (instancetype)initWithFrame:(CGRect)frame
{
  self = %orig;

  [self setUpDownloadButton];

  return self;
}

%end

%group iOS11_2_down

- (instancetype)init
{
  self = %orig;

  [self setUpDownloadButton];

  return self;
}

%end

%end

void initAVPlaybackControlsView()
{
  if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0)
  {
    %init()

    if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_3)
    {
      %init(iOS11_3_up)
    }
    else
    {
      %init(iOS11_2_down)
    }
  }
}
