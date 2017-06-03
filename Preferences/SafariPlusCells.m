//  SafariPlusCells.m
//  Header cell for preference bundle

// (c) 2017 opa334

#import "SafariPlusPrefs.h"

@implementation SafariPlusHeaderCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)reuseIdentifier specifier:(id)specifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];

  if(self)
  {
    CGFloat width = self.contentView.bounds.size.width;

    headerImage = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/PrefHeader.png", bundlePath]];
    headerImageView = [[UIImageView alloc] initWithImage:headerImage];
    headerImageView.frame = CGRectMake(0,0, width, 125);
    headerImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    headerImageView.contentMode = UIViewContentModeScaleToFill;

    [self.contentView addSubview:headerImageView];
  }
  return self;
}

- (instancetype)initWithSpecifier:(PSSpecifier *)specifier {
  return [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SafariPlusHeaderCell" specifier:specifier];
}

- (void)dealloc {
  [headerImageView release];
  [super dealloc];
}

- (void)setFrame:(CGRect)frame {
  frame.origin.x = 0;
  [super setFrame:frame];
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width {
  return 125.0;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width inTableView:(id)tableView {
  return [self preferredHeightForWidth:width];
}
@end
