include $(THEOS)/makefiles/common.mk

#WebKit from https://webkit.org/build-archives/
WEBKIT_ROOT = /Users/opa334/WebKit

export TARGET = iphone:clang:12.1.2:8.0
export ARCHS = armv7 armv7s arm64 arm64e

TWEAK_NAME = SafariPlusWC

SafariPlusWC_FILES = HTMLMediaElement.xm libSubstitrate.mm
SafariPlusWC_CFLAGS = -fobjc-arc -I$(WEBKIT_ROOT)/usr/local/include -F$(WEBKIT_ROOT) -Wno-unused-variable
SafariPlusWC_CCFLAGS += -std=c++17

SafariPlusWC_PRIVATE_FRAMEWORKS = WebCore JavaScriptCore

include $(THEOS_MAKE_PATH)/tweak.mk
