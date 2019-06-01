// SPCacheManager.mm
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

#import "SPCacheManager.h"

#import "../Defines.h"
#import "../SafariPlus.h"
#import "../Util.h"

@implementation SPCacheManager

+ (instancetype)sharedInstance
{
	static SPCacheManager* sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^
	{
		//Initialise instance
		sharedInstance = [[SPCacheManager alloc] init];
	});

	return sharedInstance;
}

- (instancetype)init
{
	self = [super init];

	_cacheURL = [NSURL fileURLWithPath:SPCachePath];

	//Migrate old cache to new location
	NSURL* oldCacheURL = [NSURL fileURLWithPath:SPDeprecatedCachePath];

	if([oldCacheURL checkResourceIsReachableAndReturnError:nil])
	{
		[[NSFileManager defaultManager] moveItemAtURL:oldCacheURL toURL:_cacheURL error:nil];
	}

	if(![_cacheURL checkResourceIsReachableAndReturnError:nil])
	{
		NSError* error;
		[[NSFileManager defaultManager] createDirectoryAtURL:_cacheURL withIntermediateDirectories:NO attributes:nil error:&error];
	}

	[self updateExcludedFromBackup];

	[self loadMiscPlist];

	return self;
}

- (void)updateExcludedFromBackup
{
	//Set resource value NSURLIsExcludedFromBackupKey so that iOS does not automatically wipe our folder when it is running low on storage
	[_cacheURL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
}

- (void)loadMiscPlist
{
	NSURL* miscPlistURL = [_cacheURL URLByAppendingPathComponent:@"misc.plist"];

	//Get data
	NSData* miscData = [NSData dataWithContentsOfURL:miscPlistURL options:0 error:nil];

	if(miscData)
	{
		//Unarchive data
		_miscPlist = (NSMutableDictionary*)[NSKeyedUnarchiver unarchiveObjectWithData:miscData];
	}
	else
	{
		//Plist does not exists -> Initialise new dictionary
		_miscPlist = [NSMutableDictionary new];
	}
}

- (void)saveMiscPlist
{
	NSURL* miscPlistURL = [_cacheURL URLByAppendingPathComponent:@"misc.plist"];

	//Archive dictionary
	NSData* miscData = [NSKeyedArchiver archivedDataWithRootObject:_miscPlist];

	if(miscData)
	{
		//Save data
		[miscData writeToURL:miscPlistURL options:0 error:nil];
	}

	[self updateExcludedFromBackup];
}

//Check if Safari is started for the first time since Safari Plus was installed
- (BOOL)firstStart
{
	NSNumber* firstLaunchSucceeded = [_miscPlist objectForKey:@"firstLaunchSucceeded"];

	return ![firstLaunchSucceeded boolValue];
}

//Set value for the first start, so it will be NO on the next start
- (void)firstStartDidSucceed
{
	[_miscPlist setObject:@YES forKey:@"firstLaunchSucceeded"];

	[self saveMiscPlist];
}

//Return downloadStorageRevision of plist, used for clearing the cached downloads when the format of the file changes
- (NSInteger)downloadStorageRevision
{
	NSNumber* downloadStorageRevision = [_miscPlist objectForKey:@"downloadStorageRevision"];

	return [downloadStorageRevision intValue];
}

//Set downloadStorageRevision inside plist
- (void)setDownloadStorageRevision:(NSInteger)revision
{
	[_miscPlist setObject:[NSNumber numberWithInteger:revision] forKey:@"downloadStorageRevision"];

	[self saveMiscPlist];
}

- (NSDictionary*)loadDownloadCache
{
	NSURL* downloadCacheURL = [_cacheURL URLByAppendingPathComponent:@"downloads.plist"];

	//Get data from download storage file
	NSData *data = [NSData dataWithContentsOfURL:downloadCacheURL];

	//Return unarchived data if it exists
	return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

- (void)saveDownloadCache:(NSDictionary*)downloadCache
{
	@synchronized(self)
	{
		NSURL* downloadCacheURL = [_cacheURL URLByAppendingPathComponent:@"downloads.plist"];

		//Create archived data from pendingDownloads
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:downloadCache];

		//Write data to file
		[data writeToURL:downloadCacheURL atomically:YES];

		[self updateExcludedFromBackup];
	}
}

//Clear the download cache by removing the plist file
- (void)clearDownloadCache
{
	NSURL* downloadCacheURL = [_cacheURL URLByAppendingPathComponent:@"downloads.plist"];

	if([downloadCacheURL checkResourceIsReachableAndReturnError:nil])
	{
		[[NSFileManager defaultManager] removeItemAtURL:downloadCacheURL error:nil];
	}
}

//Load desktop button states from file
- (void)loadDesktopButtonStates
{
	NSURL* desktopStatesCacheURL = [_cacheURL URLByAppendingPathComponent:@"desktopButtonStates.plist"];

	//Get data
	NSData* data = [NSData dataWithContentsOfURL:desktopStatesCacheURL];

	//Unarchive data
	_desktopButtonStates = [NSKeyedUnarchiver unarchiveObjectWithData:data];

	if(!_desktopButtonStates)
	{
		_desktopButtonStates = [NSMutableDictionary new];
	}
}

//Save desktop button states to file
- (void)saveDesktopButtonStates
{
	NSURL* desktopStatesCacheURL = [_cacheURL URLByAppendingPathComponent:@"desktopButtonStates.plist"];

	//Get data from dictionary
	NSData* data = [NSKeyedArchiver archivedDataWithRootObject:_desktopButtonStates];

	//Save data to file
	[data writeToURL:desktopStatesCacheURL atomically:YES];

	[self updateExcludedFromBackup];
}

//Set desktop button state for browserController UUID
- (void)setDesktopButtonState:(BOOL)state forUUID:(NSUUID*)UUID
{
	if(UUID)
	{
		[_desktopButtonStates setObject:[NSNumber numberWithBool:state] forKey:UUID];
	}
	else
	{
		[_desktopButtonStates setObject:[NSNumber numberWithBool:state] forKey:@"Enabled"];
	}

	[self saveDesktopButtonStates];
}

//Get desktop button state for browserController UUID
- (BOOL)desktopButtonStateForUUID:(NSUUID*)UUID
{
	if(!_desktopButtonStates)
	{
		[self loadDesktopButtonStates];
	}


	if(UUID)
	{
		return [[_desktopButtonStates objectForKey:UUID] boolValue];
	}

	return [[_desktopButtonStates objectForKey:@"Enabled"] boolValue];
}

- (void)loadTabStateAdditions
{
	NSURL* tabStateAdditionsURL = [_cacheURL URLByAppendingPathComponent:@"tabStateAdditions.plist"];

	//Get data
	NSData* data = [NSData dataWithContentsOfURL:tabStateAdditionsURL];

	//Unarchive data
	_tabStateAdditions = [NSKeyedUnarchiver unarchiveObjectWithData:data];

	if(!_tabStateAdditions)
	{
		_tabStateAdditions = [NSMutableDictionary new];
	}
	else
	{
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
		{
			[self cleanUpTabStateAdditions];
		});
	}
}

- (void)saveTabStateAdditions
{
	NSURL* tabStateAdditionsURL = [_cacheURL URLByAppendingPathComponent:@"tabStateAdditions.plist"];

	//Get archived data from dictionary
	NSData* data = [NSKeyedArchiver archivedDataWithRootObject:_tabStateAdditions];

	//Save data to file
	[data writeToURL:tabStateAdditionsURL atomically:YES];

	[self updateExcludedFromBackup];
}

- (BOOL)isTabWithUUIDLocked:(NSUUID*)UUID
{
	if(!_tabStateAdditions)
	{
		[self loadTabStateAdditions];
	}

	NSMutableSet* lockedTabs = [_tabStateAdditions objectForKey:@"lockedTabs"];

	BOOL locked = [lockedTabs containsObject:UUID];

	return locked;
}

- (void)setLocked:(BOOL)locked forTabWithUUID:(NSUUID*)UUID
{
	NSMutableSet* lockedTabs = [_tabStateAdditions objectForKey:@"lockedTabs"];

	if(!lockedTabs)
	{
		lockedTabs = [NSMutableSet new];
		[_tabStateAdditions setObject:lockedTabs forKey:@"lockedTabs"];
	}

	if(locked)
	{
		[lockedTabs addObject:UUID];
	}
	else
	{
		[lockedTabs removeObject:UUID];
	}

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
	{
		[self saveTabStateAdditions];
	});
}

- (void)cleanUpTabStateAdditions
{
	if(!_tabStateAdditions)
	{
		[self loadTabStateAdditions];
	}

	NSMutableSet* lockedTabs = [[_tabStateAdditions objectForKey:@"lockedTabs"] mutableCopy];

	for(NSUUID* UUID in [lockedTabs copy])
	{
		if(![self tabExistsWithUUID:UUID])
		{
			[lockedTabs removeObject:UUID];
		}
	}

	[_tabStateAdditions setObject:lockedTabs forKey:@"lockedTabs"];
	[self saveTabStateAdditions];
}

- (BOOL)tabExistsWithUUID:(NSUUID*)UUID
{
	for(BrowserController* bc in browserControllers())
	{
		for(TabDocument* tb in [bc.tabController.allTabDocuments copy])
		{
			if([tb.UUID isEqual:UUID])
			{
				return YES;
			}
		}
	}

	return NO;
}

@end
