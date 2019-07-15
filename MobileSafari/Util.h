// Util.h
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

#import <WebKit/WKWebView.h>
#import "Protocols.h"

@class BrowserController, BrowserRootViewController, BrowserToolbar, TabController, TabDocument, SPFileManager, SPCacheManager, SPDownload, SPDownloadInfo, SPDownloadManager, SPLocalizationManager, SPPreferenceManager, SPCommunicationManager, SafariWebView, NavigationBar, WebAVPlayerController;

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

extern BOOL privateBrowsingEnabled(BrowserController* controller);
extern void togglePrivateBrowsing(BrowserController* controller);
extern void setPrivateBrowsing(BrowserController* controller, BOOL enabled, void (^completion)(void));
extern NSArray<BrowserController*>* browserControllers();
extern NSArray<SafariWebView*>* activeWebViews();
extern BrowserController* browserControllerForTabDocument(TabDocument* document);
extern BrowserRootViewController* rootViewControllerForBrowserController(BrowserController* controller);
extern BrowserRootViewController* rootViewControllerForTabDocument(TabDocument* document);
extern NavigationBar* navigationBarForBrowserController(BrowserController* browserController);
extern BrowserToolbar* activeToolbarForBrowserController(BrowserController* browserController);
extern BrowserController* browserControllerForBrowserToolbar(BrowserToolbar* browserToolbar);
extern TabDocument* tabDocumentForItem(TabController* tabController, id<TabCollectionItem> item);
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
