#import "../SafariPlus.h"

#import "../Defines.h"
#import "../Shared.h"
#import "../Classes/SPPreferenceManager.h"
#import "../Classes/SPLocalizationManager.h"
#import "../Classes/SPDownloadManager.h"
#import "../Classes/SPDownloadInfo.h"

%group iOS11

%hook AVTransportControlsView

%property(nonatomic,retain) AVButton *downloadButton;

- (void)layoutSubviews
{
  %orig;

  if(preferenceManager.videoDownloadingEnabled)
  {
    if([self.delegate.playerController isKindOfClass:[%c(WebAVPlayerController) class]])
    {
      if(!self.downloadButton)
      {
        self.downloadButton = [%c(AVButton) buttonWithType:UIButtonTypeCustom];
        UIImage* buttonImage = [UIImage imageNamed:@"videoDownload.png" inBundle:SPBundle compatibleWithTraitCollection:nil];
        [self.downloadButton setImage:[UIImage inverseColor:buttonImage] forState:UIControlStateNormal];

        [self.downloadButton addTarget:self action:@selector(downloadButtonPressed) forControlEvents:UIControlEventTouchUpInside];
      }

      if(IS_PAD || UIDeviceOrientationIsLandscape(UIDevice.currentDevice.orientation))
      {
        //Easy solution :)
        [self.backdropView.contentView addArrangedSubview:self.downloadButton];
      }
      else
      {
        if(![self.downloadButton isDescendantOfView:self.backdropView])
        {
          [self.backdropView addSubview:self.downloadButton];
        }

        CGSize buttonSize = CGSizeMake(20, 47);
        CGFloat x = self.backdropView.frame.size.width - 36;
        CGFloat y = self.backdropView.frame.size.height - 51;

        self.downloadButton.frame = CGRectMake(x,y,buttonSize.width, buttonSize.height);
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
      downloadInfo.alternatePresentationController = self.delegate.playerViewController.fullScreenViewController;
      downloadInfo.sourceRect = [self convertRect:self.downloadButton.frame toView:self.delegate.playerViewController.fullScreenViewController.view];

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
    [self.delegate.playerViewController.fullScreenViewController presentViewController:errorAlert animated:YES completion:nil];;
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
    [self.delegate.playerViewController.fullScreenViewController presentViewController:errorAlert animated:YES completion:nil];
  });
}

%end

%end

%ctor
{
  if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0)
  {
    %init(iOS11)
  }
}
