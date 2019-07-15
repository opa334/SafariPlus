#import "../Defines.h"
#import "../Util.h"
#import "../Classes/SPPreferenceManager.h"

%hook NavigationBarItem

- (void)setText:(id)arg1 textWhenExpanded:(id)arg2 startIndex:(NSUInteger)arg3
{
	if(preferenceManager.showFullSiteURLEnabled)
	{
		%orig(arg2, arg2, arg3);
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
