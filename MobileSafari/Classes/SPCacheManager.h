// SPCacheManager.h
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

@interface SPCacheManager : NSObject
{
	NSURL* _cacheURL;
	NSMutableDictionary* _miscPlist;
	NSMutableDictionary* _desktopButtonStates;
	NSMutableDictionary* _tabStateAdditions;
}

+ (instancetype)sharedInstance;

- (void)updateExcludedFromBackup;

- (void)loadMiscPlist;
- (void)saveMiscPlist;
- (BOOL)firstStart;
- (void)firstStartDidSucceed;

- (NSInteger)downloadStorageRevision;
- (void)setDownloadStorageRevision:(NSInteger)revision;
- (NSDictionary*)loadDownloadCache;
- (void)saveDownloadCache:(NSDictionary*)downloadCache;
- (void)clearDownloadCache;

- (void)loadDesktopButtonStates;
- (void)saveDesktopButtonStates;
- (void)setDesktopButtonState:(BOOL)state forUUID:(NSUUID*)UUID;
- (BOOL)desktopButtonStateForUUID:(NSUUID*)UUID;

- (void)loadTabStateAdditions;
- (void)saveTabStateAdditions;
- (BOOL)isTabWithUUIDLocked:(NSUUID*)UUID;
- (void)setLocked:(BOOL)locked forTabWithUUID:(NSUUID*)UUID;

@end
