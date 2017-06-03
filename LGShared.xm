//  LockGlyphXPrefs.mm
//  Settings for LockGlyphX
//
//  (c)2017 evilgoldfish
//
//  feat. @sticktron
//
//	(Credits: https://github.com/evilgoldfish/LockGlyphX/blob/master/Prefs/LockGlyphXPrefs.mm)

#import "LGShared.h"

@implementation LGShared
+ (NSString *)localisedStringForKey:(NSString *)key {
	NSString *englishString = [[NSBundle bundleWithPath:[NSString stringWithFormat:@"%@/en.lproj", localizationBundlePath]] localizedStringForKey:key value:@"" table:nil];
	return [[NSBundle bundleWithPath:localizationBundlePath] localizedStringForKey:key value:englishString table:nil];
}
+ (void)parseSpecifiers:(NSArray *)specifiers{
    for (PSSpecifier *specifier in specifiers) {
        NSString *localisedTitle = [LGShared localisedStringForKey:specifier.properties[@"label"]];
        NSString *localisedFooter = [LGShared localisedStringForKey:specifier.properties[@"footerText"]];
        [specifier setProperty:localisedFooter forKey:@"footerText"];
        specifier.name = localisedTitle;
    }
}
@end

/*

License:

MIT License

Copyright (c) 2017 Evan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

(Source: https://github.com/evilgoldfish/LockGlyphX/blob/master/LICENSE)

*/
