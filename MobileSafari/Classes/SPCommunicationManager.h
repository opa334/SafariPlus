// SPCommunicationManager.h
// (c) 2019 opa334

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

@class CPDistributedMessagingCenter, SPMusicImport;

@interface SPCommunicationManager : NSObject
{
	CPDistributedMessagingCenter* _messagingCenter;
}

+ (instancetype)sharedInstance;
- (BOOL)testConnection;
- (void)dispatchPushNotificationWithIdentifier:(NSString*)bundleIdentifier title:(NSString*)title message:(NSString*)message;
- (NSDictionary*)executeFileOperationOnSpringBoard:(NSDictionary*)operation;
- (NSDictionary*)applicationDisplayNamesForPaths;

@end
