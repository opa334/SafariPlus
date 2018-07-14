@protocol PinnedLocationsDelegate
@required
- (void)directoryPickerFinishedWithName:(NSString*)name path:(NSString*)path;
@end
