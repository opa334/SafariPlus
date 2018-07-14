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

%hook AVPlaybackControlsView

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

%group iOS11

%hook AVPlaybackControlsView

%property(nonatomic,retain) AVButton *downloadButton;

%new
- (void)setUpDownloadButton
{
  if(preferenceManager.enhancedDownloadsEnabled && preferenceManager.videoDownloadingEnabled)
  {
    self.downloadButton = [[%c(AVButton) alloc] init];

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
      if(iOSVersion >= 11.3)
      {
        if(![self.screenModeControls.stackView.arrangedSubviews containsObject:self.downloadButton])
        {
          [self.screenModeControls.stackView addArrangedSubview:self.downloadButton];
        }
      }
      else
      {
        if(![self.screenModeControls.contentView.arrangedSubviews containsObject:self.downloadButton])
        {
          [self.screenModeControls.contentView addArrangedSubview:self.downloadButton];
        }
      }
    }
  }
}

%new
- (void)downloadButtonPressed
{
  NSString* getVideoURL = [NSString stringWithFormat:
  @"var videos = document.querySelectorAll('video');"
  @"for(var video of videos)"
  @"{"
    @"if(video.webkitDisplayingFullscreen)"
    @"{"
      @"video.currentSrc;"
    @"}"
  @"}"];

  NSArray<SafariWebView*>* webViews = activeWebViews();

  unsigned int webViewCount = [webViews count];
  __block unsigned int webViewPos = 0;
  __block NSError* _error;

  for(SafariWebView* webView in webViews)
  {
    [webView evaluateJavaScript:getVideoURL completionHandler:^(id result, NSError *error)
    {
      webViewPos++;
      if(result)
      {
        NSURL* videoURL = [NSURL URLWithString:result];
        NSURLRequest* request = [NSURLRequest requestWithURL:videoURL];

        SPDownloadInfo* downloadInfo = [[SPDownloadInfo alloc] initWithRequest:request];
        downloadInfo.filename = [videoURL lastPathComponent];
        downloadInfo.isVideo = YES;
        downloadInfo.presentationController = self.delegate.delegate.playerViewController.fullScreenViewController;
        downloadInfo.sourceRect = [self.screenModeControls.contentView convertRect:self.downloadButton.frame toView:self.delegate.delegate.playerViewController.fullScreenViewController.view];

        [downloadManager presentDownloadAlertWithDownloadInfo:downloadInfo];
      }
      else if(error)
      {
        _error = error;
        if(webViewPos == webViewCount)
        {
          [self presentErrorAlertWithError:error];
        }
      }
      else if(webViewPos == webViewCount)
      {
        if(_error)
        {
          [self presentErrorAlertWithError:_error];
        }
        else
        {
          [self presentNotFoundError];
        }
      }
    }];
  }
}

%new
- (void)presentErrorAlertWithError:(NSError*)error
{
  UIAlertController *errorAlert = [UIAlertController
    alertControllerWithTitle:[localizationManager
    localizedSPStringForKey:@"ERROR"] message:[NSString
    stringWithFormat:@"%@", error.userInfo]
    preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction *closeAction = [UIAlertAction actionWithTitle:[localizationManager
    localizedSPStringForKey:@"CLOSE"]
    style:UIAlertActionStyleCancel handler:nil];

  [errorAlert addAction:closeAction];

  dispatch_async(dispatch_get_main_queue(),
  ^{
    [self.delegate.delegate.playerViewController.fullScreenViewController presentViewController:errorAlert animated:YES completion:nil];;
  });
}

%new
- (void)presentNotFoundError
{
  UIAlertController *errorAlert = [UIAlertController
    alertControllerWithTitle:[localizationManager
    localizedSPStringForKey:@"ERROR"] message:[localizationManager
    localizedSPStringForKey:@"VIDEO_URL_NOT_FOUND"]
    preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction *closeAction = [UIAlertAction actionWithTitle:[localizationManager
    localizedSPStringForKey:@"CLOSE"]
    style:UIAlertActionStyleCancel handler:nil];

  [errorAlert addAction:closeAction];

  dispatch_async(dispatch_get_main_queue(),
  ^{
    [self.delegate.delegate.playerViewController.fullScreenViewController presentViewController:errorAlert animated:YES completion:nil];
  });
}

%end
%end

%ctor
{
  if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0)
  {
    %init(iOS11)

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
