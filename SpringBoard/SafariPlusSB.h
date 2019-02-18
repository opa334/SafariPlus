// SafariPlusSB.h
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

#ifndef SIMJECT
#import <RocketBootstrap/rocketbootstrap.h>
#endif
#import <AppSupport/CPDistributedMessagingCenter.h>

@class SSDownload, SSDownloadMetadata, SSDownloadQueue;

@interface JBBulletinManager : NSObject
+ (id)sharedInstance;
- (id)showBulletinWithTitle:(NSString *)title message:(NSString *)message bundleID:(NSString *)bundleID;
@end

@interface SBApplicationInfo : NSObject
@property (nonatomic,retain,readonly) NSURL* executableURL;
@property (nonatomic,retain,readonly) NSURL* bundleContainerURL;
@property (nonatomic,retain,readonly) NSURL* dataContainerURL;
@property (nonatomic,retain,readonly) NSURL* sandboxURL;
@property (nonatomic,copy,readonly) NSString* displayName;
@end

@interface SBApplication : NSObject
@property (nonatomic, readonly) SBApplicationInfo* info;//iOS 11 and above
- (SBApplicationInfo*)_appInfo;	//iOS 10 and below
@end

@interface SBApplicationController : NSObject
+ (instancetype)sharedInstance;
- (NSArray<SBApplication*>*)allApplications;
@end

@interface SSDownload : NSObject
@property (nonatomic,copy) SSDownloadMetadata* metadata;
- (instancetype)initWithDownloadMetadata:(SSDownloadMetadata*)downloadMetadata;
- (void)setDownloadHandler:(id)arg1 completionBlock:(/*^block*/ id)arg2;
@end

@interface SSDownloadMetadata : NSObject
@property (retain) NSString* kind;
@property (retain) NSURL* primaryAssetURL;
@property (copy) NSString* artistName;
@property (retain) NSURL* thumbnailImageURL;
@property (retain) NSString* title;
@property (copy) NSString* shortDescription;
@property (copy) NSString* longDescription;
@property (retain) NSString* genre;
@property (retain) NSDate* releaseDate;
@property (retain) NSNumber* releaseYear;
@property (retain) NSString* copyright;
- (void)setCollectionName:(NSString*)collectionName;
- (void)setDurationInMilliseconds:(NSNumber*)durationInMilliseconds;
- (void)setPurchaseDate:(NSDate*)purchaseDate;
- (void)setViewStoreItemURL:(NSURL*)itemURL;
@end

@interface SSDownloadQueue : NSObject
@property (readonly) NSSet* downloadKinds;
+ (NSSet*)mediaDownloadKinds;
- (instancetype)initWithDownloadKinds:(NSSet*)downloadKinds;
- (BOOL)addDownload:(SSDownload*)download;
@end
