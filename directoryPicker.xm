//  directoryPicker.xm
//  Directory picker for picking a path to download to

// (c) 2017 opa334

#import "directoryPicker.h"

@implementation directoryPickerTableViewController

- (UIBarButtonItem*)defaultRightBarButtonItem
{
  return [[UIBarButtonItem alloc] initWithTitle:[localizationManager localizedSPStringForKey:@"CHOOSE"] style:UIBarButtonItemStylePlain target:self action:@selector(chooseButtonPressed)];
}

- (void)chooseButtonPressed
{
  if([self canDownloadToPath:self.currentPath])
  {
    UIAlertController * nameAlert = [UIAlertController alertControllerWithTitle:
                        [localizationManager localizedSPStringForKey:@"CHOOSE_FILENAME"] message:nil
  											preferredStyle:UIAlertControllerStyleAlert];

  	[nameAlert addTextFieldWithConfigurationHandler:^(UITextField *textField)
  	{
      textField.text = ((directoryPickerNavigationController*)self.navigationController).fileName;
  		textField.placeholder = [localizationManager localizedSPStringForKey:@"FILENAME"];
  		textField.textColor = [UIColor blackColor];
  		textField.keyboardType = UIKeyboardTypeURL;
  		textField.clearButtonMode = UITextFieldViewModeWhileEditing;
  		textField.borderStyle = UITextBorderStyleNone;
  	}];

    UIAlertAction* startDownloadAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"START_DOWNLOAD"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *addAction)
  	{
  		UITextField * nameField = nameAlert.textFields[0];

      NSURLRequest* request = ((directoryPickerNavigationController*)self.navigationController).request;

      int64_t size = ((directoryPickerNavigationController*)self.navigationController).size;

      NSString* fileName = nameField.text;

      [self dismiss];

  		[[downloadManager sharedInstance] handleDirectoryPickerResponse:request size:size fileName:fileName path:self.currentPath];
    }];

    [nameAlert addAction:startDownloadAction];

    UIAlertAction* closePickerAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CLOSE_PICKER"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *addAction)
    {
      [self dismiss];
    }];

    [nameAlert addAction:closePickerAction];

  	UIAlertAction* closeAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CLOSE"] style:UIAlertActionStyleDefault handler:nil];

    [nameAlert addAction:closeAction];

    [self presentViewController:nameAlert animated:YES completion:nil];
  }
  else
  {
    UIAlertController * errorAlert = [UIAlertController alertControllerWithTitle:
                        [localizationManager localizedSPStringForKey:@"ERROR"]
                        message:[localizationManager localizedSPStringForKey:@"WRONG_PATH_MESSAGE"]
  											preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* closeAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CLOSE"] style:UIAlertActionStyleDefault handler:nil];

    [errorAlert addAction:closeAction];

    UIAlertAction* closePickerAction = [UIAlertAction actionWithTitle:[localizationManager localizedSPStringForKey:@"CLOSE_PICKER"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *addAction)
    {
      [self dismiss];
    }];

    [errorAlert addAction:closePickerAction];

    [self presentViewController:errorAlert animated:YES completion:nil];
  }
}

- (BOOL)canDownloadToPath:(NSURL*)pathURL
{
  if([[pathURL path] rangeOfString:@"/var/mobile"].location == NSNotFound)
  {
    return NO;
  }
  else
  {
    return YES;
  }
}

@end

@implementation directoryPickerNavigationController

- (id)initWithRequest:(NSURLRequest*)request size:(int64_t)size path:(NSURL*)path fileName:(NSString*)fileName
{
  self = [super init];
  self.request = request;
  self.size = size;
  self.path = path;
  self.fileName = fileName;
  return self;
}

- (NSURL*)rootPath
{
  if(preferenceManager.customDefaultPathEnabled)
  {
    return [NSURL fileURLWithPath:preferenceManager.customDefaultPath];
  }
  else
  {
    return [NSURL fileURLWithPath:@"/User/Downloads"];
  }
}

- (BOOL)shouldLoadPreviousPathElements
{
  return YES;
}

- (id)newTableViewControllerWithPath:(NSURL*)path
{
  return [[directoryPickerTableViewController alloc] initWithPath:path];
}

@end
