// Enums.h
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


//Enum for long pressed element type
enum
{
  ElementInfoURL_iOS10AndUp = 0,
  ElementInfoImage_iOS10AndUp = 1,
  ElementInfoURL_iOS9AndBelow = 120259084288,
  ElementInfoImage_iOS9AndBelow = 120259084289
};

//Enum for mode switch actions
enum
{
  ModeSwitchActionNormalMode = 1,
  ModeSwitchActionPrivateMode = 2
};

//Enum for close tab action conditions
enum
{
  CloseTabActionOnSafariClosed = 1,
  CloseTabActionOnSafariMinimized = 2
};

//Enum for close tab action modes
enum
{
  CloseTabActionFromActiveMode = 1,
  CloseTabActionFromNormalMode = 2,
  CloseTabActionFromPrivateMode = 3,
  CloseTabActionFromBothModes = 4
};

//Enum for gesture actions
enum
{
  GestureActionCloseActiveTab = 1,
  GestureActionOpenNewTab = 2,
  GestureActionDuplicateActiveTab = 3,
  GestureActionCloseAllTabs = 4,
  GestureActionSwitchMode = 5,
  GestureActionSwitchTabBackwards = 6,
  GestureActionSwitchTabForwards = 7,
  GestureActionReloadActiveTab = 8,
  GestureActionRequestDesktopSite = 9,
  GestureActionOpenFindOnPage = 10
};
