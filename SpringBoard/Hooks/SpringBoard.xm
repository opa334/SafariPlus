// SpringBoard.xm
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

#import "../SafariPlusSB.h"

%hook SpringBoard

//Use rocketbootstrap to recieve messages through CPDistributedMessagingCenter
- (id)init
{
  id orig = %orig;

  CPDistributedMessagingCenter* SPMessagingCenter =
    [%c(CPDistributedMessagingCenter)
    centerNamed:@"com.opa334.SafariPlus.MessagingCenter"];

  rocketbootstrap_distributedmessagingcenter_apply(SPMessagingCenter);

	[SPMessagingCenter runServerOnCurrentThread];

  [SPMessagingCenter registerForMessageName:@"pushNotification" target:self
    selector:@selector(recieveMessageNamed:withData:)];

  return orig;
}

//Dispatch push notification (bulletin) through libbulletin
%new
- (NSDictionary *)recieveMessageNamed:(NSString *)name withData:(NSDictionary *)data
{
  [[objc_getClass("JBBulletinManager") sharedInstance]
    showBulletinWithTitle:[data objectForKey:@"title"]
    message:[data objectForKey:@"message"]
    bundleID:[data objectForKey:@"bundleID"]];

	return nil;
}

%end
