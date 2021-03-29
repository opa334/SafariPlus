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

@interface UITableViewHeaderFooterView (Private)
- (void)_updateLabelBackgroundColor;
@end

@interface UITableView (Private)
- (void)_setupSectionView:(id)arg1 isHeader:(BOOL)arg2 forSection:(NSInteger)arg3;
@end

@implementation UITableViewController (Fixes)

//Update all header titles (Needed to prevent layout issues in some cases)
- (void)updateSectionHeaders
{
	NSInteger sections = [self numberOfSectionsInTableView:self.tableView];

	[UIView setAnimationsEnabled:NO];
	[self.tableView beginUpdates];

	for(NSInteger i = 0; i < sections; i++)
	{
		UITableViewHeaderFooterView* headerView = [self.tableView headerViewForSection:i];
		headerView.textLabel.text = [self tableView:self.tableView titleForHeaderInSection:i];
	}

	[self.tableView endUpdates];
	[UIView setAnimationsEnabled:YES];
}

- (void)fixHeaderColors
{
	for(NSInteger i = 0; i < [self numberOfSectionsInTableView:self.tableView]; i++)
	{
		UITableViewHeaderFooterView* headerView = [self.tableView headerViewForSection:i];
		if([self.tableView.backgroundColor isEqual:headerView.backgroundView.backgroundColor])
		{
			headerView.backgroundView.backgroundColor = nil;
			[self.tableView _setupSectionView:headerView isHeader:YES forSection:i];
		}
	}
}
@end

@implementation UIImage (SizeChange)
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

- (UIImage*)scaledImageWithHeight:(CGFloat)newHeight
{
	CGFloat aspectRatio = self.size.width / self.size.height;
	CGFloat newWidth = newHeight * aspectRatio;

	UIGraphicsBeginImageContextWithOptions(CGSizeMake(newWidth, newHeight), NO, 0.0);
	[self drawInRect:CGRectMake(0,0,newWidth,newHeight)];
	UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
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
	CGContextDrawImage(bitmap, CGRectMake(-self.size.width / 2, -self.size.height / 2, self.size.width, self.size.height), self.CGImage);

	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	return newImage;
}
@end

@implementation UIAlertController (TextView)
- (void)setTextView:(UITextView*)textView
{
	textView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	UIViewController* contentController = [[UIViewController alloc] init];
	textView.frame = contentController.view.frame;
	[contentController.view addSubview:textView];

	[self setValue:contentController forKey:@"contentViewController"];

	NSLayoutConstraint* heightConstraint = [NSLayoutConstraint constraintWithItem:textView
						attribute:NSLayoutAttributeHeight
						relatedBy:NSLayoutRelationEqual
						toItem:nil
						attribute:NSLayoutAttributeNotAnAttribute
						multiplier:1
						constant:90];

	[textView addConstraint:heightConstraint];
}
@end
