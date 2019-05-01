// Extensions.mm
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

#import "Extensions.h"

//https://stackoverflow.com/a/22669888
@implementation UIImage (ColorInverse)
+ (UIImage *)inverseColor:(UIImage *)image
{
	CIImage *coreImage = [CIImage imageWithCGImage:image.CGImage];
	CIFilter *filter = [CIFilter filterWithName:@"CIColorInvert"];
	[filter setValue:coreImage forKey:kCIInputImageKey];
	CIImage *result = [filter valueForKey:kCIOutputImageKey];
	return [UIImage imageWithCIImage:result scale:image.scale orientation:image.imageOrientation];
}
@end

@implementation NSURL (SchemeConversion)
//Convert http url to https url
- (NSURL*)httpsURL
{
	//Get URL components
	NSURLComponents* URLComponents = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];

	if([self.scheme isEqualToString:@"http"])
	{
		//Change scheme to https
		URLComponents.scheme = @"https";
	}

	return URLComponents.URL;
}

//Convert https url to http url
- (NSURL*)httpURL
{
	//Get URL components
	NSURLComponents* URLComponents = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO];

	if([self.scheme isEqualToString:@"https"])
	{
		//Change scheme to http
		URLComponents.scheme = @"http";
	}

	return URLComponents.URL;
}
@end

@implementation NSString (Strip)
- (NSString*)stringStrippedByStrings:(NSArray<NSString*>*)strings
{
	NSString* strippedString = self;
	NSArray* tmpArray;

	for(NSString* string in strings)
	{
		tmpArray = [strippedString componentsSeparatedByString:string];
		strippedString = tmpArray.firstObject;
	}

	return strippedString;
}
@end

@implementation NSString (UUID)
- (BOOL)isUUID
{
	return (bool)[[NSUUID alloc] initWithUUIDString:self];
}
@end

@implementation UIView (Autolayout)
+ (id)autolayoutView
{
	UIView *view = [self new];
	view.translatesAutoresizingMaskIntoConstraints = NO;
	return view;
}
@end

@implementation UITableViewController (FooterFix)
- (void)fixFooterColors
{
	for(int i = 0; i < [self numberOfSectionsInTableView:self.tableView]; i++)
	{
		UITableViewHeaderFooterView* footerView = [self.tableView headerViewForSection:i];
		footerView.backgroundView.backgroundColor = [UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:1];
	}
}
@end

@implementation UIImage (WidthChange)
//Roughly based around https://stackoverflow.com/questions/20021478/add-transparent-space-around-a-uiimage
//alignment -1: left; 0: center; 1: right;
- (UIImage*)imageWithWidth:(CGFloat)width alignment:(NSInteger)alignment
{
	if(width <= self.size.width)
	{
		return self;
	}

	UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, self.size.height), NO, 0.0);
	CGContextRef context = UIGraphicsGetCurrentContext();
	UIGraphicsPushContext(context);

	CGFloat x;

	if(alignment < 0)
	{
		x = 0;
	}
	else if(alignment == 0)
	{
		x = (width - self.size.width) / 2;
	}
	else
	{
		x = width - self.size.width;
	}

	CGPoint origin = CGPointMake(x, 0);
	[self drawAtPoint:origin];

	UIGraphicsPopContext();
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	if([self respondsToSelector:@selector(flipsForRightToLeftLayoutDirection)])
	{
		if(self.flipsForRightToLeftLayoutDirection)
		{
			newImage = [newImage imageFlippedForRightToLeftLayoutDirection];
		}
	}

	return newImage;
}
@end

@implementation UIImage (Rotate)
- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees
{
	CGFloat radians = degrees * M_PI/180;

	UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0, self.size.width, self.size.height)];
	CGAffineTransform t = CGAffineTransformMakeRotation(radians);
	rotatedViewBox.transform = t;
	CGSize rotatedSize = rotatedViewBox.frame.size;

	UIGraphicsBeginImageContextWithOptions(rotatedSize, NO, [[UIScreen mainScreen] scale]);
	CGContextRef bitmap = UIGraphicsGetCurrentContext();

	CGContextTranslateCTM(bitmap, rotatedSize.width / 2, rotatedSize.height / 2);

	CGContextRotateCTM(bitmap, radians);

	CGContextScaleCTM(bitmap, 1.0, -1.0);
	CGContextDrawImage(bitmap, CGRectMake(-self.size.width / 2, -self.size.height / 2, self.size.width, self.size.height), self.CGImage );

	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	return newImage;
}
@end
