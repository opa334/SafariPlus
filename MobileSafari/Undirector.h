extern void undirector_go();
extern void undirector_MSHookMessageEx(Class _class, SEL message, IMP hook, IMP *old);

#define UNDIRECTOR_CLASS_ADD_ID_GETTER(classname, propertyname) %hook classname %new -(id)propertyname { return [self valueForKey:[NSString stringWithFormat:@"_%s", #propertyname]]; } %end