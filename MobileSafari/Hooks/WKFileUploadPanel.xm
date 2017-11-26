// WKFileUploadPanel.xm
// (c) 2017 opa334

#import "../SafariPlus.h"

#import "../Classes/SPPreferenceManager.h"
#import "../Classes/SPLocalizationManager.h"
#import "../Classes/SPFilePickerNavigationController.h"
#import "../Defines.h"
#import "../Shared.h"

%group iOS9Up

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
    [self _chooseFiles:URLArray
      displayString:[((NSURL*)URLArray.firstObject).lastPathComponent
      stringByRemovingPercentEncoding] iconImage:nil];
  }
}

%end

%end

%group iOS8

%hook WKFileUploadPanel

- (void)_showPhotoPickerWithSourceType:(int)arg1
{
  if(preferenceManager.uploadAnyFileOptionEnabled)
  {
    //On some sites only the photo picker gets opened, if that's the case, just present the alert nonetheless
    UIAlertController* actionSheetController = MSHookIvar<UIAlertController*>(self, "_actionSheetController");
    if(!actionSheetController)
    {
      [self _showMediaSourceSelectionSheet];
      return;
    }
  }

  %orig;
}

- (void)_showMediaSourceSelectionSheet
{
  %orig;

  if(preferenceManager.uploadAnyFileOptionEnabled)
  {
    UIAlertController* uploadAlert = MSHookIvar<UIAlertController*>(self, "_actionSheetController");

    UIAlertAction* fileAction = [UIAlertAction actionWithTitle:[localizationManager
      localizedSPStringForKey:@"LOCAL_FILE"]
      style:UIAlertActionStyleDefault handler:^(UIAlertAction *addAction)
    {
      [self _showFilePicker];
    }];

    //Add 'Local File' option to alert
    [uploadAlert addAction:fileAction];
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
    //iOS8 needs the files to be inside sandbox (otherwise WebKit crashes)

    //Mutable array for sandboxed URLs
    NSMutableArray* sandboxedURLs = [NSMutableArray new];

    for(NSURL* URL in URLArray)
    {
      //Create URL for tmp location
      NSURL* sandboxedURL = [NSURL fileURLWithPath:[NSTemporaryDirectory()
        stringByAppendingPathComponent:URL.lastPathComponent]];

      //Create link to URL
      [[NSFileManager defaultManager] linkItemAtURL:URL.URLByResolvingSymlinksInPath
        toURL:sandboxedURL error:nil];

      //Add URL to array
      [sandboxedURLs addObject:sandboxedURL];
    }

    //Choose files inside sandbox
    [self _chooseFiles:sandboxedURLs
      displayString:[((NSURL*)sandboxedURLs.firstObject).lastPathComponent
      stringByRemovingPercentEncoding] iconImage:nil];
  }
}

%end

%end

%hook WKFileUploadPanel

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

%end

%ctor
{
  if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0)
  {
    %init(iOS9Up);
  }
  else
  {
    %init(iOS8);
  }
  %init;
}
