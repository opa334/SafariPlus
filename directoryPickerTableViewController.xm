//  directoryPickerTableViewController.xm
// (c) 2017 opa334

#import "directoryPickerTableViewController.h"

@implementation directoryPickerTableViewController

- (UIBarButtonItem*)defaultRightBarButtonItem
{
  //Create and return UIBarButtonItem to choose current directory
  return [[UIBarButtonItem alloc] initWithTitle:[localizationManager
    localizedSPStringForKey:@"CHOOSE"] style:UIBarButtonItemStylePlain
    target:self action:@selector(chooseButtonPressed)];
}

- (void)chooseButtonPressed
{
  if([self canDownloadToPath:self.currentPath])
  {
    //Path is writable -> create alert to pick file name
    UIAlertController * nameAlert = [UIAlertController alertControllerWithTitle:
      [localizationManager localizedSPStringForKey:@"CHOOSE_FILENAME"] message:nil
  		preferredStyle:UIAlertControllerStyleAlert];

    //Add textField to choose filename
  	[nameAlert addTextFieldWithConfigurationHandler:^(UITextField *textField)
  	{
      textField.text = ((directoryPickerNavigationController*)self.navigationController).fileName;
  		textField.placeholder = [localizationManager localizedSPStringForKey:@"FILENAME"];
  		textField.textColor = [UIColor blackColor];
  		textField.keyboardType = UIKeyboardTypeURL;
  		textField.clearButtonMode = UITextFieldViewModeWhileEditing;
  		textField.borderStyle = UITextBorderStyleNone;
  	}];

    //Create action to start downloading
    UIAlertAction* startDownloadAction = [UIAlertAction
      actionWithTitle:[localizationManager
      localizedSPStringForKey:@"START_DOWNLOAD"]
      style:UIAlertActionStyleDefault handler:^(UIAlertAction *addAction)
  	{
      //Get textField and the fileName from it's content
  		UITextField * nameField = nameAlert.textFields[0];
      NSString* fileName = nameField.text;

      if(((directoryPickerNavigationController*)self.navigationController).imageDownload)
      {
        //Download is image -> call image response with needed information
        UIImage* image = ((directoryPickerNavigationController*)self.navigationController).image;
        [self dismiss];
        [[downloadManager sharedInstance] handleDirectoryPickerImageResponse:image
          fileName:fileName path:self.currentPath];
      }
      else
      {
        //Download is file -> call file response with needed information
        NSURLRequest* request = ((directoryPickerNavigationController*)self.navigationController).request;
        int64_t size = ((directoryPickerNavigationController*)self.navigationController).size;
        [self dismiss];
    		[[downloadManager sharedInstance] handleDirectoryPickerResponse:request
          size:size fileName:fileName path:self.currentPath];
      }
    }];

    //Add action
    [nameAlert addAction:startDownloadAction];

    //Create action to close the picker
    UIAlertAction* closePickerAction = [UIAlertAction actionWithTitle:
      [localizationManager localizedSPStringForKey:@"CLOSE_PICKER"]
      style:UIAlertActionStyleDefault handler:^(UIAlertAction *addAction)
    {
      //Dismiss picker
      [self dismiss];
    }];

    //Add action
    [nameAlert addAction:closePickerAction];

    //Create action to close the alert
  	UIAlertAction* closeAction = [UIAlertAction actionWithTitle:
      [localizationManager localizedSPStringForKey:@"CLOSE"]
      style:UIAlertActionStyleDefault handler:nil];

    //Add action
    [nameAlert addAction:closeAction];

    //Present alert
    [self presentViewController:nameAlert animated:YES completion:nil];
  }
  else
  {
    //Path is not writable -> Create error alert
    UIAlertController * errorAlert = [UIAlertController alertControllerWithTitle:
      [localizationManager localizedSPStringForKey:@"ERROR"]
      message:[localizationManager localizedSPStringForKey:@"WRONG_PATH_MESSAGE"]
  		preferredStyle:UIAlertControllerStyleAlert];

    //Create action to close the alert
    UIAlertAction* closeAction = [UIAlertAction actionWithTitle:
    [localizationManager localizedSPStringForKey:@"CLOSE"]
    style:UIAlertActionStyleDefault handler:nil];

    //Add action
    [errorAlert addAction:closeAction];

    //Create action to close the picker
    UIAlertAction* closePickerAction = [UIAlertAction actionWithTitle:
      [localizationManager localizedSPStringForKey:@"CLOSE_PICKER"]
      style:UIAlertActionStyleDefault handler:^(UIAlertAction *addAction)
    {
      //Close picker
      [self dismiss];
    }];

    //Add action
    [errorAlert addAction:closePickerAction];

    //Present alert
    [self presentViewController:errorAlert animated:YES completion:nil];
  }
}

- (BOOL)canDownloadToPath:(NSURL*)pathURL
{
  if([[pathURL path] rangeOfString:@"/var/mobile"].location == NSNotFound)
  {
    //Path is not within /var/mobile -> Not writable
    return NO;
  }
  else
  {
    //Path is within /var/mobile -> Writable
    return YES;
  }
}

@end
