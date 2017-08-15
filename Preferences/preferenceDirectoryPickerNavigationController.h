//  directoryPickerNavigationController.h
// (c) 2017 opa334

#import "preferenceDirectoryPickerTableViewController.h"
#import "preferenceFileBrowserNavigationController.h"

@protocol PinnedLocationsDelegate
@required
- (void)directoryPickerFinishedWithName:(NSString*)name path:(NSURL*)pathURL;
@end

@interface preferenceDirectoryPickerNavigationController : preferenceFileBrowserNavigationController {}
@property(nonatomic, weak) id<PinnedLocationsDelegate> pinnedLocationsDelegate;
@property(nonatomic) NSString* name;
- (id)initWithDelegate:(id<PinnedLocationsDelegate>)delegate name:(NSString*) name;
@end
