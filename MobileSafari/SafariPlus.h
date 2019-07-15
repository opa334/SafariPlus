// SafariPlus.h
// (c) 2017 - 2019 opa334

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
#import <WebKit/WKNavigationDelegate.h>

#import "Protocols.h"

@class _WKActivatedElementInfo, ApplicationShortcutController, AVPlayer, AVPlayerViewController, AVActivityButton, BrowserController, BrowserRootViewController, BrowserToolbar, DownloadDispatcher, NavigationBar, SafariWebView, SearchEngineInfo, SPTabManagerTableViewCell, TabBarStyle, TabBarItemLayoutInfo, TabBarItemView, TabController, TabDocument, TabOverview, TabOverviewItem, TabOverviewItemView, TabOverviewItemLayoutInfo, TiltedTabItem, TiltedTabView, TiltedTabItemLayoutInfo, TabThumbnailView, UnifiedField, WebBookmark;

/**** General stuff ****/

#if defined __cplusplus
extern "C" {
#endif

enum sandbox_filter_type
{
	SANDBOX_FILTER_NONE,
	SANDBOX_FILTER_PATH,
	SANDBOX_FILTER_GLOBAL_NAME,
	SANDBOX_FILTER_LOCAL_NAME,
	SANDBOX_FILTER_APPLEEVENT_DESTINATION,
	SANDBOX_FILTER_RIGHT_NAME,
};

extern const enum sandbox_filter_type SANDBOX_CHECK_NO_REPORT __attribute__((weak_import));

int sandbox_check(pid_t pid, const char *operation, int type, ...);

CGImageRef LICreateIconForImage(CGImageRef image, int variant, int precomposed);

#if defined __cplusplus
};
#endif

@interface LSAppLink : NSObject
@property (assign) NSInteger openStrategy;
+ (void)getAppLinkWithURL:(id)arg1 completionHandler:(void (^)(LSAppLink*,NSError*))arg2;
- (void)openInWebBrowser:(BOOL)arg1 setOpenStrategy:(NSInteger)arg2 webBrowserState:(id)arg3 completionHandler:(id)arg4;
@end

@interface _LSLazyPropertyList : NSObject
@property (readonly) NSDictionary* propertyList;
+ (id)lazyPropertyListWithPropertyList:(id)arg1;
@end

@interface LSDocumentProxy : NSObject
@property (nonatomic,readonly) NSString* containerOwnerApplicationIdentifier;
@property (setter=_setBoundIconsDictionary:,nonatomic,copy) _LSLazyPropertyList* _boundIconsDictionary;
@property (nonatomic,readonly) NSDictionary* iconsDictionary;
+ (id)documentProxyForURL:(id)arg1;
+ (id)documentProxyForName:(id)arg1 type:(id)arg2 MIMEType:(id)arg3;
@end

@interface NSUserDefaults (Safari)
+ (NSUserDefaults*)_sf_safariDefaults;
@end

@interface _UIBackdropViewSettings : NSObject
@property (nonatomic,retain) UIColor* colorTint;
@property (nonatomic,retain) UIColor* legibleColor;
@property (assign,nonatomic) CGFloat colorTintAlpha;
@property (assign,nonatomic) BOOL usesGrayscaleTintView;
@property (assign,nonatomic) BOOL usesColorTintView;
@property (assign,nonatomic) CGFloat colorTintMaskAlpha;
@property (assign,nonatomic) CGFloat grayscaleTintAlpha;
+ (id)settingsForPrivateStyle:(NSInteger)privateStyle;
@end

@interface _UIBackdropViewSettingsColored : _UIBackdropViewSettings
@end

@interface _UIBackdropView : UIView
@property (nonatomic, retain) UIView* contentView;
@property (nonatomic, retain) UIView* grayscaleTintView;
@property (nonatomic,retain) _UIBackdropViewSettings* inputSettings;
- (void)transitionToSettings:(_UIBackdropViewSettings*)settings;
- (void)transitionToPrivateStyle:(NSInteger)arg1;
@end

@interface _UIBarBackground : UIView
@property (nonatomic,retain) UIView* customBackgroundView;
@end

@interface _UIButtonBarButtonVisualProviderIOS : NSObject
@property (nonatomic,readonly) UIButton* imageButton;
@end

@interface _UIButtonBarButton : UIView
@property (nonatomic,copy,readonly) _UIButtonBarButtonVisualProviderIOS* visualProvider;
@end

@interface UIImage (Private)
+ (UIImage*)_iconForResourceProxy:(LSDocumentProxy*)arg1 variant:(int)arg2 variantsScale:(CGFloat)arg3;
+ (UIImage*)_iconForResourceProxy:(LSDocumentProxy*)arg1 format:(int)arg2 options:(NSUInteger)arg3;
+ (UIImage*)imageNamed:(NSString*)arg1 inBundle:(NSBundle*)arg2;
- (UIImage*)_flatImageWithColor:(UIColor*)color;
@end

@interface _UINavigationControllerPalette : UIView
- (BOOL)isAttached;
@end

@interface UIAlertController (Private)
- (void)_removeAllActions;
- (void)_setActions:(id)arg1;
@end

@interface UINavigationController (Private)
- (id)paletteForEdge:(NSUInteger)arg1 size:(CGSize)arg2;
- (void)attachPalette:(id)arg1 isPinned:(BOOL)arg2;
@end

@interface UISegmentedControl (Private)
+ (CGFloat)defaultHeightForStyle:(NSInteger)arg1 size:(int)arg2;
@end

@interface UIBarButtonItem (Safari)
//iOS 11.2.6 and below
- (void)_sf_setLongPressTarget:(id)target action:(SEL)action;
//iOS 11.3 and above
- (void)_sf_setTarget:(id)target longPressAction:(SEL)longPressAction;
- (void)_sf_setTarget:(id)target touchDownAction:(SEL)touchDownAction longPressAction:(SEL)longPressAction;
@end

@interface UIBarButtonItem (Private)
- (UIView*)view;
+ (void)_getSystemItemStyle:(NSInteger*)arg1 title:(id*)arg2 image:(UIImage**)arg3 selectedImage:(UIImage**)arg4 action:(SEL*)arg5 forBarStyle:(NSInteger)arg6 landscape:(BOOL)arg7 alwaysBordered:(BOOL)arg8 usingSystemItem:(NSInteger)arg9 usingItemStyle:(NSInteger)arg10;
@property (nonatomic) NSInteger systemItem;
@property (assign,setter=_setAdditionalSelectionInsets:,nonatomic) UIEdgeInsets _additionalSelectionInsets;
@property (setter=_setGestureRecognizers:,nonatomic,retain) NSArray* _gestureRecognizers;
- (BOOL)isSystemItem;
@end

@interface UIAlertAction (Private)
@property (setter=_setRepresenter:) id _representer;
- (void)setTitle:(NSString*)arg1;
@end

@interface UIImage (Safari)
+ (UIImage*)ss_imageNamed:(NSString*)name;
@end

@interface UIWindow (Safari)
@property (nonatomic) CGRect _sf_bottomUnsafeAreaFrameForToolbar;
@end

@interface UIView (Safari)
- (BOOL)_sf_usesLeftToRightLayout;
@end

@interface UIView (Private)
- (void)removeAllGestureRecognizers;
@end

@interface CALayer (Private)
@property (assign) BOOL allowsGroupBlending;
@end

@interface WebBookmark
@property (nonatomic,readonly) int identifier;
@property (nonatomic,readonly) NSString* UUID;
- (instancetype)initWithTitle:(NSString*)arg1 address:(NSString*)arg2;
@end

@interface WebBookmarkCollection
+ (instancetype)safariBookmarkCollection;
+ (BOOL)isLockedSync;
+ (void)unlockSync;
+ (BOOL)lockSync;
- (WebBookmark*)favoritesFolder;
- (WebBookmark*)bookmarkWithUUID:(NSString*)arg1;
- (BOOL)moveBookmark:(id)arg1 toFolderWithID:(int)arg2;
- (BOOL)saveBookmark:(id)arg1;
@end

/*@interface NSKeyedUnarchiver (Private)
 + (id)unarchivedObjectOfClass:(Class)cls fromData:(NSData*)data error:(NSError**)error;
   @end*/

/**** WebKit ****/

@interface WKContentView : UIView
- (void)_zoomOutWithOrigin:(CGPoint)arg1;
@end

@interface WKNavigationAction (Private)
@property (getter=_isUserInitiated, nonatomic, readonly) bool _userInitiated;
@property (nonatomic,readonly) BOOL _shouldOpenAppLinks;
@property (nonatomic,readonly) CGPoint _clickLocationInRootViewCoordinates;
@end

@interface WKNavigationResponse (Private)
@property (nonatomic,readonly) NSURLRequest* _request;
@end

@interface WKWebView (Private)
@property (setter=_setApplicationNameForUserAgent:,copy) NSString* _applicationNameForUserAgent;
- (void)_requestActivatedElementAtPosition:(CGPoint)position completionBlock:(void (^)(_WKActivatedElementInfo *))block;
- (void)_setCustomUserAgent:(NSString*)arg1;
- (WKContentView*)_currentContentView;
@end

@interface WKFileUploadPanel <filePickerDelegate>
- (void)_presentPopoverWithContentViewController:(id)arg1 animated:(BOOL)arg2;
- (void)_presentFullscreenViewController:(id)arg1 animated:(BOOL)arg2;
- (void)_dismissDisplayAnimated:(BOOL)arg1;
- (void)_chooseFiles:(id)arg1 displayString:(id)arg2 iconImage:(id)arg3;
- (void)_showFilePicker;
- (void)_cancel;
- (void)_showMediaSourceSelectionSheet;	//iOS8
@end

@interface _WKActivatedElementInfo : NSObject
@property (nonatomic, readonly) NSURL* URL;
@property (nonatomic,readonly) NSInteger type;
@property (nonatomic,copy,readonly) UIImage* image;
@property (nonatomic,readonly) NSString* ID;
@property (nonatomic,readonly) NSString* title;
@end

@interface _WKElementAction : NSObject
+ (id)elementActionWithTitle:(id)arg1 actionHandler:(id)arg2;
@end

/**** WebCore ****/

// *INDENT-OFF*
/*
namespace WTF
{
	class StringImpl
	{
	public:
		unsigned m_refCount;
    unsigned m_length;
		union
		{
        const char* m_data8;
        const char16_t* m_data16;
        const char* m_data8Char;
        const char16_t* m_data16Char;
    };
		mutable unsigned m_hashAndFlags;
	};

	class String
	{
	public:
		StringImpl* m_impl;
	};
}

#define m_currentSrc_off 159

namespace WebCore
{
	class URL
	{
	public:
		operator NSURL*() const;
	};

	class HTMLMediaElement
	{
	public:
	};

	class PlaybackSessionModel
	{
	public:
		virtual void pause() = 0;
	};

	class PlaybackSessionModelMediaElement final : public PlaybackSessionModel// final
	{
	public:
		//HTMLMediaElement* m_mediaElement; //This works because this is the first attribute, for everything else we have to add the offset to the object
		virtual void pause();
	};
}
*/
// *INDENT-ON*

/**** MediaRemote ****/
extern "C"
{

extern CFStringRef kMRMediaRemoteNowPlayingInfoTitle;
typedef void (^MRMediaRemoteGetNowPlayingInfoCompletion)(CFDictionaryRef information);
void MRMediaRemoteGetNowPlayingInfo(dispatch_queue_t queue, MRMediaRemoteGetNowPlayingInfoCompletion completion);

}

/**** SafariServices ****/

@interface _SFBarManager : NSObject
@property (nonatomic) BrowserController* delegate;
@end

@interface SFBarRegistration : UIResponder
- (UIBarButtonItem*)UIBarButtonItemForItem:(NSInteger)arg1;
@end

@interface SFCrossfadingLabel : UILabel
@end

@interface _SFBookmarkInfoViewController : UITableViewController
@end

@interface _SFBrowserSavedState : NSObject
@end

@interface _SFDialog : NSObject
@property (nonatomic,copy,readonly) NSString* defaultText;
- (void)finishWithPrimaryAction:(BOOL)arg1 text:(id)arg2;
- (void)completeWithResponse:(NSDictionary*)arg1;
@end

@interface _SFDialogController : NSObject
- (void)_dismissDialog;
- (void)_dismissDialogWithAdditionalAnimations:(id)arg1;
@end

@interface _SFDimmingButton : UIButton
@property (assign,nonatomic) CGFloat normalImageAlpha;
@property (assign,nonatomic) CGFloat highlightedImageAlpha;
@end

@interface _SFDownloadController : NSObject
- (void)_beginDownloadBackgroundTask:(id)arg1;
@end

@interface _SFFindOnPageView : UIView
- (void)setShouldFocusTextField:(BOOL)arg1;
- (void)showFindOnPage;
@end

@interface _SFFluidProgressView : UIView
@property (nonatomic,retain) UIColor* progressBarFillColor;
@end

@interface _SFSiteIconView : UIImageView
@end

@interface _SFNavigationBar : UIView
@property (nonatomic, weak) BrowserController* delegate;
@property (nonatomic, getter=isUsingLightControls) BOOL usingLightControls;
@property (nonatomic,readonly) CGRect URLOutlineFrameInNavigationBarSpace;
- (id)_backdropInputSettings;
@end

@interface _SFNavigationBarBackdrop : _UIBackdropView
@property (assign,nonatomic) NavigationBar* navigationBar;
@end

@interface _SFNavigationBarURLButton : UIButton								//iOS 9 + 10
//new stuff below
@property (nonatomic, retain) UISwipeGestureRecognizer* URLBarSwipeLeftGestureRecognizer;
@property (nonatomic, retain) UISwipeGestureRecognizer* URLBarSwipeRightGestureRecognizer;
@property (nonatomic, retain) UISwipeGestureRecognizer* URLBarSwipeDownGestureRecognizer;
@end

@interface SFNavigationBarReaderButton : UIButton	//_SFNavigationBarReaderButton on iOS 10 and below, but doesn't matter
- (void)setGlyphTintColor:(UIColor*)color;
@property (assign,nonatomic) BOOL drawsLightGlyph;
@end

@interface _SFReloadOptionsController : NSObject
@property (nonatomic,readonly) BOOL loadedUsingDesktopUserAgent;
- (void)requestDesktopSiteWithURL:(id)arg1;
- (void)requestDesktopSite;
@end

@interface _SFTabStateData : NSObject
- (BOOL)privateBrowsing;
@end

@interface _SFToolbar : UIToolbar
@property (nonatomic) UIColor* tintColor;
@property (nonatomic,readonly) NSInteger toolbarSize;
@property (nonatomic,readonly) CGFloat URLFieldHorizontalMargin;
- (id)_backdropInputSettings;
- (BOOL)_tintUsesDarkTheme;
- (BOOL)hasDarkBackground;
@end


/**** SafariShared ****/

@interface WBSCompletionQuery : NSObject
@property (nonatomic,readonly) NSString* queryString;
@property (assign,nonatomic) NSUInteger triggerEvent;
@end

@interface WBSBookmarkAndHistoryCompletionMatch : NSObject
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
@property (assign,nonatomic) CGSize extrinsicContentSize;
@property (assign,getter=isIncluded,nonatomic) BOOL included;
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
@property (nonatomic,readonly) CGFloat anchorTimeStamp;
@end

@interface WebAVPlayerController : NSObject
@property (getter=isPlaying) BOOL playing;
@property (retain) AVValueTiming* timing;
//@property (assign) WebCore::PlaybackSessionModel** delegate;
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
@property (nonatomic,readonly) AVStackView* contentView;//iOS 11.0 -> 11.2.6
@property (nonatomic,readonly) UIStackView* stackView;	//iOS 11.3 and above
@end

@interface AVTransportControlsView : UIView
@property (assign,nonatomic) AVPlaybackControlsController* delegate;
@end

@interface AVPlayerViewControllerContentView
@property (assign,nonatomic) AVPlaybackControlsController* delegate;
@end

@interface AVPlaybackControlsView : UIView <SourceVideoDelegate>
@property (assign,nonatomic) AVPlayerViewControllerContentView* delegate;
@property (nonatomic,readonly) AVTransportControlsView* transportControlsView;
@property (nonatomic,readonly) AVBackdropView* screenModeControls;
@property (assign,getter=isDoubleRowLayoutEnabled,nonatomic) bool doubleRowLayoutEnabled;
@property (nonatomic,readonly) AVButton* doneButton;
//new
@property (nonatomic,retain) AVActivityButton* downloadButton;
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


@protocol TabThumbnailCollectionView
@property (readonly, nonatomic) NSInteger presentationState;
@property (copy, nonatomic) NSString* searchTerm;
@end

@interface Application : UIApplication <UIApplicationDelegate>
@property (nonatomic,readonly) ApplicationShortcutController* shortcutController;
@property (nonatomic,readonly) NSArray* browserControllers;
- (BOOL)isPrivateBrowsingEnabledInAnyWindow;
//new stuff below
- (void)handleTwitterAlert;
- (void)handleSBConnectionTest;
- (void)application:(UIApplication*)application handleEventsForBackgroundURLSession:(NSString*)identifier completionHandler:(void (^)(void))completionHandler;
@end

@interface ApplicationShortcutController : NSObject
@property (assign,nonatomic) BrowserController* browserController;
@end

@interface BrowserController : UIResponder <BrowserToolbarDelegate>
@property (nonatomic,readonly) TabController* tabController;
@property (nonatomic,readonly) BrowserToolbar* bottomToolbar;
@property (nonatomic,readonly) BrowserRootViewController* rootViewController;
@property (nonatomic,readonly) NSUUID* UUID;
@property (readonly, nonatomic) BrowserToolbar* topToolbar;
@property (nonatomic, getter=isShowingTabBar) BOOL showingTabBar;
@property (nonatomic) BOOL shouldFocusFindOnPageTextField;	//iOS9
@property (readonly, nonatomic, getter=isFavoritesFieldFocused) BOOL favoritesFieldFocused;
@property (readonly, nonatomic, getter=isShowingTabView) BOOL showingTabView;
@property (readonly, nonatomic) BOOL usesTabBar;
- (void)_toggleTabViewKeyPressed;
- (BOOL)isShowingTabView;
- (void)togglePrivateBrowsing;
- (BOOL)privateBrowsingEnabled;
- (void)updateTabOverviewFrame;
- (id)loadURLInNewTab:(id)arg1 inBackground:(BOOL)arg2;
- (id)loadURLInNewTab:(id)arg1 inBackground:(BOOL)arg2 animated:(BOOL)arg3;
- (void)insertTabDocument:(TabDocument*)arg1 afterTabDocument:(TabDocument*)arg2 inBackground:(BOOL)arg3 animated:(BOOL)arg4;
- (void)dismissTransientUIAnimated:(BOOL)arg1;
- (void)clearHistoryMessageReceived;
- (void)clearAutoFillMessageReceived;
- (BOOL)_shouldShowTabBar;
- (void)updateUsesTabBar;
- (void)setFavoritesState:(NSInteger)arg1 animated:(BOOL)arg2;
- (BOOL)isPrivateBrowsingAvailable;
- (void)dismissTransientUIAnimated:(BOOL)arg1;
- (BOOL)_shouldShowTabBar;
- (void)_setPrivateBrowsingEnabled:(BOOL)arg1 showModalAuthentication:(BOOL)arg2 completion:(void (^)(void))arg3;		//iOS11
- (BOOL)isPrivateBrowsingEnabled;	//iOS11
- (void)togglePrivateBrowsingEnabled;	//iOS11
- (void)showFindOnPage;	//iOS9
- (id)loadURLInNewWindow:(id)arg1 inBackground:(BOOL)arg2;	//iOS9
- (id)loadURLInNewWindow:(id)arg1 inBackground:(BOOL)arg2 animated:(BOOL)arg3;	//iOS9
- (void)newTabKeyPressed;	//iOS8

//iOS 12.1.4 and below
@property (readonly, nonatomic) NavigationBar* navigationBar;
@property (nonatomic,readonly) BrowserToolbar* activeToolbar;

//new stuff below
@property (nonatomic, assign) BOOL browsingModeSet;
@property (nonatomic, retain) UISwipeGestureRecognizer* URLBarSwipeLeftGestureRecognizer;
@property (nonatomic, retain) UISwipeGestureRecognizer* URLBarSwipeRightGestureRecognizer;
@property (nonatomic, retain) UISwipeGestureRecognizer* URLBarSwipeDownGestureRecognizer;
- (void)handleGesture:(NSInteger)swipeAction;
- (void)downloadsFromButtonBar;
- (void)clearData;
- (void)modeSwitchAction:(int)switchToMode;
- (void)autoCloseAction;
- (void)updateTabExposeAlertForLockedTabs;
@end

@interface BrowserRootViewController : UIViewController
@property (nonatomic,weak,readonly) BrowserController* browserController;	//iOS10 and above
//iOS >=12.2
@property (readonly, nonatomic) NSInteger toolbarPlacement;
@property (readonly, nonatomic) BrowserToolbar* bottomToolbar;
@property (readonly, nonatomic) NavigationBar* navigationBar;
@property (nonatomic, getter=isShowingTabBar) BOOL showingTabBar;
@end

@interface BrowserToolbar : _SFToolbar
@property (assign,nonatomic) BrowserController* browserDelegate;
@property (nonatomic,retain) UIToolbar* replacementToolbar;
@property (nonatomic) BOOL hasDarkBackground;	//iOS8
- (void)updateTintColor;
//new stuff below
@property (nonatomic,retain) UIBarButtonItem* _downloadsItem;
@property (nonatomic,retain) UIBarButtonItem *_reloadItem;
@property (nonatomic,retain) UILabel* tabCountLabel;
@property (nonatomic,retain) UIImage *tabExposeImage;
- (void)setDownloadsEnabled:(BOOL)enabled;
- (void)updateTabCount;
- (NSMutableArray*)dynamicItemsForOrder:(NSArray*)order;
- (void)updateCustomBackgroundColorForStyle:(NSUInteger)style;
@end

@interface BookmarkInfoViewController : UITableViewController
- (instancetype)initWithBookmark:(id)arg1 inCollection:(id)arg2 addingBookmark:(BOOL)arg3 toFavorites:(BOOL)arg4 willBeDisplayedModally:(BOOL)arg5;
- (instancetype)initWithBookmark:(id)arg1 inCollection:(id)arg2 addingBookmark:(BOOL)arg3;
@end

@interface BookmarkFavoritesActionButton : UIButton
- (void)configureWithActivity:(UIActivity*)arg1;
@end

@interface BookmarkFavoritesActionsView : UIView
@property (nonatomic,retain) BookmarkFavoritesActionButton* toggleForceHTTPSButton;
@end

@interface CatalogViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic,retain) UnifiedField* textField;
@property (retain, nonatomic) NSString* queryString;
-  (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;
- (id)_completionItemAtIndexPath:(id)arg1;
- (void)_textFieldEditingChanged;
@end

@interface CompletionListTableViewController : UITableViewController
@end


@interface FindOnPageView : _SFFindOnPageView
@end

@interface GestureRecognizingBarButtonItem : UIBarButtonItem
@property (nonatomic,retain) UIGestureRecognizer* gestureRecognizer;
- (void)setGestureRecognizer:(UIGestureRecognizer*)arg1;
- (UIGestureRecognizer*)gestureRecognizer;
- (void)setView:(id)arg1;
@end

@interface LoadingController : NSObject
- (void)reload;
@end

@interface NavigationBar : _SFNavigationBar
@property (nonatomic,readonly) UIButton* reloadButton;
@property (nonatomic,readonly) UnifiedField* textField;
- (UIImage*)_lockImageWithTint:(UIColor*)tint usingMiniatureVersion:(BOOL)miniatureVersion;
- (void)_updateControlTints;
- (UIColor*)_placeholderColor;
//iOS >=12.2
- (BrowserToolbar*)toolbarPlacedOnTop;
@end

@interface NavigationBarBackdrop : _UIBackdropView
@property (nonatomic) NavigationBar* navigationBar;
@end

@interface NavigationBarURLButton : UIView						//iOS 8
//new stuff below
@property (nonatomic, retain) UISwipeGestureRecognizer* URLBarSwipeLeftGestureRecognizer;
@property (nonatomic, retain) UISwipeGestureRecognizer* URLBarSwipeRightGestureRecognizer;
@property (nonatomic, retain) UISwipeGestureRecognizer* URLBarSwipeDownGestureRecognizer;
@property (nonatomic, weak) NavigationBar* delegate;
@end

@interface SafariWebView : WKWebView
@property (nonatomic) TabDocument* delegate;
- (void)sp_updateCustomUserAgent;
- (void)sp_applyCustomUserAgent;
//new
@property (nonatomic) NSInteger desktopModeState;
@end

@interface SearchEngineController : NSObject
@property (readonly, copy, nonatomic) NSMutableArray* engines;
//new
@property (nonatomic, retain) SearchEngineInfo* customSearchEngine;
@end

@interface SearchEngineInfo : NSObject
@property (readonly, nonatomic) NSString *shortName;
+ (instancetype)engineFromDictionary:(NSDictionary*)arg1 withController:(id)arg2;
@end

@interface SearchSuggestion : NSObject
@property (nonatomic) BOOL goesToURL;
@property (nonatomic, retain) CatalogViewController* sp_handler;
- (NSString*)string;
@end

@interface SearchSuggestionTableViewCell : UITableViewCell
@property (nonatomic, retain) UIImageView* hiddenAccessoryView;	//new
- (void)setHidesAccessoryView:(BOOL)hidden;	//new (below 12.2)
@end

@interface TabBar8 : UIView
@property (nonatomic) NSUInteger barStyle;
@end

@interface TabBar : UIView
@property (readonly, nonatomic) TabBarStyle* barStyle;
@property (nonatomic, weak) TabController* delegate;
@end

@interface TabBarStyle : NSObject
@property (readonly, nonatomic) UIColor *itemTitleColor;
+ (UIImage*)_closeButtonWithColor:(UIColor*)color;
@end

@interface TabBarItem : NSObject <TabCollectionItem>
@property (retain, nonatomic) TabBarItemLayoutInfo *layoutInfo;
@end

@interface TabBarItemLayoutInfo : NSObject
@property (readonly, nonatomic, weak) TabBar* tabBar;
@property (readonly, nonatomic, weak) TabBarItem* tabBarItem;
@property (nonatomic) BOOL canClose;

//iOS 9
@property (readonly, nonatomic) TabBarItemView* rightView;
@property (readonly, nonatomic) TabBarItemView* leftView;

//iOS 10-11
@property (readonly, nonatomic) TabBarItemView* trailingView;
@property (readonly, nonatomic) TabBarItemView* leadingView;

//iOS 12+
@property (readonly, nonatomic) TabBarItemView* tabBarItemView;
@end

@interface TabBarItemView : UIView
@property (nonatomic, getter=isActive) BOOL active;
@property (readonly, nonatomic) UIButton* closeButton;
//new
@property (nonatomic, retain) UIButton* lockButton;
- (void)_layoutLockButton;
- (void)_layoutTitleLabelUsingCachedTruncation;
@end

@interface TabController : NSObject
@property (nonatomic,copy,readonly) NSArray* tabDocuments;
@property (nonatomic,copy,readonly) NSArray* privateTabDocuments;
@property (nonatomic,copy,readonly) NSArray* allTabDocuments;
@property (nonatomic,copy,readonly) NSArray* currentTabDocuments;
@property (nonatomic,retain,readonly) TiltedTabView* tiltedTabView;
@property (nonatomic,retain) TabDocument* activeTabDocument;
@property (nonatomic,retain,readonly) TabOverview* tabOverview;
@property (assign,nonatomic) BOOL usesTabBar;
@property (retain, nonatomic) NSString* searchTerm;	//iOS 11 and above
@property (readonly, nonatomic) NSArray* tabDocumentsMatchingSearchTerm;	//iOS 11 and above
@property (readonly, retain, nonatomic) TabBar* tabBar;
@property (readonly, nonatomic) UIView<TabThumbnailCollectionView>* tabThumbnailCollectionView;	//iOS 12.2 and above
@property(readonly, nonatomic) NSUInteger numberOfCurrentNonHiddenTabs; //iOS 12 and above
- (id)tabDocumentWithUUID:(NSUUID*)arg1;//iOS 11 and above
- (void)setActiveTabDocument:(id)arg1 animated:(BOOL)arg2;
- (void)closeTabDocument:(id)arg1 animated:(BOOL)arg2;
- (void)closeAllOpenTabsAnimated:(BOOL)arg1 exitTabView:(BOOL)arg2;
- (void)closeAllOpenTabsAnimated:(BOOL)arg1;
- (BOOL)isPrivateBrowsingEnabled;
- (void)closeTab;
- (void)newTab;
- (TabDocument*)_tabDocumentRepresentedByTiltedTabItem:(TiltedTabItem*)arg1;
- (TabDocument*)_tabDocumentRepresentedByTabOverviewItem:(TabOverviewItem*)arg1;
- (TabDocument*)_tabDocumentRepresentedByTabBarItem:(TabBarItem*)arg1;
- (void)tiltedTabView:(TiltedTabView*)arg1 didSelectItem:(TiltedTabItem*)arg2;
- (TabOverviewItem*)currentItemForTabOverview:(TabOverview*)arg1;
- (TiltedTabItem*)currentItemForTiltedTabView:(TiltedTabView*)arg1;
- (void)insertNewTabDocument:(TabDocument*)arg1 openedFromTabDocument:(TabDocument*)arg2 inBackground:(BOOL)arg3 animated:(BOOL)arg4;
- (void)dismissTabViewAnimated:(BOOL)arg1;
- (void)_updateTiltedTabViewItemsAnimated:(BOOL)arg1;
- (void)updateTabBarAnimated:(BOOL)arg1;
- (BOOL)_document:(TabDocument*)arg1 matchesSearchText:(NSString*)arg2;
- (void)_closeTabDocuments:(NSArray<TabDocument*>*)documents animated:(BOOL)arg2 temporarily:(BOOL)arg3 allowAddingToRecentlyClosedTabs:(BOOL)arg4 keepWebViewAlive:(BOOL)arg5;
- (void)closeTabsDocuments:(NSArray<TabDocument*>*)arg1;
- (void)_insertTabDocument:(TabDocument*)arg1 atIndex:(NSUInteger)arg2 inBackground:(BOOL)arg3 animated:(BOOL)arg4 updateUI:(BOOL)arg5;
- (BOOL)tabBar:(TabBar*)tabBar canCloseItem:(TabBarItem*)item;
- (BOOL)tabCollectionView:(id)collectionView canCloseItem:(id<TabCollectionItem>)item;
- (void)tabCollectionView:(id)collectionView didSelectItem:(id<TabCollectionItem>)item;
- (void)_insertTabDocument:(TabDocument*)arg1 afterTabDocument:(TabDocument*)arg2 inBackground:(BOOL)arg3 animated:(BOOL)arg4;	//iOS 8-10
- (void)insertTabDocument:(TabDocument*)arg1 afterTabDocument:(TabDocument*)arg2 inBackground:(BOOL)arg3 animated:(BOOL)arg4;	//iOS 11 and above
//new stuff below
@property (assign,nonatomic) BOOL desktopButtonSelected;
@property (nonatomic,retain) UIButton* tiltedTabViewDesktopModeButton;
@property (nonatomic,retain) UIBarButtonItem* tiltedTabViewTabManagerBarButton;
@property (nonatomic,retain) UINavigationController* presentedTabManager;
- (void)loadDesktopButtonState;
- (void)saveDesktopButtonState;
- (void)updateUserAgents;
- (void)toggleLockedStateForItem:(id<TabCollectionItem>)item;
- (void)toggleLockedStateForTabDocument:(TabDocument*)tabDocument;
- (void)tabManagerDidClose;
- (void)tiltedTabViewTabManagerButtonPressed;
@end

@interface TabDocument8 : NSObject
- (void)_loadURLInternal:(NSURL*)arg1 userDriven:(BOOL)arg2;
@end

@interface TabDocument : NSObject
@property (assign,nonatomic) BrowserController* browserController;
@property (nonatomic,readonly) _SFReloadOptionsController* reloadOptionsController;
@property (nonatomic,readonly) _SFTabStateData* tabStateData;
@property (nonatomic,readonly) SafariWebView* webView;
@property (nonatomic,copy) NSString* customUserAgent;
@property (nonatomic,readonly) FindOnPageView* findOnPageView;
@property (nonatomic,retain) _SFDownloadController* downloadController;
@property (nonatomic,readonly) TiltedTabItem* tiltedTabItem;
@property (nonatomic,readonly) TabOverviewItem* tabOverviewItem;
@property (readonly, nonatomic) TabBarItem *tabBarItem;
@property (assign,getter=isBlankDocument,nonatomic) BOOL blankDocument;
@property (copy, nonatomic) NSUUID *UUID;
@property (nonatomic) CGPoint scrollPoint;
@property (nonatomic,readonly) BOOL privateBrowsingEnabled;
+ (id)tabDocumentForWKWebView:(id)arg1;
- (id)initWithTitle:(NSString*)arg1 URL:(NSURL*)arg2 UUID:(NSUUID*)arg3 privateBrowsingEnabled:(BOOL)arg4 hibernated:(BOOL)arg5 bookmark:(id)arg6 browserController:(BrowserController*)arg7;
- (NSURL*)URL;
- (NSString*)title;
- (NSString*)titleForNewBookmark;
- (BOOL)isBlankDocument;
- (id)_loadURLInternal:(NSURL*)arg1 userDriven:(BOOL)arg2;
- (void)_loadStartedDuringSimulatedClickForURL:(id)arg1;
- (void)reload;
- (BOOL)privateBrowsingEnabled;
- (WebBookmark*)readingListBookmark;
- (void)_closeTabDocumentAnimated:(BOOL)arg1;
- (void)_animateElement:(id)arg1 toToolbarButton:(NSInteger)arg2;
- (void)_animateElement:(id)arg1 toBarItem:(NSInteger)arg2;
- (void)loadURL:(id)arg1 userDriven:(BOOL)arg2;
- (void)stopLoading;
- (void)webView:(WKWebView*)arg1 decidePolicyForNavigationResponse:(WKNavigationResponse*)arg2 decisionHandler:(void (^)(void))arg3;
- (void)_closeTabDocumentAnimated:(BOOL)arg1;
- (BOOL)isHibernated;
- (void)_openAppLinkInApp:(id)arg1 fromOriginalRequest:(id)arg2 updateAppLinkStrategy:(BOOL)arg3 webBrowserState:(id)arg4 completionHandler:(id)arg5;
- (void)userTappedReloadButton;
- (void)unhibernate;
- (_WKElementAction*)_openInNewPageActionForElement:(_WKActivatedElementInfo*)arg1;	//iOS 8
- (_WKElementAction*)_openInNewPageActionForElement:(_WKActivatedElementInfo*)arg1 previewViewController:(id)arg2;	//iOS 9 and above
- (void)requestDesktopSite;	//iOS 8
- (BOOL)isPrivateBrowsingEnabled;
- (BOOL)privateBrowsingEnabled;
//new stuff below
- (BOOL)handleAlwaysOpenInNewTabForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler;
- (BOOL)handleForceHTTPSForNavigationAction:(WKNavigationAction*)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler;
- (BOOL)handleDownloadAlertForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler;
- (void)addAdditionalActionsForElement:(_WKActivatedElementInfo*)element toActions:(NSMutableArray*)actions;
@property (nonatomic,assign) BOOL locked;
- (void)updateLockButtonStates;
@property (nonatomic,assign) BOOL accessAuthenticated;
@property (nonatomic, retain) SPTabManagerTableViewCell* tabManagerViewCell;
@property (nonatomic, retain) UIImage* currentTabIcon;
@end

//iOS 8
@interface TabDocumentWK2 : TabDocument
@end

@interface TabExposeActionsController : UIAlertController
@property (readonly, nonatomic) UIAlertController* alertController;
@property (readonly, nonatomic, weak) BrowserController* browserController;
- (void)updateActions;
- (void)_setActions:(NSUInteger)arg1;
@end

@interface TabOverview : UIView
@property (readonly, nonatomic) UIButton* addTabButton;
@property (nonatomic,readonly) UIButton* privateBrowsingButton;
@property (nonatomic, weak) TabController* delegate;
@property (copy, nonatomic) NSArray *items;
- (void)_updateDisplayedItems;
- (CGRect)_scrollBounds;
//new stuff below
@property (nonatomic, retain) UIButton* desktopModeButton;
@property (nonatomic,retain) UIButton* tabManagerButton;
- (void)userAgentButtonLandscapePressed;
@end

@interface TabOverviewItem : NSObject <TabCollectionItem>
@property (nonatomic, getter=_thumbnailView, setter=_setThumbnailView:) __weak TabThumbnailView *thumbnailView;	//iOS 9 and below
@property (nonatomic,retain) TabOverviewItemLayoutInfo* layoutInfo;
@property (nonatomic,weak) TabOverview* tabOverview;
@end

@interface TabOverviewItemLayoutInfo : NSObject
@property (readonly, nonatomic) __weak TabOverview* tabOverview;
@property (readonly, nonatomic) __weak TabOverviewItem* tabOverviewItem;
@property (nonatomic,retain) TabOverviewItemView* itemView;
@property (nonatomic) BOOL visibleInTabOverview;
@end

@interface TabThumbnailHeaderView : UIView
@end

@interface TabThumbnailView : UIView
@property (nonatomic,readonly) UIButton* closeButton;
@property (nonatomic) BOOL usesDarkTheme;
@property (copy, nonatomic) UIColor *titleColor;
@property (nonatomic, retain) _SFDimmingButton* lockButton;	//new
- (void)layoutSubviews;
@end

@interface TabOverviewItemView : TabThumbnailView
@end

@interface TiltedTabThumbnailView : TabThumbnailView
@end

@interface TiltedTabItem : NSObject <TabCollectionItem>
@property (readonly, nonatomic) TabThumbnailView *contentView;	//iOS 9 and below
@property (nonatomic,readonly) TiltedTabItemLayoutInfo* layoutInfo;
@property (nonatomic,weak) TiltedTabView* tiltedTabView;
@end

@interface TiltedTabItemLayoutInfo : NSObject
@property (readonly, nonatomic) TiltedTabView* tiltedTabView;
@property (nonatomic,retain) TiltedTabThumbnailView* contentView;
@property (readonly, nonatomic) __weak TiltedTabItem* item;
@end

@interface TiltedTabView : UIView
@property (nonatomic,weak) TabController* delegate;
@property (copy, nonatomic) NSArray* items;
- (CGRect)_visibleContentFrame;
- (TiltedTabItem*)_tiltedTabItemForLocation:(CGPoint)arg1;
- (void)_layoutItemsWithTransition:(NSInteger)arg1;
- (void)setPresented:(BOOL)arg1 animated:(BOOL)arg2;
- (void)setShowsExplanationView:(BOOL)arg1 animated:(BOOL)arg2;
- (void)setShowsPrivateBrowsingExplanationView:(BOOL)arg1 animated:(BOOL)arg2;	//iOS 11
- (void)dismissAnimated:(BOOL)arg1;
@end

@interface UnifiedField : UITextField
- (void)_setTopHit:(id)arg1;
- (void)_textDidChangeFromTyping;
- (void)setText:(id)arg1;
- (void)setInteractionTintColor:(UIColor*)interactionTintColor;
@end
