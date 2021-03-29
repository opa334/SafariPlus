//Simplified version of https://github.com/PoomSmart/libSubstitrate/blob/master/libSubstitrate.mm

#import "substitrate.h"
#import "../pac.h"

int (*substitute_hook_functions)(const struct substitute_function_hook *hooks, size_t nhooks, struct substitute_function_hook_record **recordp, int options) = NULL;

static bool didSubstituteSearch = false;


static void readDylib()
{
	if (!didSubstituteSearch)
	{
		MSImageRef ref = MSGetImageByName("/usr/lib/libsubstitute.dylib");
		if(ref)
		{
			substitute_hook_functions = (int (*)(const struct substitute_function_hook *, size_t, struct substitute_function_hook_record **, int))make_sym_callable(MSFindSymbol(ref, "_substitute_hook_functions"));
		}
		didSubstituteSearch = true;
	}
}

int PSHookFunction(void *func, void *replace, void **result)
{
	if(func == 0)
	{
		return 1000;
	}
	
	readDylib();
	if(substitute_hook_functions)
	{
		struct substitute_function_hook hook = { func, replace, result };
		int ret = substitute_hook_functions(&hook, 1, NULL, 1);
		return ret;
	}
	else
	{
		MSHookFunction(func, replace, result);
	}
	return 0;
}

int PSHookFunction1(MSImageRef ref, const char *symbol, void *replace, void **result) {
	return PSHookFunction(MSFindSymbol(ref, symbol), replace, result);
}

int PSHookFunction2(MSImageRef ref, const char *symbol, void *replace) {
	return PSHookFunction1(ref, symbol, replace, NULL);
}

int PSHookFunction3(const char *image, const char *symbol, void *replace, void **result) {
	MSImageRef imageRef = MSGetImageByName(image);
	void* symbolPtr = MSFindSymbol(imageRef, symbol);
	return PSHookFunction(symbolPtr, replace, result);
}

int PSHookFunction4(const char *image, const char *symbol, void *replace) {
	return PSHookFunction3(image, symbol, replace, NULL);
}
