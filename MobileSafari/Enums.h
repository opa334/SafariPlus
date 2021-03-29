// Copyright (c) 2017-2021 Lars Fröder

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
	FileOperation_DirectoryContents_SPFile,
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
	FileOperation_ResolveSymlinks_URL,
	FileOperation_DirectorySize_URL
};

enum
{
    StockBarItemBack,
    StockBarItemForward,
    StockBarItemBookmarks,
    StockBarItemShare,
    StockBarItemAddTab,
	StockBarItemTabExpose,
    StockBarItemOpenInSafari,
    StockBarItemDownloads
};

enum
{
	BrowserToolbarBackItem,
	BrowserToolbarForwardItem,
	BrowserToolbarBookmarksItem,
	BrowserToolbarShareItem,
	BrowserToolbarAddTabItem,
	BrowserToolbarTabExposeItem,
	BrowserToolbarSearchBarSpace,
	BrowserToolbarDownloadsItem,
	BrowserToolbarReloadItem,
	BrowserToolbarClearDataItem,
	BrowserToolbarItemCount
};
