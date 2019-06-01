// Extensions.h
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

@interface UIImage (ColorInverse)
+ (UIImage *)inverseColor:(UIImage *)image;
@end

@interface NSURL (SchemeConversion)
- (NSURL*)httpsURL;
- (NSURL*)httpURL;
@end

@interface NSString (Strip)
- (NSString*)stringStrippedByStrings:(NSArray<NSString*>*)strings;
@end

@interface NSString (UUID)
- (BOOL)isUUID;
@end

@interface UIView (Autolayout)
+ (id)autolayoutView;
@end

@interface UITableViewController (Fixes)
- (void)updateSectionHeaders;
- (void)fixFooterColors;
@end

@interface UIImage (WidthChange)
- (UIImage*)imageWithWidth:(CGFloat)width alignment:(NSInteger)alignment;
@end

@interface UIImage (Rotate)
- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees;
@end

@interface UIAlertController (TextView)
- (void)setTextView:(UITextView*)textView;
@end
