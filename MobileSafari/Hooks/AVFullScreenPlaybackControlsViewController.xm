// AVFullScreenPlaybackControlsViewController.xm
// (c) 2017 opa334

#import "../SafariPlus.h"

/*%hook AVFullScreenPlaybackControlsViewController

%property(nonatomic,retain) AVButton *downloadButton;

- (void)viewDidLoad
{
  %orig;

  AVAsset* currentPlayerAsset = self.playerViewController.player.currentItem.asset;

  if(![currentPlayerAsset isKindOfClass:AVURLAsset.class])
  {
    NSLog(@"Web content detected");
    if(!self.downloadButton)
    {
      //AVButton* scaleButton = MSHookIvar<AVButton*>(self, "_scaleButton");
      self.downloadButton = [%c(AVButton) buttonWithType:UIButtonTypeCustom];
      self.downloadButton.backgroundColor = [UIColor redColor];
      self.downloadButton.frame = CGRectMake(68, 4, 20, 22);
      [self.view addSubview:self.downloadButton];
      NSLog(@"placed download button at %@", NSStringFromCGRect(self.downloadButton.frame));
    }
    /*MPMusicPlayerController* musicPlayer = [%c(MPMusicPlayerController) systemMusicPlayer];
    MPMediaItem* mediaItem = musicPlayer.nowPlayingItem;
    NSString* testURL = [mediaItem valueForProperty:MPMediaItemPropertyTitle];

    NSLog(@"musicPlayer: %@", musicPlayer);
    NSLog(@"Current URL: %@", testURL);*//*
  }
  else
  {
    NSLog(@"Currently playing: NO WEB CONTENT");
  }
}

%end*/
