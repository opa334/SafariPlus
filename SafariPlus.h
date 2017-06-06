//  SafariPlus.h
//  Headers for SafariPlus

// (c) 2017 opa334

#import <Cephei/HBPreferences.h>
#import <CoreImage/CoreImage.h>
#import "libcolorpicker.h"
#import "LGShared.h"
#import "filePicker.h"

NSString* bundlePath = @"/Library/Application Support/SafariPlus.bundle";
NSString* plistPath = @"/var/mobile/Library/Preferences/com.opa334.safariplusprefs.plist";

@class ApplicationShortcutController, BrowserController, TabController, TabDocument, TabOverview, TiltedTabView, UnifiedField;

/**** General stuff ****/
@interface _UIBackdropView : UIView {}
@property (nonatomic, retain) UIView *contentView;
@property (nonatomic, retain) UIView *grayscaleTintView;
@end

@interface _UIBarBackground : UIView {}
@property (nonatomic,retain) UIView * customBackgroundView;
@end

/**** WebKit ****/

@interface _WKActivatedElementInfo : NSObject {}
@property (nonatomic, readonly) NSURL *URL;
@property (nonatomic,readonly) long long type;
@end

@interface _WKElementAction : NSObject {
}
+ (id)elementActionWithTitle:(id)arg1 actionHandler:(id /* block */)arg2;
@end

@interface WKFileUploadPanel : UIViewController <filePickerDelegate> {}
- (void)_chooseFiles:(id)arg1 displayString:(id)arg2 iconImage:(id)arg3;
- (void)_showFilePicker;
- (void)_cancel;
@end


/**** SafariServices ****/

@interface _SFFluidProgressView : UIView {}
@property (nonatomic,retain) UIColor * progressBarFillColor;
@end

@interface _SFNavigationBar : UIView {}
@end

@interface _SFNavigationBarBackdrop : _UIBackdropView {}
@property (nonatomic, retain) UIView * grayscaleTintView;
@end

@interface _SFNavigationBarURLButton : UIButton {}
@end

@interface _SFReloadOptionsController : NSObject {}
@property (nonatomic,readonly) BOOL loadedUsingDesktopUserAgent;
- (void)requestDesktopSiteWithURL:(id)arg1;
@end

@interface _SFTabStateData : NSObject {}
- (BOOL)privateBrowsing;
@end

@interface _SFToolbar : UIToolbar {}
@end


/**** SafariShared ****/

@interface WBSBookmarkAndHistoryCompletionMatch : NSObject {}
- (id)originalURLString;
@end


/**** Safari ****/

@interface Application : UIApplication {}
@property (nonatomic,readonly) ApplicationShortcutController * shortcutController;
- (BOOL)isPrivateBrowsingEnabledInAnyWindow;
//new methods below
- (void)autoCloseAction;
- (void)modeSwitchAction:(int)switchToMode;
@end

@interface ApplicationShortcutController : NSObject {}
@property (assign,nonatomic) BrowserController * browserController;
@end

@interface BrowserController : UIResponder {}
@property (nonatomic,readonly) TabController * tabController;
- (BOOL)isShowingTabView;
- (void)togglePrivateBrowsing;
- (BOOL)privateBrowsingEnabled;
- (void)updateTabOverviewFrame;
- (id)loadURLInNewTab:(id)arg1 inBackground:(BOOL)arg2;
- (id)loadURLInNewTab:(id)arg1 inBackground:(BOOL)arg2 animated:(BOOL)arg3;
- (void)dismissTransientUIAnimated:(BOOL)arg1;
//new methods below
- (void)handleURLSwipeLeft;
- (void)handleURLSwipeRight;
- (void)handleURLSwipeDown;
- (void)handleSwipe:(NSInteger)swipeAction;
- (void)userAgentButtonLandscapePressed;
@end

//iOS9
@interface BrowserController (BrowserControllerTabs) {}
- (id)loadURLInNewWindow:(id)arg1 inBackground:(BOOL)arg2;
- (id)loadURLInNewWindow:(id)arg1 inBackground:(BOOL)arg2 animated:(BOOL)arg3;
@end

@interface BrowserToolbar : _SFToolbar {}
@property (nonatomic,retain) UIToolbar * replacementToolbar;
- (void)updateTintColor;
- (BOOL)getBrowsingMode; //New
@end

@interface CatalogViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {}
@property (nonatomic,retain) UnifiedField * textField;
-  (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (id)_completionItemAtIndexPath:(id)arg1;
- (void)_textFieldEditingChanged;
@end

@interface CompletionListTableViewController : UITableViewController {}
@end

@interface GestureRecognizingBarButtonItem : UIBarButtonItem {}
@property (nonatomic,retain) UIGestureRecognizer * gestureRecognizer;
- (void)setGestureRecognizer:(UIGestureRecognizer *)arg1;
- (UIGestureRecognizer *)gestureRecognizer;
- (void)setView:(id)arg1;
@end

@interface NavigationBar : _SFNavigationBar {}
//new methods below
- (void)_updateControlTints;
- (void)didSwipe:(UISwipeGestureRecognizer*)swipe;
- (BOOL)getBrowsingMode;
@end

@interface SearchSuggestion : NSObject {}
- (NSString *)string;
@end

@interface TabBarStyle : NSObject {}
- (BOOL)getBrowsingMode; //new
@end

@interface TabController : NSObject {}
@property (nonatomic,copy,readonly) NSArray * currentTabDocuments;
@property (nonatomic,retain,readonly) TiltedTabView * tiltedTabView;
@property (nonatomic,retain) TabDocument * activeTabDocument;
@property (nonatomic,retain,readonly) TabOverview * tabOverview;
- (void)closeAllOpenTabsAnimated:(BOOL)arg1 exitTabView:(BOOL)arg2;
- (void)closeTab;
- (void)newTab;
//new methods below
- (void)userAgentButtonPressed;
@end

@interface TabDocument : NSObject {}
@property (assign,nonatomic) BrowserController * browserController;
@property (nonatomic,readonly) _SFReloadOptionsController * reloadOptionsController;
@property (nonatomic,readonly) _SFTabStateData * tabStateData;
- (id)URL;
- (void)_closeTabDocumentAnimated:(BOOL)arg1;
- (void)_animateElement:(id)arg1 toToolbarButton:(int)arg2;
//new methods below
- (NSURL*)URLHandler:(NSURL*)URL;
@end

@interface TabOverview : UIView {}
@property (nonatomic,readonly) UIButton * privateBrowsingButton;
@end

@interface TabOverviewItem : NSObject {}
- (BOOL)getBrowsingMode; //new
@end

@interface TiltedTabView : UIView {}
- (void)setShowsExplanationView:(BOOL)arg1 animated:(BOOL)arg2;
@end

@interface TiltedTabItem : NSObject {}
- (BOOL)getBrowsingMode; //new
@end

@interface UnifiedField : UITextField {}
- (void)_textDidChangeFromTyping;
- (void)setText:(id)arg1;
@end
