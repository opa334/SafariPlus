// Copyright (c) 2017-2022 Lars Fröder

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

@class CPDistributedMessagingCenter, SSDownloadQueue;

@interface SPSBReceiver : NSObject
{
	CPDistributedMessagingCenter* _messagingCenter;
	NSDictionary* _displayNamesForPaths;
	SSDownloadQueue* _downloadQueue;
}

- (NSDictionary*)testConnection:(NSString*)name withUserInfo:(NSDictionary*)userInfo;
- (NSDictionary*)handleFileOperation:(NSString*)name withUserInfo:(NSDictionary*)serializedUserInfo;
//- (NSDictionary*)importToMusicLibrary:(NSString*)name withUserInfo:(NSDictionary*)serializedUserInfo;
- (NSDictionary*)getApplicationDisplayNames:(NSString*)name withUserInfo:(NSDictionary*)userInfo;

@end
