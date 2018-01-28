// AVFullScreenPlaybackControlsViewController.xm
// (c) 2017 opa334

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

#import "../Shared.h"
#import "../Defines.h"
#import "../Classes/SPDownloadInfo.h"
#import "../Classes/SPDownloadManager.h"
#import "../Classes/SPPreferenceManager.h"
#import "../Classes/SPLocalizationManager.h"

#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVPlayer.h>
#import <AVFoundation/AVPlayerItem.h>
#import <AVKit/AVPlayerViewController.h>
#import <WebKit/WKNavigationResponse.h>

%group iOS10Down

%hook AVFullScreenPlaybackControlsViewController

%property(nonatomic,retain) AVButton *downloadButton;

- (void)viewDidLayoutSubviews
{
  %orig;

  if(preferenceManager.videoDownloadingEnabled)
  {
    //Get asset
    AVAsset* currentPlayerAsset = self.playerViewController.player.currentItem.asset;

    //Check if video is online (and not a local file)
    if(![currentPlayerAsset isKindOfClass:AVURLAsset.class])
    {
      if(!self.downloadButton)
      {
        self.downloadButton = [%c(AVButton) buttonWithType:UIButtonTypeCustom];
        UIImage* buttonImage = [UIImage imageNamed:@"videoDownload.png" inBundle:SPBundle compatibleWithTraitCollection:nil];
        [self.downloadButton setImage:buttonImage forState:UIControlStateNormal];
        [self.downloadButton setImage:[UIImage inverseColor:buttonImage] forState:UIControlStateHighlighted];

        [self.downloadButton addTarget:self action:@selector(downloadButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.downloadButton];
      }

      CGFloat height = [UIScreen mainScreen].bounds.size.height;

      CGSize buttonSize = CGSizeMake(20.6667, 22);
      CGPoint buttonPosition;

      //Plus devices: Landscape; iPad: Portrait + Landscape
      if(IS_PAD || (UIDeviceOrientationIsLandscape(UIDevice.currentDevice.orientation) && height == 414))
      {
        CGFloat x = self.view.frame.size.width - 81;

        if(iOSVersion > 8)
        {
          if(MSHookIvar<BOOL>(self, "_pictureInPictureButtonEnabled"))
          {
            x = x - 52.3334;
          }
        }

        if(!MSHookIvar<UIButton*>(self, "_mediaSelectionButton").hidden)
        {
          x = x - 47;
        }

        buttonPosition = CGPointMake(x, self.view.frame.size.height - 37);
      }
      //Plus devices: Portrait; All other devices except iPad: Portrait + Landscape
      else
      {
        buttonPosition = CGPointMake(self.view.frame.size.width - 35.75, self.view.frame.size.height - 69);
      }

      self.downloadButton.frame = CGRectMake(buttonPosition.x, buttonPosition.y, buttonSize.width, buttonSize.height);
    }
  }
}

%new
- (void)downloadButtonPressed
{
  NSString* getVideoURL;

  if(iOSVersion <= 9)
  {
    //For some reason for loops have issues prior to iOS 10 (or I'm just stupid lol)
    getVideoURL = [NSString stringWithFormat:
    @"var videos = document.querySelectorAll('video');"
    @"var i = 0;"
    @"while(i < videos.length)"
    @"{"
      @"if(videos[i].webkitDisplayingFullscreen)"
      @"{"
        @"videos[i].currentSrc;"
        @"break;"
      @"}"
      @"i++;"
    @"}"];
  }
  else
  {
    getVideoURL = [NSString stringWithFormat:
    @"var videos = document.querySelectorAll('video');"
    @"for(var video of videos)"
    @"{"
      @"if(video.webkitDisplayingFullscreen)"
      @"{"
        @"video.currentSrc;"
      @"}"
    @"}"];
  }

  NSArray<SafariWebView*>* webViews = activeWebViews();

  unsigned int webViewCount = [webViews count];
  __block unsigned int webViewPos = 0;
  __block NSError* _error;

  //Check all active webViews (2 at most) for the video URL
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
        downloadInfo.presentationController = self;
        downloadInfo.sourceRect = self.downloadButton.frame;

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
    [self presentViewController:errorAlert animated:YES completion:nil];;
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
    [self presentViewController:errorAlert animated:YES completion:nil];
  });
}

%end

%end

%ctor
{
  if(kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_11_0)
  {
    %init(iOS10Down)
  }
}
