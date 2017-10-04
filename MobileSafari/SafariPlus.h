//  SafariPlus.h
// (c) 2017 opa334

#ifdef SIMJECT
#import "substrate.h"
#endif

#import "libcolorpicker.h"
#import <CoreImage/CoreImage.h>
#import "Lib/CWStatusBarNotification.h"
#import "Classes/SPLocalizationManager.h"
#import "Classes/SPPreferenceManager.h"
#import "Classes/SPDownloadsNavigationController.h"
#import "Classes/SPFilePickerNavigationController.h"
#import "Classes/SPDownloadManager.h"
#import "Defines.h"
#import "Shared.h"

@import AVKit;
@import AVFoundation;
@import MediaPlayer;
@import WebKit;

@class ApplicationShortcutController, BrowserController, BrowserRootViewController, BrowserToolbar, CWStatusBarNotification, DownloadDispatcher, SafariWebView, TabController, TabDocument, TabOverview, TabOverviewItem, TabOverviewItemView, TabOverviewItemLayoutInfo, TiltedTabItem, TiltedTabView, TiltedTabItemLayoutInfo, TabThumbnailView, UnifiedField, WebBookmark;

/**** General stuff ****/

@interface _UIBackdropView : UIView {}
@property (nonatomic, retain) UIView *contentView;
@property (nonatomic, retain) UIView *grayscaleTintView;
@end

@interface _UIBarBackground : UIView {}
@property (nonatomic,retain) UIView* customBackgroundView;
@end

/**** WebKit ****/

@interface WKNavigationResponse () {}
@property (nonatomic,readonly) NSURLRequest* _request;
@end

@interface WKFileUploadPanel <filePickerDelegate> {}
- (void)_presentPopoverWithContentViewController:(id)arg1 animated:(BOOL)arg2;
- (void)_presentFullscreenViewController:(id)arg1 animated:(BOOL)arg2;
- (void)_dismissDisplayAnimated:(BOOL)arg1;
- (void)_chooseFiles:(id)arg1 displayString:(id)arg2 iconImage:(id)arg3;
- (void)_showFilePicker;
- (void)_cancel;
- (void)_showMediaSourceSelectionSheet; //iOS8
@end

@interface _WKActivatedElementInfo : NSObject {}
@property (nonatomic, readonly) NSURL *URL;
@property (nonatomic,readonly) long long type;
@property (nonatomic,copy,readonly) UIImage* image;
@property (nonatomic,readonly) NSString* ID;
@property (nonatomic,readonly) NSString* title;
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
@property (nonatomic,copy,readonly) NSString* defaultText;
- (void)finishWithPrimaryAction:(BOOL)arg1 text:(id)arg2;
@end

@interface _SFDialogController : NSObject {}
-(void)_dismissDialog;
@end

@interface _SFDimmingButton : UIButton {}
@end


@interface _SFDownloadController : NSObject {}
- (void)_beginDownloadBackgroundTask:(id)arg1;
@end

@interface _SFFindOnPageView : UIView {}
- (void)setShouldFocusTextField:(BOOL)arg1;
- (void)showFindOnPage;
@end

@interface _SFFluidProgressView : UIView {}
@property (nonatomic,retain) UIColor* progressBarFillColor;
@end

@interface _SFSiteIconView : UIImageView {}
@end

@interface _SFNavigationBar : UIView {}
@end

@interface _SFNavigationBarBackdrop : _UIBackdropView {}
@property (nonatomic, retain) UIView* grayscaleTintView;
@end

@interface _SFNavigationBarURLButton : UIButton {} //iOS 9 + 10
//new stuff below
@property(nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeLeftGestureRecognizer;
@property(nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeRightGestureRecognizer;
@property(nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeDownGestureRecognizer;
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
@property (nonatomic,readonly) long long toolbarSize;
@end


/**** SafariShared ****/

@interface WBSBookmarkAndHistoryCompletionMatch : NSObject {}
- (id)originalURLString;
@end

/**** AVKit ****/

@interface AVPlayerController : UIResponder
@property (nonatomic, retain) AVPlayer *player;
@end

@interface AVPlaybackControlsViewController : UIViewController
@property (nonatomic) AVPlayerViewController* playerViewController;
@property (nonatomic, retain) AVPlayerController* playerController;
- (BOOL)isPlaying;
- (void)setPlaying:(BOOL)arg1;
//new methods below
- (void)downloadButtonPressed;
- (void)presentErrorAlertWithError:(NSError*)error;
- (void)presentNotFoundError;
@end

@interface AVButton : UIButton
@end

@interface AVFullScreenPlaybackControlsViewController : AVPlaybackControlsViewController
@property (nonatomic, retain) AVButton* downloadButton; //new
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
//new stuff below
- (void)downloadsFromButtonBar;
@end

@interface Application : UIApplication <UIApplicationDelegate> {}
@property (nonatomic,readonly) ApplicationShortcutController* shortcutController;
@property (nonatomic,readonly) NSArray* browserControllers;
- (BOOL)isPrivateBrowsingEnabledInAnyWindow;
//new stuff below
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler;
@end

@interface ApplicationShortcutController : NSObject {}
@property (assign,nonatomic) BrowserController* browserController;
@end

@interface BrowserController : UIResponder <BrowserToolbarDelegate> {}
@property (nonatomic,readonly) TabController* tabController;
@property (nonatomic,readonly) BrowserToolbar* bottomToolbar;
@property (nonatomic,readonly) BrowserRootViewController* rootViewController;
@property (nonatomic) BOOL shouldFocusFindOnPageTextField; //iOS9
- (void)_toggleTabViewKeyPressed;
- (BOOL)isShowingTabView;
- (void)togglePrivateBrowsing;
- (BOOL)privateBrowsingEnabled;
- (void)updateTabOverviewFrame;
- (id)loadURLInNewTab:(id)arg1 inBackground:(BOOL)arg2;
- (id)loadURLInNewTab:(id)arg1 inBackground:(BOOL)arg2 animated:(BOOL)arg3;
- (void)dismissTransientUIAnimated:(BOOL)arg1;
- (void)clearHistoryMessageReceived;
- (void)clearAutoFillMessageReceived;
- (BOOL)isPrivateBrowsingEnabled; //iOS11
- (void)togglePrivateBrowsingEnabled; //iOS11
- (void)showFindOnPage; //iOS9
//new stuff below
- (void)handleGesture:(NSInteger)swipeAction;
- (void)downloadsFromButtonBar;
- (void)clearData;
- (void)modeSwitchAction:(int)switchToMode;
- (void)autoCloseAction;
@end

//iOS9
@interface BrowserController (BrowserControllerTabs) {}
- (id)loadURLInNewWindow:(id)arg1 inBackground:(BOOL)arg2;
- (id)loadURLInNewWindow:(id)arg1 inBackground:(BOOL)arg2 animated:(BOOL)arg3;
- (void)newTabKeyPressed; //iOS8
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
@property (nonatomic,retain) UIToolbar* replacementToolbar;
- (void)updateTintColor;
//new stuff below
@property (nonatomic,retain) UIBarButtonItem* _downloadsItem;
- (void)setDownloadsEnabled:(BOOL)enabled;
- (BOOL)usesTabBar;
@end

@interface CatalogViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {}
@property (nonatomic,retain) UnifiedField* textField;
-  (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (id)_completionItemAtIndexPath:(id)arg1;
- (void)_textFieldEditingChanged;
@end

@interface CompletionListTableViewController : UITableViewController {}
@end


@interface FindOnPageView : _SFFindOnPageView {}
@end

@interface GestureRecognizingBarButtonItem : UIBarButtonItem {}
@property (nonatomic,retain) UIGestureRecognizer* gestureRecognizer;
- (void)setGestureRecognizer:(UIGestureRecognizer *)arg1;
- (UIGestureRecognizer *)gestureRecognizer;
- (void)setView:(id)arg1;
@end

@interface NavigationBar : _SFNavigationBar {}
@property (nonatomic,readonly) UnifiedField* textField;
- (void)_updateControlTints;
//new methods below
- (void)didSwipe:(UISwipeGestureRecognizer*)swipe;
@end

@interface NavigationBarURLButton : UIView {} //iOS 8
//new stuff below
@property(nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeLeftGestureRecognizer;
@property(nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeRightGestureRecognizer;
@property(nonatomic, retain) UISwipeGestureRecognizer *URLBarSwipeDownGestureRecognizer;
@end

@interface SafariWebView : WKWebView {}
@end

@interface SearchSuggestion : NSObject {}
- (NSString *)string;
@end

@interface TabController : NSObject {}
@property (nonatomic,copy,readonly) NSArray* tabDocuments;
@property (nonatomic,copy,readonly) NSArray* privateTabDocuments;
@property (nonatomic,copy,readonly) NSArray* allTabDocuments;
@property (nonatomic,copy,readonly) NSArray* currentTabDocuments; //iOS 10 only
@property (nonatomic,retain,readonly) TiltedTabView* tiltedTabView;
@property (nonatomic,retain) TabDocument* activeTabDocument;
@property (nonatomic,retain,readonly) TabOverview* tabOverview;
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
@property (assign,nonatomic) BrowserController* browserController;
@property (nonatomic,readonly) _SFReloadOptionsController* reloadOptionsController;
@property (nonatomic,readonly) _SFTabStateData* tabStateData;
@property (nonatomic,readonly) SafariWebView* webView;
@property (nonatomic,copy) NSString* customUserAgent;
@property (nonatomic,readonly) FindOnPageView* findOnPageView;
@property (nonatomic,retain) _SFDownloadController* downloadController;
@property (nonatomic,readonly) TiltedTabItem* tiltedTabItem;
@property (nonatomic,readonly) TabOverviewItem* tabOverviewItem;
- (NSURL*)URL;
- (BOOL)isBlankDocument;
- (void)_loadURLInternal:(id)arg1 userDriven:(BOOL)arg2;
- (void)_loadStartedDuringSimulatedClickForURL:(id)arg1;
- (void)reload;
- (BOOL)privateBrowsingEnabled;
- (WebBookmark*)readingListBookmark;
- (void)_closeTabDocumentAnimated:(BOOL)arg1;
- (void)_animateElement:(id)arg1 toToolbarButton:(int)arg2;
- (void)loadURL:(id)arg1 userDriven:(BOOL)arg2;
- (void)setCustomUserAgent:(NSString *)arg1;
- (void)stopLoading;
- (void)webView:(WKWebView*)arg1 decidePolicyForNavigationResponse:(WKNavigationResponse*)arg2 decisionHandler:(void (^)(void))arg3;
- (void)requestDesktopSite; //iOS 8
//new methods below
- (NSURL*)URLHandler:(NSURL*)URL;
- (BOOL)shouldRequestHTTPS:(NSURL*)URL;
@end

//iOS 8
@interface TabDocumentWK2 : TabDocument {}
@end

@interface TabOverview : UIView {}
@property (nonatomic,readonly) UIButton* privateBrowsingButton;
//new stuff below
@property (nonatomic, retain) UIButton* desktopModeButton;
- (void)userAgentButtonLandscapePressed;
@end

@interface TabOverviewItem : NSObject
@property (nonatomic,retain) TabOverviewItemLayoutInfo* layoutInfo;
@end

@interface TabOverviewItemLayoutInfo : NSObject
@property (nonatomic,retain) TabOverviewItemView * itemView;
@end

@interface TiltedTabView : UIView {}
- (void)setShowsExplanationView:(BOOL)arg1 animated:(BOOL)arg2;
- (void)setShowsPrivateBrowsingExplanationView:(BOOL)arg1 animated:(BOOL)arg2; //iOS 11
@end

@interface TabThumbnailView : UIView {}
@property (nonatomic,readonly) UIButton* closeButton;
@property(nonatomic, assign) BOOL isLocked; //new
@property(nonatomic, retain) UIButton* lockButton; //new
- (void)layoutSubviews;
@end

@interface TabOverviewItemView : TabThumbnailView
@end

@interface TiltedTabThumbnailView : TabThumbnailView
@end

@interface TiltedTabItem : NSObject {}
@property (nonatomic,readonly) TiltedTabItemLayoutInfo* layoutInfo;
@end

@interface TiltedTabItemLayoutInfo : NSObject
@property (nonatomic,retain) TiltedTabThumbnailView* contentView;
@end

@interface UnifiedField : UITextField {}
- (void)_textDidChangeFromTyping;
- (void)setText:(id)arg1;
@end
