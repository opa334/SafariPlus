include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SafariPlus
SafariPlus_CFLAGS = -fobjc-arc -I$(INCLUDES) -include ../Prefix.pch -Wno-deprecated-declarations -Wno-unguarded-availability-new -Wno-unused-variable
SafariPlus_FILES = Util.xm Init.xm Undirector.xmi
SafariPlus_FILES += $(wildcard Hooks/*.xm Classes/*.mm Classes/*.xm ../Shared/*.mm)
SafariPlus_EXTRA_FRAMEWORKS += CydiaSubstrate

ifeq ($(NO_LIBCSCOLORPICKER),0)
SafariPlus_LIBRARIES += CSColorPicker
else
SafariPlus_CFLAGS += -D NO_LIBCSCOLORPICKER=1
endif

ifeq ($(DEBUG_LOGGING),1)
SafariPlus_CFLAGS += -D DEBUG_LOGGING=1
endif

ifeq ($(SIMJECT),1)
dir_string := @"\"$(CURDIR)\""
SafariPlus_CFLAGS += -D SIMJECT=1 -D CUR_DIR=$(dir_string)
endif

SafariPlus_LIBRARIES += objc sandy
SafariPlus_FRAMEWORKS = UIKit CoreFoundation Foundation AVKit
SafariPlus_PRIVATE_FRAMEWORKS = MobileIcons

include $(THEOS_MAKE_PATH)/tweak.mk
