//  SPFileTableViewCell.xm
// (c) 2017 opa334

#import "SPFileTableViewCell.h"

@implementation SPFileTableViewCell

- (id)initWithFileURL:(NSURL*)fileURL
{
  self = [super init];

  //Get filename
  NSString* fileName = [[[fileURL absoluteString] lastPathComponent] stringByRemovingPercentEncoding];

  //Get defaultManager
  NSFileManager* fileManager = [NSFileManager defaultManager];

  //Check if URL is file or directory
  NSNumber* isFile;
  [fileURL getResourceValue:&isFile forKey:NSURLIsRegularFileKey error:nil];

  //Set label of cell to filename
  self.textLabel.text = fileName;

  if([isFile boolValue])
  {
    //URL is file -> set imageView to file icon
    self.imageView.image = [UIImage imageNamed:@"File.png" inBundle:SPBundle compatibleWithTraitCollection:nil];

    //Get filesize
    int64_t fileSize = [[fileManager attributesOfItemAtPath:[fileURL path] error:nil] fileSize];

    //Create sizeLabel from filesize and set it to accessoryView
    UILabel* sizeLabel = [[UILabel alloc] init];
    sizeLabel.text = [NSByteCountFormatter stringFromByteCount:fileSize countStyle:NSByteCountFormatterCountStyleFile];
    sizeLabel.textColor = [UIColor lightGrayColor];
    sizeLabel.font = [sizeLabel.font fontWithSize:10];
    sizeLabel.textAlignment = NSTextAlignmentRight;
    sizeLabel.frame = CGRectMake(0,0, sizeLabel.intrinsicContentSize.width, 15);
    self.accessoryView = sizeLabel;
  }
  else
  {
    //URL is directory -> set imageView to directory icon
    self.imageView.image = [UIImage imageNamed:@"Directory.png" inBundle:SPBundle compatibleWithTraitCollection:nil];

    //Set accessoryType to disclosureIndicator (arrow to the right)
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  }

  if([fileName hasPrefix:@"."])
  {
    //File is hidden -> modify alpha
    self.imageView.alpha = 0.4;
    self.textLabel.alpha = 0.4;
  }

  //Enable seperators between imageViews
  [self setSeparatorInset:UIEdgeInsetsZero];

  return self;
}

@end
