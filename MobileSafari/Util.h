// Copyright (c) 2017-2020 Lars Fröder

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import <WebKit/WKWebView.h>
#import "Protocols.h"

@class BrowserController, BrowserRootViewController, BrowserToolbar, TabController, TabDocument, TabThumbnailView, SPFileManager, SPCacheManager, SPDownload, SPDownloadInfo, SPDownloadManager, SPLocalizationManager, SPPreferenceManager, SPCommunicationManager, SafariWebView, NavigationBar, WebAVPlayerController;

extern BOOL showAlert;
extern SPFileManager* fileManager;
extern SPPreferenceManager* preferenceManager;
extern SPLocalizationManager* localizationManager;
extern SPDownloadManager* downloadManager;
extern SPCommunicationManager* communicationManager;
extern SPCacheManager* cacheManager;
extern NSBundle* SPBundle;
extern NSBundle* MSBundle;
extern BOOL rocketBootstrapWorks;
extern BOOL skipBiometricProtection;

extern BOOL privateBrowsingEnabled(BrowserController* controller);
extern void togglePrivateBrowsing(BrowserController* controller);
extern void setPrivateBrowsing(BrowserController* controller, BOOL enabled, void (^completion)(void));
extern NSArray<BrowserController*>* browserControllers();
extern NSArray<SafariWebView*>* activeWebViews();
extern BrowserController* browserControllerForTabDocument(TabDocument* document);
extern BrowserRootViewController* rootViewControllerForBrowserController(BrowserController* controller);
extern BrowserRootViewController* rootViewControllerForTabDocument(TabDocument* document);
extern NavigationBar* navigationBarForBrowserController(BrowserController* browserController);
extern BrowserToolbar* activeToolbarOrToolbarForBarItemForBrowserController(BrowserController* browserController, NSInteger barItem);
extern BrowserController* browserControllerForBrowserToolbar(BrowserToolbar* browserToolbar);
extern TabDocument* tabDocumentForItem(TabController* tabController, id<TabCollectionItem> item);
extern NSInteger safariPlusOrderItemForBarButtonItem(NSInteger barItem);
extern NSInteger barButtonItemForSafariPlusOrderItem(NSInteger orderItem);
extern TabDocument* tabDocumentForTabThumbnailView(TabThumbnailView* tabThumbnailView);
extern BOOL browserControllerIsShowingTabView(BrowserController* browserController);
extern BOOL updateTabExposeActionsForLockedTabs(BrowserController* browserController, UIAlertController* tabExposeAlertController);
extern void closeTabDocuments(TabController* tabController, NSArray<TabDocument*>* tabDocuments, BOOL animated);
extern void addToDict(NSMutableDictionary* dict, NSObject* object, id<NSCopying> key);
extern void requestAuthentication(NSString* reason, void (^successHandler)(void));
extern void sendSimpleAlert(NSString* title, NSString* message);
extern NSDictionary* decodeResumeData12(NSData* resumeData);
extern BOOL isUsingCellularData();
//extern NSURL* videoURLFromWebAVPlayerController(WebAVPlayerController* playerController);
extern void loadOtherPlist();
extern void saveOtherPlist();

#ifdef DEBUG_LOGGING

extern void initDebug();
extern void _dlog(NSString* fString, ...);
extern void _dlogDownload(SPDownload* download, NSString* message);
extern void _dlogDownloadInfo(SPDownloadInfo* downloadInfo, NSString* message);
extern void _dlogDownloadManager();

#define dlog(args ...) _dlog(args)
#define dlogDownload(args ...) _dlogDownload(args)
#define dlogDownloadInfo(args ...) _dlogDownloadInfo(args)
#define dlogDownloadManager() _dlogDownloadManager()

#else

#define dlog(args ...)
#define dlogDownload(args ...)
#define dlogDownloadInfo(args ...)
#define dlogDownloadManager()

#endif
/*
   @interface WKWebView (VideoURL)
   - (NSString*)getNowPlayingVideoURL;
   @end
 */
