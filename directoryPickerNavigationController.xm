//  directoryPickerNavigationController.xm
// (c) 2017 opa334

#import "directoryPickerNavigationController.h"

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

- (id)initWithImage:(UIImage*)image fileName:(NSString*)fileName
{
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
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"/User%@", preferenceManager.customDefaultPath]];
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
