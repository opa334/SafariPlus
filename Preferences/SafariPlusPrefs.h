//  SafariPlusPrefs.h
//  Headers for preference bundle

// (c) 2017 opa334

#define bundlePath @"/Library/PreferenceBundles/SafariPlusPrefs.bundle"
#define plistPath @"/var/mobile/Library/Preferences/com.opa334.safariplusprefs.plist"
#import <Preferences/PSListController.h>
#import <Preferences/PSTableCell.h>
#import <Preferences/PSSpecifier.h>

@interface SafariPlusRootListController : PSListController {}
@end

@interface GeneralPrefsController : PSListController {}
@end

@interface PSEditableListController : PSListController {
    BOOL  _editable;
    BOOL  _editingDisabled;
}

- (id)_editButtonBarItem;
- (void)_setEditable:(BOOL)arg1 animated:(BOOL)arg2;
- (void)_updateNavigationBar;
- (void)didLock;
- (void)editDoneTapped;
- (BOOL)editable;
- (id)init;
- (BOOL)performDeletionActionForSpecifier:(id)arg1;
- (void)setEditButtonEnabled:(BOOL)arg1;
- (void)setEditable:(BOOL)arg1;
- (void)setEditingButtonHidden:(BOOL)arg1 animated:(BOOL)arg2;
- (void)showController:(id)arg1 animate:(BOOL)arg2;
- (void)suspend;
- (void)tableView:(id)arg1 commitEditingStyle:(int)arg2 forRowAtIndexPath:(id)arg3;
- (UITableViewCellEditingStyle)tableView:(id)arg1 editingStyleForRowAtIndexPath:(id)arg2;
- (id)tableView:(id)arg1 willSelectRowAtIndexPath:(id)arg2;
- (void)viewWillAppear:(BOOL)arg1;
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
