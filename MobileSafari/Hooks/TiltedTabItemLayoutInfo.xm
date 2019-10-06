// TiltedTabItemLayoutInfo.xm
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

#import "../SafariPlus.h"

#import "../Util.h"
#import "../Classes/SPPreferenceManager.h"
#import "../Defines.h"

%hook TiltedTabItemLayoutInfo

%group iOS10Up

- (void)tearDownThumbnailView
{
	if(self.contentView)
	{
		[self.contentView.lockButton removeTarget:self.tiltedTabView action:@selector(_lockButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	}

	%orig;
}

- (void)setUpThumbnailView
{
	%orig;

	if(preferenceManager.lockedTabsEnabled)
	{
		[self.contentView.lockButton addTarget:self.tiltedTabView action:@selector(_lockButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		self.contentView.lockButton.selected = [self.tiltedTabView.delegate _tabDocumentRepresentedByTiltedTabItem:self.item].locked;
	}
}

%end

%end

void initTiltedTabItemLayoutInfo()
{
	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0)
	{
		%init(iOS10Up);
	}
}
