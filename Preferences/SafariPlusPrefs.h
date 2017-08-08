//  SafariPlusPrefs.h
// (c) 2017 opa334

#define bundlePath @"/Library/PreferenceBundles/SafariPlusPrefs.bundle"
#define otherPlistPath @"/var/mobile/Library/Preferences/com.opa334.safariplusprefsOther.plist"
#import <Preferences/PSListController.h>
#import <Preferences/PSTableCell.h>
#import <Preferences/PSSpecifier.h>
#import "SPPreferenceLocalizationManager.h"

@interface PSEditableListController : PSListController {}
- (id)_editButtonBarItem;
- (BOOL)performDeletionActionForSpecifier:(id)arg1;
@end


@interface SafariPlusRootListController : PSListController {}
@end

@interface GeneralPrefsController : PSListController {}
@end

@interface DownloadPrefsController : PSListController {}
@end

@interface ExceptionsController : PSEditableListController {
  NSMutableDictionary *plist;
  NSMutableArray *ForceHTTPSExceptions;
}
@end

@interface ActionPrefsController : PSListController {}
@end

@interface GesturePrefsController : PSListController {}
@end

@interface OtherPrefsController : PSListController {}
@end

@interface ColorPrefsController : PSListController {}
@end

@interface NormalColorPrefsController : PSListController {}
@end

@interface PrivateColorPrefsController : PSListController {}
@end

@interface CreditsController : PSListController {}
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
