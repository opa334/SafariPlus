// Enums.h
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


//Enum for long pressed element type
enum
{
	ElementInfoURL = 0,
	ElementInfoImage = 1,
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

//Enum for file operations (When communicating with SpringBoard)
enum
{
	FileOperation_DirectoryContents,
	FileOperation_DirectoryContents_URL,
	FileOperation_CreateDirectory,
	FileOperation_CreateDirectory_URL,
	FileOperation_MoveItem,
	FileOperation_MoveItem_URL,
	FileOperation_RemoveItem,
	FileOperation_RemoveItem_URL,
	FileOperation_CopyItem,
	FileOperation_CopyItem_URL,
	FileOperation_LinkItem,
	FileOperation_LinkItem_URL,
	FileOperation_FileExists,
	FileOperation_FileExists_URL,
	FileOperation_FileExists_IsDirectory,
	FileOperation_IsDirectory_URL,
	FileOperation_Attributes,
	FileOperation_ResourceValue_URL,
	FileOperation_IsWritable,
	FileOperation_ResolveSymlinks,
	FileOperation_ResolveSymlinks_URL
};
