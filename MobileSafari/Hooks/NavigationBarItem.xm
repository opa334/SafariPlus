#import "../Defines.h"
#import "../Util.h"
#import "../Classes/SPPreferenceManager.h"

%hook NavigationBarItem

- (void)setText:(NSString*)text textWhenExpanded:(NSString*)textWhenExpanded startIndex:(NSUInteger)startIndex
{
	if(preferenceManager.showFullSiteURLEnabled)
	{
		%orig(textWhenExpanded, textWhenExpanded, startIndex);
	}
	else
	{
		%orig;
	}
}

%end

void initNavigationBarItem()
{
	Class navigationBarItemClass = NSClassFromString(@"NavigationBarItem");

	if(!navigationBarItemClass)
	{
		navigationBarItemClass = NSClassFromString(@"_SFNavigationBarItem");
	}

	%init(NavigationBarItem=navigationBarItemClass);
}
