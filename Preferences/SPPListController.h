// Copyright (c) 2017-2022 Lars Fröder

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

#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

// Additional features:
// Localizes specifiers
// nestedEntryCount for more dynamic preferences
// version specific specifiers
// method to open twitter account

@interface SPPListController : PSListController
{
	NSArray* _allSpecifiers;
	UITapGestureRecognizer* _tapGestureRecognizer;
}

- (NSString*)plistName;
- (NSString*)title;
- (void)applyModificationsToSpecifiers:(NSMutableArray*)specifiers;
- (void)removeUnsupportedSpecifiers:(NSMutableArray*)specifiers;
- (void)removeDisabledGroups:(NSMutableArray*)specifiers;
- (void)openTwitterWithUsername:(NSString*)username;
- (void)closeKeyboard;
- (BOOL)shouldDismissKeyboardOnTap;
- (BOOL)shouldAddTapGesture;
- (void)tapGestureReceivedTap:(UITapGestureRecognizer*)sender;
@end
