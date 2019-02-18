#import "../SafariPlus.h"

@interface AVActivityButton : AVButton
@property (nonatomic) UIActivityIndicatorView* activityIndicatorView;

- (BOOL)spinning;
- (void)setSpinning:(BOOL)spinning;
- (void)setUpSpinner;
@end
