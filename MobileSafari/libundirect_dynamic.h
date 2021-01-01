//Used so libundirect doesn't have to installed on iOS below 14

extern void (*libundirect_MSHookMessageEx)(Class _class, SEL message, IMP hook, IMP *old);
extern void (*libundirect_rebind)(void* directPtr, Class _class, SEL selector, const char* format);
extern void* (*libundirect_find)(NSString* imageName, unsigned char* bytesToSearch, size_t byteCount, unsigned char startByte);
extern NSArray* (*libundirect_failedSelectors)();
#define LIBUNDIRECT_CLASS_ADD_GETTER(classname, type, ivarname, gettername) %hook classname %new - (type)gettername { return [self valueForKey:[NSString stringWithUTF8String:#ivarname]]; } %end
#define LIBUNDIRECT_CLASS_ADD_SETTER(classname, type, ivarname, settername) %hook classname %new - (void)settername:(type)toset { [self setValue:toset forKey:[NSString stringWithUTF8String:#ivarname]]; } %end