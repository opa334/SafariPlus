//Simplified version of https://github.com/PoomSmart/libSubstitrate/blob/master/substitrate.h

struct substitute_function_hook {
    void *function;
    void *replacement;
    void *old_ptr;
    int options;
};
struct substitute_function_hook_record;

enum LIBHOOKER_ERR {
    LIBHOOKER_OK = 0,
    LIBHOOKER_ERR_SELECTOR_NOT_FOUND = 1,
    LIBHOOKER_ERR_SHORT_FUNC = 2,
    LIBHOOKER_ERR_BAD_INSN_AT_START = 3,
    LIBHOOKER_ERR_VM = 4,
    LIBHOOKER_ERR_NO_SYMBOL = 5
};

enum LHOptions {
    LHOptionsNone = 0,
    LHOptionsSetJumpReg = 1
};

struct LHFunctionHook {
    void *function;
    void *replacement;
    void *oldptr;
    enum LHOptions options;
    int jmp_reg;
};

#import <dlfcn.h>
#import <substrate.h>

int PSHookFunction(void *func, void *replace, void **result) __asm__("PSHookFunction");
int PSHookFunction1(MSImageRef ref, const char *symbol, void *replace, void **result) __asm__("PSHookFunction1");
int PSHookFunction2(MSImageRef ref, const char *symbol, void *replace) __asm__("PSHookFunction2");
int PSHookFunction3(const char *image, const char *symbol, void *replace, void **result) __asm__("PSHookFunction3");
int PSHookFunction4(const char *image, const char *symbol, void *replace) __asm__("PSHookFunction4");

#define _PSHookFunction(ref, symbol, replace) PSHookFunction1(ref, symbol, (void *)replace, (void **)& _ ## replace)
#define _PSHookFunctionCompat(image, symbol, replace) PSHookFunction3(image, symbol, (void *)replace, (void **)& _ ## replace)
