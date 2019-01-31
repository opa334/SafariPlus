// SafariPlus.h
// (c) 2018 opa334

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#ifdef SIMJECT
#import "substrate.h"
#endif

#import <WebKit/WKNavigationAction.h>
#import <WebKit/WKNavigationResponse.h>
#import <WebKit/WKWebView.h>
#import "Protocols.h"

@class ApplicationShortcutController, AVPlayer, AVPlayerViewController, AVActivityButton, BrowserController, BrowserRootViewController, BrowserToolbar, CWSPStatusBarNotification, DownloadDispatcher, NavigationBar, SafariWebView, TabController, TabDocument, TabOverview, TabOverviewItem, TabOverviewItemView, TabOverviewItemLayoutInfo, TiltedTabItem, TiltedTabView, TiltedTabItemLayoutInfo, TabThumbnailView, UnifiedField, WebBookmark;

/**** General stuff ****/

@interface LSAppLink : NSObject
@property (assign) NSInteger openStrategy;
+ (void)getAppLinkWithURL:(id)arg1 completionHandler:(void (^)(LSAppLink*,NSError*))arg2;
- (void)openInWebBrowser:(BOOL)arg1 setOpenStrategy:(NSInteger)arg2 webBrowserState:(id)arg3 completionHandler:(id)arg4;
@end

@interface _UIBackdropView : UIView
@property (nonatomic, retain) UIView* contentView;
@property (nonatomic, retain) UIView* grayscaleTintView;
@end

@interface _UIBackdropViewSettings : NSObject
@end

@interface _UIBarBackground : UIView
@property (nonatomic,retain) UIView* customBackgroundView;
@end

@interface UIImage(Private)
- (UIImage*)_flatImageWithColor:(UIColor*)color;
@end

@interface _UINavigationControllerPalette : UIView
- (BOOL)isAttached;
@end

@interface UINavigationController(Private)
- (id)paletteForEdge:(NSUInteger)arg1 size:(CGSize)arg2;
- (void)attachPalette:(id)arg1 isPinned:(BOOL)arg2;
@end

@interface UISegmentedControl(Private)
+ (double)defaultHeightForStyle:(NSInteger)arg1 size:(int)arg2;
@end

/**** WebKit ****/

@interface WKNavigationAction ()
@property (getter=_isUserInitiated, nonatomic, readonly) bool _userInitiated;
@property (nonatomic,readonly) BOOL _shouldOpenAppLinks;
@end

@interface WKNavigationResponse ()
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
@property (nonatomic, readonly) NSURL* URL;
@property (nonatomic,readonly) NSInteger type;
@property (nonatomic,copy,readonly) UIImage* image;
@property (nonatomic,readonly) NSString* ID;
@property (nonatomic,readonly) NSString* title;
@end

@interface _WKElementAction : NSObject {}
+ (id)elementActionWithTitle:(id)arg1 actionHandler:(id)arg2;
@end

/**** MediaRemote ****/
extern "C"
{

extern CFStringRef kMRMediaRemoteNowPlayingInfoTitle;
typedef void (^MRMediaRemoteGetNowPlayingInfoCompletion)(CFDictionaryRef information);
void MRMediaRemoteGetNowPlayingInfo(dispatch_queue_t queue, MRMediaRemoteGetNowPlayingInfoCompletion completion);

}

/**** SafariServices ****/

@interface SFCrossfadingLabel : UILabel {}
@end

@interface _SFBookmarkInfoViewController : UITableViewController {}
@end

@interface _SFBrowserSavedState : NSObject {}
@end

@interface _SFDialog : NSObject {}
@property (nonatomic,copy,readonly) NSString* defaultText;
- (void)finishWithPrimaryAction:(BOOL)arg1 text:(id)arg2;
@end

@interface _SFDialogController : NSObject {}
- (void)_dismissDialog;
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
@property (nonatomic, weak) BrowserController* delegate;
@end

@interface _SFNavigationBarBackdrop : _UIBackdropView {}
@property (assign,nonatomic) NavigationBar* navigationBar;
@end

@interface _SFNavigationBarURLButton : UIButton {} //iOS 9 + 10
//new stuff below
@property(nonatomic, retain) UISwipeGestureRecognizer* URLBarSwipeLeftGestureRecognizer;
@property(nonatomic, retain) UISwipeGestureRecognizer* URLBarSwipeRightGestureRecognizer;
@property(nonatomic, retain) UISwipeGestureRecognizer* URLBarSwipeDownGestureRecognizer;
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
@property (nonatomic) UIColor* tintColor;
@property (nonatomic,readonly) NSInteger toolbarSize;
@end


/**** SafariShared ****/

@interface WBSBookmarkAndHistoryCompletionMatch : NSObject {}
- (id)originalURLString;
@end

/**** AVKit ****/

@interface AVPlayerController : UIResponder
@property (nonatomic, retain) AVPlayer* player;
@end

@interface AVPlaybackControlsViewController : UIViewController
@property (nonatomic) AVPlayerViewController* playerViewController;
@property (nonatomic, retain) AVPlayerController* playerController;
- (BOOL)isPlaying;
- (void)setPlaying:(BOOL)arg1;
@end

@interface AVButton : UIButton
@end

@interface AVFullScreenPlaybackControlsViewController : AVPlaybackControlsViewController <SourceVideoDelegate>
//new
@property (nonatomic, retain) AVActivityButton* downloadButton;
@property (nonatomic, retain) NSMutableArray* additionalLayoutConstraints;
- (void)downloadButtonPressed;
@end

//iOS 11

@interface AVPlayerViewController : UIViewController
@property (nonatomic,readonly) UIViewController* fullScreenViewController;
@end

@interface AVValueTiming : NSObject
@property (nonatomic,readonly) double anchorTimeStamp;
@end

@interface WebAVPlayerController : NSObject
@property (getter=isPlaying) BOOL playing;
@property (retain) AVValueTiming* timing;
- (void)play:(id)arg1;
- (void)pause:(id)arg1;
@end

@interface AVPlaybackControlsController : NSObject
@property (assign,nonatomic) AVPlayerController* playerController;
@property (nonatomic,readonly) AVPlayerViewController* playerViewController;
@end

@interface AVStackView : UIStackView
@end

@interface AVBackdropView : UIView
@property (nonatomic,readonly) AVStackView* contentView; //iOS 11.0 -> 11.2.6
@property (nonatomic,readonly) UIStackView* stackView; //iOS 11.3 and above
@end

@interface AVPlayerViewControllerContentView
@property (assign,nonatomic) AVPlaybackControlsController* delegate;
@end

@interface AVPlaybackControlsView : UIView <SourceVideoDelegate>
@property (assign,nonatomic) AVPlayerViewControllerContentView* delegate;
@property (nonatomic,readonly) AVBackdropView* screenModeControls;
@property (assign,getter=isDoubleRowLayoutEnabled,nonatomic) bool doubleRowLayoutEnabled;
@property (nonatomic,readonly) AVButton* doneButton;
//new
@property(nonatomic,retain) AVActivityButton* downloadButton;
- (void)downloadButtonPressed;
- (void)setUpDownloadButton;
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
- (void)handleTwitterAlert;
- (void)handleSBConnectionTest;
- (void)application:(UIApplication*)application handleEventsForBackgroundURLSession:(NSString*)identifier completionHandler:(void (^)(void))completionHandler;
@end

@interface ApplicationShortcutController : NSObject {}
@property (assign,nonatomic) BrowserController* browserController;
@end

@interface BrowserController : UIResponder <BrowserToolbarDelegate> {}
@property (nonatomic,readonly) TabController* tabController;
@property (nonatomic,readonly) BrowserToolbar* bottomToolbar;
@property (nonatomic,readonly) BrowserRootViewController* rootViewController;
@property (nonatomic,readonly) NSUUID* UUID;
@property (readonly, nonatomic) NavigationBar* navigationBar;
@property (nonatomic,readonly) BrowserToolbar* activeToolbar;
@property(readonly, nonatomic) BrowserToolbar* topToolbar;
@property (nonatomic, getter=isShowingTabBar) BOOL showingTabBar;
@property (nonatomic) BOOL shouldFocusFindOnPageTextField; //iOS9
@property(readonly, nonatomic, getter=isFavoritesFieldFocused) BOOL favoritesFieldFocused;
@property(readonly, nonatomic, getter=isShowingTabView) BOOL showingTabView;
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
- (BOOL)_shouldShowTabBar;
- (void)updateUsesTabBar;
- (void)setFavoritesState:(int)arg1 animated:(BOOL)arg2;
- (BOOL)isPrivateBrowsingEnabled; //iOS11
- (void)togglePrivateBrowsingEnabled; //iOS11
- (void)showFindOnPage; //iOS9
- (id)loadURLInNewWindow:(id)arg1 inBackground:(BOOL)arg2; //iOS9
- (id)loadURLInNewWindow:(id)arg1 inBackground:(BOOL)arg2 animated:(BOOL)arg3; //iOS9
- (void)newTabKeyPressed; //iOS8
//new stuff below
@property(nonatomic, retain) UISwipeGestureRecognizer* URLBarSwipeLeftGestureRecognizer;
@property(nonatomic, retain) UISwipeGestureRecognizer* URLBarSwipeRightGestureRecognizer;
@property(nonatomic, retain) UISwipeGestureRecognizer* URLBarSwipeDownGestureRecognizer;
- (void)handleGesture:(NSInteger)swipeAction;
- (void)downloadsFromButtonBar;
- (void)clearData;
- (void)modeSwitchAction:(int)switchToMode;
- (void)autoCloseAction;
@end

@interface BrowserRootViewController : UIViewController {}
@property (nonatomic,weak,readonly) BrowserController* browserController;
@end

@interface BrowserToolbar : _SFToolbar {}
@property (assign,nonatomic) BrowserController* browserDelegate;
@property (nonatomic,retain) UIToolbar* replacementToolbar;
@property(nonatomic) BOOL hasDarkBackground; //iOS8
- (void)updateTintColor;
//new stuff below
@property (nonatomic,retain) UIBarButtonItem* _downloadsItem;
- (void)setDownloadsEnabled:(BOOL)enabled;
@end

@interface CatalogViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {}
@property (nonatomic,retain) UnifiedField* textField;
-  (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;
- (id)_completionItemAtIndexPath:(id)arg1;
- (void)_textFieldEditingChanged;
@end

@interface CompletionListTableViewController : UITableViewController {}
@end


@interface FindOnPageView : _SFFindOnPageView {}
@end

@interface GestureRecognizingBarButtonItem : UIBarButtonItem {}
@property (nonatomic,retain) UIGestureRecognizer* gestureRecognizer;
- (void)setGestureRecognizer:(UIGestureRecognizer*)arg1;
- (UIGestureRecognizer*)gestureRecognizer;
- (void)setView:(id)arg1;
@end

@interface NavigationBar : _SFNavigationBar {}
@property (nonatomic,readonly) UnifiedField* textField;
@property(nonatomic, getter=isUsingLightControls) BOOL usingLightControls;
- (UIImage*)_lockImageWithTint:(UIColor*)tint usingMiniatureVersion:(BOOL)miniatureVersion;
- (void)_updateControlTints;
- (UIColor*)_placeholderColor;
@end

@interface NavigationBarBackdrop : _UIBackdropView
@property(nonatomic) NavigationBar* navigationBar;
@end

@interface NavigationBarURLButton : UIView {} //iOS 8
//new stuff below
@property(nonatomic, retain) UISwipeGestureRecognizer* URLBarSwipeLeftGestureRecognizer;
@property(nonatomic, retain) UISwipeGestureRecognizer* URLBarSwipeRightGestureRecognizer;
@property(nonatomic, retain) UISwipeGestureRecognizer* URLBarSwipeDownGestureRecognizer;
@property(nonatomic, weak) NavigationBar* delegate;
@end

@interface SafariWebView : WKWebView {}
@end

@interface SearchSuggestion : NSObject {}
- (NSString*)string;
@end

@interface TabBar : UIView
@property(nonatomic) NSUInteger barStyle; //iOS 8
@end

@interface TabBarStyle : NSObject
@end

@interface TabBarItemView : UIView
@property(nonatomic, getter=isActive) BOOL active;
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
- (void)closeTabDocument:(id)arg1 animated:(BOOL)arg2;
- (void)closeAllOpenTabsAnimated:(BOOL)arg1 exitTabView:(BOOL)arg2;
- (BOOL)isPrivateBrowsingEnabled;
- (void)closeTab;
- (void)newTab;
//new stuff below
@property (assign,nonatomic) BOOL desktopButtonSelected;
@property (nonatomic,retain) UIButton* tiltedTabViewDesktopModeButton;
- (void)loadDesktopButtonState;
- (void)saveDesktopButtonState;
- (void)updateUserAgents;
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
@property (assign,getter=isBlankDocument,nonatomic) BOOL blankDocument;
+ (id)tabDocumentForWKWebView:(id)arg1;
- (NSURL*)URL;
- (BOOL)isBlankDocument;
- (id)_loadURLInternal:(NSURL*)arg1 userDriven:(BOOL)arg2;
- (void)_loadStartedDuringSimulatedClickForURL:(id)arg1;
- (void)reload;
- (BOOL)privateBrowsingEnabled;
- (WebBookmark*)readingListBookmark;
- (void)_closeTabDocumentAnimated:(BOOL)arg1;
- (void)_animateElement:(id)arg1 toToolbarButton:(int)arg2;
- (void)loadURL:(id)arg1 userDriven:(BOOL)arg2;
- (void)stopLoading;
- (void)webView:(WKWebView*)arg1 decidePolicyForNavigationResponse:(WKNavigationResponse*)arg2 decisionHandler:(void (^)(void))arg3;
- (void)_closeTabDocumentAnimated:(BOOL)arg1;
- (BOOL)isHibernated;
- (void)_openAppLinkInApp:(id)arg1 fromOriginalRequest:(id)arg2 updateAppLinkStrategy:(_Bool)arg3 webBrowserState:(id)arg4 completionHandler:(id)arg5;
- (void)requestDesktopSite; //iOS 8
//new stuff below
- (void)updateDesktopMode;
- (BOOL)shouldRequestHTTPS:(NSURL*)URL;
@property(nonatomic) BOOL desktopMode;
@end

//iOS 8
@interface TabDocumentWK2 : TabDocument {}
@end

@interface TabOverview : UIView {}
@property(readonly, nonatomic) UIButton* addTabButton;
@property(nonatomic,readonly) UIButton* privateBrowsingButton;
@property(nonatomic, weak) TabController* delegate;
//new stuff below
@property (nonatomic, retain) UIButton* desktopModeButton;
- (void)userAgentButtonLandscapePressed;
@end

@interface TabOverviewItem : NSObject
@property (nonatomic,retain) TabOverviewItemLayoutInfo* layoutInfo;
@property (nonatomic,weak) TabOverview* tabOverview;
@end

@interface TabOverviewItemLayoutInfo : NSObject
@property (nonatomic,retain) TabOverviewItemView* itemView;
@end

@interface TiltedTabView : UIView {}
@property (nonatomic,weak) BrowserController* delegate;
- (void)setShowsExplanationView:(BOOL)arg1 animated:(BOOL)arg2;
- (void)setShowsPrivateBrowsingExplanationView:(BOOL)arg1 animated:(BOOL)arg2; //iOS 11
@end

@interface TabThumbnailHeaderView : UIView
@end

@interface TabThumbnailView : UIView {}
@property (nonatomic,readonly) UIButton* closeButton;
@property (nonatomic) BOOL usesDarkTheme;
//@property(nonatomic, assign) BOOL isLocked; //new
//@property(nonatomic, retain) UIButton* lockButton; //new
- (void)layoutSubviews;
@end

@interface TabOverviewItemView : TabThumbnailView
@end

@interface TiltedTabThumbnailView : TabThumbnailView
@end

@interface TiltedTabItem : NSObject {}
@property (nonatomic,readonly) TiltedTabItemLayoutInfo* layoutInfo;
@property (nonatomic,weak) TiltedTabView* tiltedTabView;
@end

@interface TiltedTabItemLayoutInfo : NSObject
@property (nonatomic,retain) TiltedTabThumbnailView* contentView;
@end

@interface UnifiedField : UITextField {}
- (void)_textDidChangeFromTyping;
- (void)setText:(id)arg1;
- (void)setInteractionTintColor:(UIColor*)interactionTintColor;
@end
