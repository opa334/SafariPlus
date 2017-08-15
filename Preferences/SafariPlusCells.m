//  SafariPlusCells.m
// (c) 2017 opa334

#import "SafariPlusPrefs.h"

@implementation SafariPlusHeaderCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)reuseIdentifier specifier:(id)specifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];

  if(self)
  {
    headerImage = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/PrefHeader.png", bundlePath]];
    headerImageView = [[UIImageView alloc] initWithImage:headerImage];

    [self.contentView addSubview:headerImageView];
  }
  return self;
}

- (instancetype)initWithSpecifier:(PSSpecifier *)specifier
{
  return [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SafariPlusHeaderCell" specifier:specifier];
}

- (void)setFrame:(CGRect)frame
{
  frame.origin.x = 0;
  [super setFrame:frame];
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width
{
  CGFloat aspectRatio = headerImage.size.height / headerImage.size.width;

  CGFloat height = width * aspectRatio;

  headerImageView.frame = CGRectMake(0,0,self.contentView.bounds.size.width,height);
  headerImageView.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
  headerImageView.contentMode = UIViewContentModeScaleAspectFit;

  return height;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width inTableView:(id)tableView
{
  return [self preferredHeightForWidth:width];
}
@end
