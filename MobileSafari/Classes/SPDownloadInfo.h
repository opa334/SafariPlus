// SPDownloadInfo.h
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

#import "../Protocols.h"

@class SPDownload, TabDocument;

@interface SPDownloadInfo : NSObject
@property (nonatomic) NSURLRequest* request;
@property (nonatomic) UIImage* image;
@property (nonatomic) int64_t filesize;
@property (nonatomic) NSString* filename;
@property (nonatomic) NSURL* targetURL;
@property (nonatomic) BOOL customPath;
@property (nonatomic) id<SourceVideoDelegate> sourceVideo;
@property (nonatomic) TabDocument* sourceDocument;
@property (nonatomic) UIViewController* presentationController;
@property (nonatomic) CGRect sourceRect;

- (SPDownloadInfo*)initWithRequest:(NSURLRequest*)request;
- (SPDownloadInfo*)initWithImage:(UIImage*)image;
- (SPDownloadInfo*)initWithDownload:(SPDownload*)download;

- (NSURL*)pathURL;
- (BOOL)fileExists;
- (void)removeExistingFile;
@end
