//  fileTableViewCell.xm
// (c) 2017 opa334

#import "fileTableViewCell.h"

@implementation fileTableViewCell

- (id)initWithSize:(int64_t)size;
{
  self = [super init];

  UILabel* sizeLabel = [[UILabel alloc] init];

  sizeLabel.text = [NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile];
  sizeLabel.textColor = [UIColor lightGrayColor];
  sizeLabel.backgroundColor = [UIColor clearColor];
  sizeLabel.font = [sizeLabel.font fontWithSize:10];
  sizeLabel.textAlignment = NSTextAlignmentRight;
  sizeLabel.frame = CGRectMake(0,0, sizeLabel.intrinsicContentSize.width, 15);
  self.accessoryView = sizeLabel;

  return self;
}

@end
