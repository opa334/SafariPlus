// SPFile.h
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

@interface SPFile : NSObject

@property (nonatomic, readonly) NSURL* fileURL;
@property (nonatomic, readonly) NSString* name;
@property (nonatomic, readonly) NSString* applicationDisplayName;
@property (nonatomic, readonly) NSAttributedString* cellTitle;
@property (nonatomic, readonly) BOOL isRegularFile;
@property (nonatomic, readonly) int64_t size;
@property (nonatomic, readonly) BOOL isHidden;
@property (nonatomic, readonly) BOOL isWritable;
@property (nonatomic, readonly) CFStringRef fileUTI;

- (instancetype)initWithFileURL:(NSURL*)fileURL;

- (BOOL)conformsTo:(CFStringRef)UTI;

@end
