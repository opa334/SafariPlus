// SPCacheManager.m
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

#import "SPCacheManager.h"

#import "../Defines.h"

@implementation SPCacheManager

+ (instancetype)sharedInstance
{
    static SPCacheManager* sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,
    ^{
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
		[[NSFileManager defaultManager] createDirectoryAtURL:_cacheURL withIntermediateDirectories:NO attributes:nil error:nil];
	}

	[self updateExcludedFromBackup];

	return self;
}

- (void)updateExcludedFromBackup
{
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

- (BOOL)firstStart
{
	[self loadMiscPlist];

	NSNumber* firstLaunchSucceeded = [_miscPlist objectForKey:@"firstLaunchSucceeded"];

	return ![firstLaunchSucceeded boolValue];
}

- (void)firstStartDidSucceed
{
	[_miscPlist setObject:@YES forKey:@"firstLaunchSucceeded"];

	[self saveMiscPlist];
}

- (NSMutableArray*)loadCachedDownloads
{
	NSURL* downloadCacheURL = [_cacheURL URLByAppendingPathComponent:@"downloads.plist"];

	//Get data from download storage file
  NSData *data = [NSData dataWithContentsOfURL:downloadCacheURL];

	if(data)
	{
		//Return unarchived data if it exists
	  return [NSKeyedUnarchiver unarchiveObjectWithData:data];
	}

	return [NSMutableArray new];
}

- (void)saveCachedDownloads:(NSMutableArray*)cachedDownloads
{
	NSURL* downloadCacheURL = [_cacheURL URLByAppendingPathComponent:@"downloads.plist"];

	//Create data from pendingDownloads
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:cachedDownloads];

  //Write data to file
  [data writeToURL:downloadCacheURL atomically:YES];

	[self updateExcludedFromBackup];
}

- (void)clearDownloadCache
{
	NSURL* downloadCacheURL = [_cacheURL URLByAppendingPathComponent:@"downloads.plist"];

	if([downloadCacheURL checkResourceIsReachableAndReturnError:nil])
	{
		[[NSFileManager defaultManager] removeItemAtURL:downloadCacheURL error:nil];
	}
}

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

- (void)saveDesktopButtonStates
{
	NSURL* desktopStatesCacheURL = [_cacheURL URLByAppendingPathComponent:@"desktopButtonStates.plist"];

	//Get data from dictionary
	NSData* data = [NSKeyedArchiver archivedDataWithRootObject:_desktopButtonStates];

	//Save data to file
  [data writeToURL:desktopStatesCacheURL atomically:YES];

	[self updateExcludedFromBackup];
}

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

- (BOOL)desktopButtonStateForUUID:(NSUUID*)UUID
{
	[self loadDesktopButtonStates];

	if(UUID)
	{
		return [[_desktopButtonStates objectForKey:UUID] boolValue];
	}

	return [[_desktopButtonStates objectForKey:@"Enabled"] boolValue];
}

@end
