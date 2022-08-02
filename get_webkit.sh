#!/bin/sh

#download and extract webkit
curl -L -o WebKit.zip https://s3-us-west-2.amazonaws.com/minified-archives.webkit.org/ios-simulator-14-x86_64-release/274758.zip
mkdir tmp
unzip WebKit.zip -d ./tmp
mv ./tmp/Release-iphonesimulator .WebKit
rm -rf tmp
rm WebKit.zip

# additional patches

# fix compilation
rm -rf .WebKit/WebKit.framework
rm -rf .WebKit/WebKitLegacy.framework

# fix video downloading runtime crashes
sed -i '' -e 's|ALWAYS_INLINE ~RefPtr() { RefDerefTraits::derefIfNotNull(PtrTraits::exchange(m_ptr, nullptr)); }|ALWAYS_INLINE ~RefPtr() { m_ptr = nullptr; } ALWAYS_INLINE typename PtrTraits::StorageType ptr() { return m_ptr; }|' .WebKit/usr/local/include/wtf/RefPtr.h