//  SafariPlusPrefs.h
//  Headers for preference bundle

// (c) 2017 opa334

#define bundlePath @"/Library/PreferenceBundles/SafariPlusPrefs.bundle"
#import <Preferences/PSListController.h>
#import <Preferences/PSTableCell.h>
#import <Preferences/PSSpecifier.h>

@interface SafariPlusRootListController : PSListController {
  NSMutableArray *_forceModeSpecifiers;
}
@end

@interface GeneralPrefsController : PSListController {
  NSMutableArray *_forceModeSpecifiers;
}
@end

@interface ActionPrefsController : PSListController {
  NSMutableArray *_forceModeSpecifiers;
}
@end

@interface GesturePrefsController : PSListController {
  NSMutableArray *_forceModeSpecifiers;
}
@end

@interface OtherPrefsController : PSListController {
  NSMutableArray *_forceModeSpecifiers;
}
@end

@interface ColorPrefsController : PSListController {
  NSMutableArray *_forceModeSpecifiers;
}
@end

@interface NormalColorPrefsController : PSListController {
  NSMutableArray *_forceModeSpecifiers;
}
@end

@interface PrivateColorPrefsController : PSListController {
  NSMutableArray *_forceModeSpecifiers;
}
@end

@interface CreditsController : PSListController {
  NSMutableArray *_forceModeSpecifiers;
}
@end

@protocol PreferencesTableCustomView
- (id)initWithSpecifier:(id)specifier;
@optional
- (CGFloat)preferredHeightForWidth:(CGFloat)width;
- (CGFloat)preferredHeightForWidth:(CGFloat)width inTableView:(id)tableView;
@end

@interface SafariPlusHeaderCell : PSTableCell <PreferencesTableCustomView> {
  UIImage *headerImage;
  UIImageView *headerImageView;
}
@end
