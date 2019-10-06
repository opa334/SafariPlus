
#import "../SafariPlus.h"
#import <dlfcn.h>
#import "substrate.h"

///System/Library/PrivateFrameworks/WebCore.framework/WebCore

/*

   @interface WKContentView : UIView
   @end

   extern "C"
   {
   namespace WTF
   {
   class String
   {
   public:
   extern CFStringRef createCFString(void);
   };
   }
   }

   class WebFrameProxy
   {
   public:
   WTF::String m_url;
   };

   class WebPageProxy
   {
   public:
   WebFrameProxy* m_mainFrame;
   };



   @implementation WKWebView (VideoURL)

   - (NSString*)getNowPlayingVideoURL
   {
   NSValue* contentViewPtr = [self valueForKey:@"_contentView"];

   id contentView = contentViewPtr.nonretainedObjectValue;

   NSLog(@"contentView:%@", contentView);

   NSValue* webPagePtr = [contentView valueForKey:@"_page"];
   WebPageProxy* page = (WebPageProxy*)[webPagePtr pointerValue];

   NSLog(@"page:%p", page);

   WebFrameProxy* mainFrame = page->m_mainFrame;

   NSLog(@"mainFramePtr:%p", mainFrame);

   WTF::String url = mainFrame->m_url;

   NSLog(@"url:%p", &url);

   //void *handle = dlsym(0, RTLD_LOCAL | RTLD_LAZY);
   //CFStringRef (*createCFString)(String*) = (CFStringRef (*)(String*))dlsym(RTLD_DEFAULT, "_ZNK3WTF6String14createCFStringEv");

   //NSLog(@"createCFString = %p", createCFString);

   //NSLog(@"asciiMethod = %p", asciiMethod);

   //char* asciiString = asciiMethod(&mainFrame->m_url);
   //char* asciiString = url.ascii();
   //char* asciiString = asciiMethod(&url);

   CFStringRef urlString = url.createCFString();

   NSString* URL = (__bridge NSString*)urlString;

   NSLog(@"mainFrame URL:%@", URL);

   return nil;
   }

   @end
 */

//void HTMLMediaElement::loadResource(const URL& initialURL, ContentType& contentType, const String& keySystem)
//_ZN7WebCore16HTMLMediaElement12loadResourceERKNS_3URLERNS_11ContentTypeERKN3WTF6StringE

namespace WTF
{
class URL
{

};

class ContentType
{

};

class String
{

};
};

void (*orig_loadResource)(void*, WTF::URL, WTF::ContentType, const WTF::String& keySystem);
void new_loadResource(void* self, WTF::URL initialURL, WTF::ContentType contentType, const WTF::String& keySystem)
{
	NSLog(@"GANG UP ON YOUR VIDEO URL!");
	return orig_loadResource(self, initialURL, contentType, keySystem);
}

/*%ctor
   {
     void* symbol = (void *)MSFindSymbol(NULL, "_ZN7WebCore16HTMLMediaElement12loadResourceERKNS_3URLERNS_11ContentTypeERKN3WTF6StringE");
     NSLog(@"symbol = %p", symbol);
     MSHookFunction(symbol, (void*)new_loadResource, (void**)&orig_loadResource);
   }*/

/*void (*orig_didBecomeFullscreenElement)(void*);
   void new_didBecomeFullscreenElement(void* self)
   {
        NSLog(@"GANG UP ON YOUR VIDEO URL!");
        return orig_didBecomeFullscreenElement(self);
   }*/

%ctor
{
	dlopen("/System/Library/PrivateFrameworks/WebCore.framework/WebCore", RTLD_NOW);

	MSImageRef webCoreImage = MSGetImageByName("/System/Library/PrivateFrameworks/WebCore.framework/WebCore");

	NSLog(@"webCoreImage = %p", webCoreImage);

	void* symbol = (void *)MSFindSymbol(webCoreImage, "__ZN7WebCore16HTMLMediaElement12loadResourceERKNS_3URLERNS_11ContentTypeERKN3WTF6StringE");
	NSLog(@"symbol = %p", symbol);
	MSHookFunction(symbol, (void*)new_loadResource, (void**)&orig_loadResource);

	/*void* symbol = (void *)MSFindSymbol(webCoreImage, "__ZN7WebCore16HTMLMediaElement26didBecomeFullscreenElementEv");
	   NSLog(@"symbol = %p", symbol);
	   MSHookFunction(symbol, (void*)new_didBecomeFullscreenElement, (void**)&orig_didBecomeFullscreenElement);*/
}
