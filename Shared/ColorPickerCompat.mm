#include <dlfcn.h>
#import <CSColorPicker/CSColorPicker.h>

BOOL useAlderis(void)
{
#if defined(__arm64__) && __arm64__
    static BOOL alderis;
    static dispatch_once_t onceToken;
    dispatch_once (&onceToken, ^{
        alderis = [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Frameworks/Alderis.framework"];
    });
    return alderis;
#else
    return NO;
#endif
}

void loadColorPicker(void)
{
    if(useAlderis())
    {
#ifdef PREFERENCES
        dlopen("/usr/lib/libcolorpicker.dylib", RTLD_NOW);
#else
        NSBundle* alderisBundle = [NSBundle bundleWithPath:@"/Library/Frameworks/Alderis.framework"];
        [alderisBundle load];
#endif
    }
    else
    {
        dlopen("/usr/lib/libCSColorPicker.dylib", RTLD_NOW);
    }
}

#ifndef PREFERENCES

@import Alderis;

UIColor* colorFromHex(NSString* hex)
{
#ifdef NO_LIBCOLORPICKER
    return [UIColor redColor];
#else
    if(useAlderis())
    {
#if defined(__arm64__) && __arm64__
        return [[UIColor alloc] initWithHbcp_propertyListValue:hex];
#else
        return nil;
#endif
    }
    else
    {
        return [UIColor cscp_colorFromHexString:hex];
    }
#endif
}

#endif