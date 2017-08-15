//  directoryPickerNavigationController.xm
// (c) 2017 opa334

#import "directoryPickerNavigationController.h"

@implementation directoryPickerNavigationController

- (id)initWithRequest:(NSURLRequest*)request size:(int64_t)size path:(NSURL*)path fileName:(NSString*)fileName
{
  //Initialise an instance and set given properties
  self = [super init];
  self.request = request;
  self.size = size;
  self.path = path;
  self.fileName = fileName;
  return self;
}

- (id)initWithImage:(UIImage*)image fileName:(NSString*)fileName
{
  //Initialise an instance and set given properties
  self = [super init];
  self.image = image;
  self.imageDownload = YES;
  self.fileName = fileName;
  return self;
}

- (NSURL*)rootPath
{
  if(preferenceManager.customDefaultPathEnabled)
  {
    //customDefaultPath enabled -> return custom path if it is valid
    NSURL* path = [NSURL fileURLWithPath:[NSString stringWithFormat:@"/User%@", preferenceManager.customDefaultPath]];
    BOOL isDir;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[path path] isDirectory:&isDir];
    if(isDir && exists)
    {
      return path;
    }
  }
  //customDefaultPath disabled or invalid -> return default path
  return [NSURL fileURLWithPath:@"/User/Downloads/"];
}

- (BOOL)shouldLoadPreviousPathElements
{
  return YES;
}

- (id)newTableViewControllerWithPath:(NSURL*)path
{
  //return instance of directoryPickerTableViewController
  return [[directoryPickerTableViewController alloc] initWithPath:path];
}

@end
