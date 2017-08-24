//  SafariPlus.h
// (c) 2017 opa334

#import "SPLocalizationManager.h"
#import "SPPreferenceManager.h"
#import <CoreImage/CoreImage.h>
#import "libcolorpicker.h"
#import "filePickerNavigationController.h"
#import "downloadsNavigationController.h"
#import "downloadManager.h"
#import "lib/CWStatusBarNotification.h"

#define otherPlistPath @"/var/mobile/Library/Preferences/com.opa334.safariplusprefsOther.plist"
#define desktopUserAgent @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_5) AppleWebKit/603.2.4 (KHTML, like Gecko) Version/10.1.1 Safari/603.2.4"

@class ApplicationShortcutController, BrowserController, BrowserRootViewController, BrowserToolbar, DownloadDispatcher, SafariWebView, TabController, TabDocument, TabOverview, TiltedTabView, UnifiedField, WebBookmark;

/**** General stuff ****/

@interface _UIBackdropView : UIView {}
@property (nonatomic, retain) UIView *contentView;
@property (nonatomic, retain) UIView *grayscaleTintView;
@end

@interface _UIBarBackground : UIView {}
@property (nonatomic,retain) UIView * customBackgroundView;
@end

/**** WebKit ****/

@interface WKNavigationResponse () {}
@property (nonatomic,readonly) NSURLRequest * _request;
@end

@interface WKFileUploadPanel <filePickerDelegate> {}
- (void)_presentPopoverWithContentViewController:(id)arg1 animated:(BOOL)arg2;
- (void)_presentFullscreenViewController:(id)arg1 animated:(BOOL)arg2;
- (void)_dismissDisplayAnimated:(BOOL)arg1;
- (void)_chooseFiles:(id)arg1 displayString:(id)arg2 iconImage:(id)arg3;
- (void)_showFilePicker;
- (void)_cancel;
@end

@interface _WKActivatedElementInfo : NSObject {}
@property (nonatomic, readonly) NSURL *URL;
@property (nonatomic,readonly) long long type;
@property (nonatomic,copy,readonly) UIImage * image;
@property (nonatomic,readonly) NSString * ID;
@property (nonatomic,readonly) NSString * title;
@end

@interface _WKElementAction : NSObject {}
+ (id)elementActionWithTitle:(id)arg1 actionHandler:(id)arg2;
@end

/**** SafariServices ****/

@interface SFCrossfadingLabel : UILabel {}
@end

@interface _SFBookmarkInfoViewController : UITableViewController {}
@end

@interface _SFDialog : NSObject {}
@property (nonatomic,copy,readonly) NSString * defaultText;
- (void)finishWithPrimaryAction:(BOOL)arg1 text:(id)arg2;
@end

@interface _SFDialogController : NSObject {}
-(void)_dismissDialog;
@end

@interface _SFDownloadController : NSObject {}
- (void)_beginDownloadBackgroundTask:(id)arg1;
@end

@interface _SFFindOnPageView : UIView {}
- (void)setShouldFocusTextField:(BOOL)arg1;
- (void)showFindOnPage;
@end

@interface _SFFluidProgressView : UIView {}
@property (nonatomic,retain) UIColor * progressBarFillColor;
@end

@interface _SFSiteIconView : UIImageView {}
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
- (void)requestDesktopSite;
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

@protocol BrowserToolbarDelegate <NSObject>
@optional
- (void)presentAddTabPopoverFromButtonBar;
- (void)addTabFromButtonBar;

@required
- (void)toggleBookmarksFromButtonBar;
- (void)backFromButtonBar;
- (void)forwardFromButtonBar;
- (void)showActionPanelFromButtonBar;
- (void)presentBookmarksLongPressMenuFromButtonBar;
- (void)showTabsFromButtonBar;
- (void)presentBackPopoverFromButtonBar;
- (void)presentForwardPopoverFromButtonBar;
- (void)presentTabExposePopoverFromButtonBar;
- (CGPoint*)targetPointForButtonBarLinkImageAnimationIntoLayer:(id)arg1 proposedTargetPoint:(CGPoint)arg2;
//added by me
- (void)downloadsFromButtonBar;
- (BOOL)usesTabBar;

@end

@interface Application : UIApplication <UIApplicationDelegate> {}
@property (nonatomic,readonly) ApplicationShortcutController * shortcutController;
@property (nonatomic,readonly) NSArray * browserControllers;
- (BOOL)isPrivateBrowsingEnabledInAnyWindow;
//new methods below
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler;
- (void)updateButtonState;
@end

@interface ApplicationShortcutController : NSObject {}
@property (assign,nonatomic) BrowserController * browserController;
@end

@interface BrowserController : UIResponder <BrowserToolbarDelegate> {}
@property (nonatomic,readonly) TabController * tabController;
@property (nonatomic,readonly) BrowserToolbar * bottomToolbar;
@property (nonatomic,readonly) BrowserRootViewController * rootViewController;
@property (nonatomic) BOOL shouldFocusFindOnPageTextField; //iOS9
- (BOOL)isShowingTabView;
- (void)togglePrivateBrowsing;
- (BOOL)privateBrowsingEnabled;
- (void)updateTabOverviewFrame;
- (id)loadURLInNewTab:(id)arg1 inBackground:(BOOL)arg2;
- (id)loadURLInNewTab:(id)arg1 inBackground:(BOOL)arg2 animated:(BOOL)arg3;
- (void)_presentModalViewController:(id)arg1 fromButtonIdentifier:(long long)arg2 animated:(BOOL)arg3 completion:(/*^block*/id)arg4;
- (void)dismissTransientUIAnimated:(BOOL)arg1;
- (void)clearHistoryMessageReceived;
- (void)clearAutoFillMessageReceived;
- (void)_toggleTabViewKeyPressed;
- (void)showFindOnPage; //iOS9
//new stuff below
@property(nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeLeftGestureRecognizer;
@property(nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeRightGestureRecognizer;
@property(nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeDownGestureRecognizer;
- (void)handleURLSwipeLeft;
- (void)handleURLSwipeRight;
- (void)handleURLSwipeDown;
- (void)handleSwipe:(NSInteger)swipeAction;
- (void)downloadsFromButtonBar;
- (BOOL)usesTabBar;
- (void)clearData;
- (void)modeSwitchAction:(int)switchToMode;
- (void)autoCloseAction;
@end

//iOS9
@interface BrowserController (BrowserControllerTabs) {}
- (id)loadURLInNewWindow:(id)arg1 inBackground:(BOOL)arg2;
- (id)loadURLInNewWindow:(id)arg1 inBackground:(BOOL)arg2 animated:(BOOL)arg3;
@end

@interface BrowserRootViewController : UIViewController <RootControllerDownloadDelegate> {} //added delegate
//new stuff below
@property(nonatomic,retain) CWStatusBarNotification *statusBarNotification;
- (void)dispatchNotificationWithText:(NSString*)text;
- (void)dismissNotificationWithCompletion:(void (^)(void))completion;
- (void)presentViewController:(id)viewController;
- (void)presentAlertControllerSheet:(UIAlertController*)alertController;
@end

@interface BrowserToolbar : _SFToolbar {}
@property (nonatomic,weak) id<BrowserToolbarDelegate> browserDelegate;
@property (nonatomic,retain) UIToolbar * replacementToolbar;
- (void)updateTintColor;
//new stuff below
@property (nonatomic,retain) UIBarButtonItem * _downloadsItem;
- (void)setDownloadsEnabled:(BOOL)enabled;
- (BOOL)getBrowsingMode;
- (BOOL)usesTabBar;
@end

@interface CatalogViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {}
@property (nonatomic,retain) UnifiedField * textField;
-  (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (id)_completionItemAtIndexPath:(id)arg1;
- (void)_textFieldEditingChanged;
@end

@interface CompletionListTableViewController : UITableViewController {}
@end


@interface FindOnPageView : _SFFindOnPageView {}
@end

@interface GestureRecognizingBarButtonItem : UIBarButtonItem {}
@property (nonatomic,retain) UIGestureRecognizer * gestureRecognizer;
- (void)setGestureRecognizer:(UIGestureRecognizer *)arg1;
- (UIGestureRecognizer *)gestureRecognizer;
- (void)setView:(id)arg1;
@end

@interface NavigationBar : _SFNavigationBar {}
@property (nonatomic,readonly) UnifiedField * textField;
- (void)_updateControlTints;
//new methods below
- (void)didSwipe:(UISwipeGestureRecognizer*)swipe;
- (BOOL)getBrowsingMode;
@end

@interface SafariWebView : WKWebView {}
@end

@interface SearchSuggestion : NSObject {}
- (NSString *)string;
@end

@interface TabBarStyle : NSObject {}
- (BOOL)getBrowsingMode; //new
@end

@interface TabController : NSObject {}
@property (nonatomic,copy,readonly) NSArray * tabDocuments;
@property (nonatomic,copy,readonly) NSArray * privateTabDocuments;
@property (nonatomic,copy,readonly) NSArray * allTabDocuments;
@property (nonatomic,copy,readonly) NSArray * currentTabDocuments; //iOS 10 only
@property (nonatomic,retain,readonly) TiltedTabView * tiltedTabView;
@property (nonatomic,retain) TabDocument * activeTabDocument;
@property (nonatomic,retain,readonly) TabOverview * tabOverview;
@property (assign,nonatomic) BOOL usesTabBar;
- (void)setActiveTabDocument:(id)arg1 animated:(BOOL)arg2;
- (void)closeAllOpenTabsAnimated:(BOOL)arg1 exitTabView:(BOOL)arg2;
- (BOOL)isPrivateBrowsingEnabled;
- (void)closeTab;
- (void)newTab;
//new stuff below
@property (nonatomic,retain) UIButton *tiltedTabViewDesktopModeButton;
- (void)reloadTabsIfNeeded;
- (void)userAgentButtonPressed;
@end

@interface TabDocument : NSObject {}
@property (assign,nonatomic) BrowserController * browserController;
@property (nonatomic,readonly) _SFReloadOptionsController * reloadOptionsController;
@property (nonatomic,readonly) _SFTabStateData * tabStateData;
@property (nonatomic,readonly) SafariWebView * webView;
@property (nonatomic,copy) NSString * customUserAgent;
@property (nonatomic,readonly) FindOnPageView * findOnPageView;
@property (nonatomic,retain) _SFDownloadController * downloadController;
- (NSURL*)URL;
- (BOOL)isBlankDocument;
- (id)_loadURLInternal:(id)arg1 userDriven:(BOOL)arg2;
- (void)_loadStartedDuringSimulatedClickForURL:(id)arg1;
- (void)reload;
- (BOOL)privateBrowsingEnabled;
- (WebBookmark*)readingListBookmark;
- (void)_closeTabDocumentAnimated:(BOOL)arg1;
- (void)_animateElement:(id)arg1 toToolbarButton:(int)arg2;
- (id)loadURL:(id)arg1 userDriven:(BOOL)arg2;
- (id)loadUserTypedAddress:(NSString*)arg1;
- (void)setCustomUserAgent:(NSString *)arg1;
- (void)stopLoading;
- (void)webView:(WKWebView*)arg1 decidePolicyForNavigationResponse:(WKNavigationResponse*)arg2 decisionHandler:(void (^)(void))arg3;
//new methods below
- (NSURL*)URLHandler:(NSURL*)URL;
- (BOOL)shouldRequestHTTPS:(NSURL*)URL;
@end

@interface TabOverview : UIView {}
@property (nonatomic,readonly) UIButton * privateBrowsingButton;
//new stuff below
@property (nonatomic, retain) UIButton * desktopModeButton;
- (void)userAgentButtonLandscapePressed;
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
