// Shared.h
// (c) 2017 opa334

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

@class BrowserController, BrowserRootViewController, TabDocument, SPDownloadManager, SPLocalizationManager, SPPreferenceManager, SafariWebView;

extern BOOL showAlert;
extern BOOL iPhoneX;
extern NSString* defaultDownloadPath;
extern CGFloat iOSVersion;
extern SPPreferenceManager* preferenceManager;
extern SPLocalizationManager* localizationManager;
extern SPDownloadManager* downloadManager;
extern NSBundle* SPBundle;
extern NSBundle* MSBundle;

extern BOOL privateBrowsingEnabled(BrowserController* controller);
extern void togglePrivateBrowsing(BrowserController* controller);
extern NSArray<BrowserController*>* browserControllers();
extern NSArray<SafariWebView*>* activeWebViews();
extern BrowserController* browserControllerForTabDocument(TabDocument* document);
extern BrowserRootViewController* rootViewControllerForBrowserController(BrowserController* controller);
extern BrowserRootViewController* rootViewControllerForTabDocument(TabDocument* document);
extern void loadOtherPlist();
extern void saveOtherPlist();

@interface UIImage (ColorInverse)
+ (UIImage *)inverseColor:(UIImage *)image;
@end

@interface NSURL (HTTPtoHTTPS)
- (NSURL*)httpsURL;
@end

@interface NSString (Strip)
- (NSString*)stringStrippedByStrings:(NSArray<NSString*>*)strings;
@end
