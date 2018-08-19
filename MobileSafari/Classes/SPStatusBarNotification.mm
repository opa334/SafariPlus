// SPStatusBarNotificationStyle.mm
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

#import "SPStatusBarNotification.h"

@implementation SPStatusBarNotification

+ (SPStatusBarNotification*)defaultStyleWithText:(NSString*)text
{
  SPStatusBarNotification* defaultNotification = [[SPStatusBarNotification alloc] init];
  defaultNotification.text = text;
  defaultNotification.backgroundColor = [UIColor whiteColor];
  defaultNotification.textColor = [UIColor blackColor];
  defaultNotification.dismissAfter = 2.0;
  return defaultNotification;
}

+ (SPStatusBarNotification*)downloadStyleWithText:(NSString*)text
{
  SPStatusBarNotification* downloadNotification = [[SPStatusBarNotification alloc] init];
  downloadNotification.text = text;
  downloadNotification.backgroundColor = [UIColor blueColor];
  downloadNotification.textColor = [UIColor whiteColor];
  downloadNotification.dismissAfter = 2.0;
  return downloadNotification;
}

@end
