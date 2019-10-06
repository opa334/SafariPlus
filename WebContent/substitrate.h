//Simplified version of https://github.com/PoomSmart/libSubstitrate/blob/master/substitrate.h

struct substitute_function_hook {
    void *function;
    void *replacement;
    void *old_ptr;
    int options;
};
struct substitute_function_hook_record;

#import <dlfcn.h>
#import <substrate.h>

int PSHookFunction(void *func, void *replace, void **result) __asm__("PSHookFunction");
int PSHookFunction1(MSImageRef ref, const char *symbol, void *replace, void **result) __asm__("PSHookFunction1");
int PSHookFunction2(MSImageRef ref, const char *symbol, void *replace) __asm__("PSHookFunction2");
int PSHookFunction3(const char *image, const char *symbol, void *replace, void **result) __asm__("PSHookFunction3");
int PSHookFunction4(const char *image, const char *symbol, void *replace) __asm__("PSHookFunction4");

#define _PSHookFunction(ref, symbol, replace) PSHookFunction1(ref, symbol, (void *)replace, (void **)& _ ## replace)
#define _PSHookFunctionCompat(image, symbol, replace) PSHookFunction3(image, symbol, (void *)replace, (void **)& _ ## replace)
