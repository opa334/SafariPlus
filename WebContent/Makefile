include $(THEOS)/makefiles/common.mk

#WebKit from https://webkit.org/build-archives/
WEBKIT_ROOT = /Users/opa334/WebKit

TWEAK_NAME = SafariPlusWC

SafariPlusWC_FILES = HTMLMediaElement.xm libSubstitrate.mm
SafariPlusWC_CFLAGS = -fobjc-arc -I$(WEBKIT_ROOT)/usr/local/include -include ../Prefix.pch -F$(WEBKIT_ROOT) -Wno-unused-variable -Wno-unused-function
SafariPlusWC_CCFLAGS += -std=c++17

ifeq ($(SIMJECT),1)
SafariPlusWC_EXTRA_FRAMEWORKS += CydiaSubstrate
SafariPlusWC_CFLAGS += -D SIMJECT=1
endif

SafariPlusWC_PRIVATE_FRAMEWORKS = WebCore JavaScriptCore

include $(THEOS_MAKE_PATH)/tweak.mk
