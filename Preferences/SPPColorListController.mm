#import "SPPColorListController.h"

@implementation SPPColorListController

- (void)applyModificationsToSpecifiers:(NSMutableArray*)specifiers
{
	NSString* modeIdentifier = [[self specifier] propertyForKey:@"modeIdentifier"];

	for(PSSpecifier* specifier in specifiers)
	{
		NSString* key = [specifier propertyForKey:@"key"];
		key = [key stringByReplacingOccurrencesOfString:@"@MODE_IDENTIFIER@" withString:modeIdentifier];
		[specifier setProperty:key forKey:@"key"];
	}

	[super applyModificationsToSpecifiers:specifiers];
}

@end