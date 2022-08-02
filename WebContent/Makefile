include $(THEOS)/makefiles/common.mk

# run get_webkit.sh
WEBKIT_ROOT = ../.WebKit

TWEAK_NAME = SafariPlusWC

SafariPlusWC_FILES = HTMLMediaElement.xm libSubstitrate.mm
SafariPlusWC_CFLAGS = -fobjc-arc -include ../Prefix.pch -I$(WEBKIT_ROOT)/usr/local/include -F$(WEBKIT_ROOT) -Wno-unused-variable -Wno-unused-function
SafariPlusWC_CCFLAGS += -std=c++17

ifeq ($(SIMJECT),1)
SafariPlusWC_EXTRA_FRAMEWORKS += CydiaSubstrate
SafariPlusWC_CFLAGS += -D SIMJECT=1
endif

SafariPlusWC_PRIVATE_FRAMEWORKS = WebCore JavaScriptCore

include $(THEOS_MAKE_PATH)/tweak.mk
