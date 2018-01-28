// SPFileTableViewCell.m
// (c) 2017 opa334

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import "SPFileTableViewCell.h"

#import "../Shared.h"
#import "SPLocalizationManager.h"

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
