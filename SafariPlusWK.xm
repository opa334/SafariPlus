//  SafariPlusWK.xm
//  WebKit Hooks

// (c) 2017 opa334

#import "SafariPlus.h"

/****** Preference variables ******/

HBPreferences *preferences;

static BOOL uploadAnyFileOptionEnabled;


/****** WebKit Hooks (Upload any file) ******/

%hook WKFileUploadPanel

//Add button to document menu
-(void)_showDocumentPickerMenu
{
  %orig;
  if(uploadAnyFileOptionEnabled)
  {
    UIDocumentMenuViewController* documentMenuController = MSHookIvar<UIDocumentMenuViewController*>(self, "_documentMenuController");
    [documentMenuController addOptionWithTitle:[LGShared localisedStringForKey:@"LOCAL_FILE"] image:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/Device.png", bundlePath]] order:UIDocumentMenuOrderFirst handler:^{
      [self _showFilePicker];
    }];
  }
}

//Present file picker
%new
-(void)_showFilePicker
{
  @autoreleasepool
  {
    filePickerTableViewController* _filePickerTableViewController = [[filePickerTableViewController alloc] init];
    filePickerNavigationController* navController = [[filePickerNavigationController alloc] initWithRootViewController:_filePickerTableViewController];
    navController.filePickerDelegate = self;
    UIViewController* presentationViewController = MSHookIvar<UIViewController*>(self, "_presentationViewController");
    [presentationViewController presentViewController:navController animated:YES completion:nil];
  }
}

//Dismiss file picker and start upload or cancel
%new
-(void)didSelectFileAtURL:(NSURL*)url shouldCancel:(BOOL)cancel
{
  __block UIViewController* presentationViewController = MSHookIvar<UIViewController*>(self, "_presentationViewController");
  [presentationViewController dismissViewControllerAnimated:YES completion:^
  {
    presentationViewController = nil;
  }];

  if(cancel)
  {
    [self _cancel];
  }

  else
  {
    [self _chooseFiles:@[url] displayString:[url.lastPathComponent stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] iconImage:nil];
  }
}
%end


/****** Preference stuff ******/

static NSString *const SarafiPlusPrefsDomain = @"com.opa334.safariplusprefs";

%ctor
{
	preferences = [[HBPreferences alloc] initWithIdentifier:SarafiPlusPrefsDomain];

  [preferences registerBool:&uploadAnyFileOptionEnabled default:NO forKey:@"uploadAnyFileOptionEnabled"];
}
