// WKFileUploadPanel.xm
// (c) 2017 opa334

#import "../SafariPlus.h"

%hook WKFileUploadPanel

//Add button to document menu
- (void)_showDocumentPickerMenu
{
  %orig;
  if(preferenceManager.uploadAnyFileOptionEnabled)
  {
    UIDocumentMenuViewController* documentMenuController =
      MSHookIvar<UIDocumentMenuViewController*>(self, "_documentMenuController");

    [documentMenuController addOptionWithTitle:[localizationManager
      localizedSPStringForKey:@"LOCAL_FILE"]
      image:[UIImage imageNamed:@"Device.png"
      inBundle:SPBundle compatibleWithTraitCollection:nil]
      order:UIDocumentMenuOrderFirst handler:
    ^{
      [self _showFilePicker];
    }];
  }
}

//Present file picker
%new
- (void)_showFilePicker
{
  SPFilePickerNavigationController* navController = [[%c(SPFilePickerNavigationController) alloc] init];
  navController.filePickerDelegate = self;

  if(IS_PAD)
  {
    [self _presentPopoverWithContentViewController:navController animated:YES];
  }
  else
  {
    [self _presentFullscreenViewController:navController animated:YES];
  }
}

//Dismiss file picker and start upload or cancel
%new
- (void)didSelectFilesAtURL:(NSArray*)URLArray
{
  [self _dismissDisplayAnimated:YES];

  if(!URLArray)
  {
    [self _cancel];
  }
  else
  {
    [self _chooseFiles:URLArray displayString:[((NSURL*)URLArray[0]).lastPathComponent
      stringByRemovingPercentEncoding] iconImage:nil];
  }
}
%end
