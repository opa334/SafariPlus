// AVFullScreenPlaybackControlsViewController.xm
// (c) 2017 opa334

#import "../SafariPlus.h"
#import "../Shared.h"

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
          if(MSHookIvar<BOOL>(self, "_showsMediaSelectionButton"))
          {
            x = x - 47;
          }
        }
        else
        {
          //Different approach needed on iOS 8 for some reason
          if(!MSHookIvar<UIButton*>(self, "_mediaSelectionButton").hidden)
          {
            x = x - 47;
          }
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

  switch(iOSVersion)
  {
    //For some reason for loops have issues prior to iOS 10 (or I'm just stupid lol)
    case 8:
    case 9:
    getVideoURL = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@",
    @"var videos = document.querySelectorAll('video');",
    @"var i = 0;",
    @"while(i < videos.length)",
    @"{",
      @"if(videos[i].webkitDisplayingFullscreen)",
      @"{",
        @"videos[i].currentSrc;",
        @"break;",
      @"}",
      @"i++;"
    @"}"];
    break;

    case 10:
    getVideoURL = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@",
    @"var videos = document.querySelectorAll('video');",
    @"for(var video of videos)",
    @"{",
      @"if(video.webkitDisplayingFullscreen)",
      @"{",
        @"video.currentSrc;",
      @"}",
    @"}"];
    break;
  }

  SafariWebView* webView = activeWebView();
  [webView evaluateJavaScript:getVideoURL completionHandler:^(id result, NSError *error)
  {
    if(result)
    {
      NSURL* videoURL = [NSURL URLWithString:result];
      NSURLRequest* request = [NSURLRequest requestWithURL:videoURL];

      SPDownloadInfo* downloadInfo = [[SPDownloadInfo alloc] initWithRequest:request];
      downloadInfo.filename = [videoURL lastPathComponent];
      downloadInfo.isVideo = YES;
      downloadInfo.alternatePresentationController = self;
      downloadInfo.sourceRect = self.downloadButton.frame;

      [[SPDownloadManager sharedInstance] presentDownloadAlertWithDownloadInfo:downloadInfo];
    }
    else if(error)
    {
      [self presentErrorAlertWithError:error];
    }
    else
    {
      [self presentNotFoundError];
    }
  }];
}

%new
- (void)presentErrorAlertWithError:(NSError*)error
{
  //NSString* exception = [error.userInfo
    //objectForKey:@"WKJavaScriptExceptionMessage"];

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
