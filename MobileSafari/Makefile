include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SafariPlus
SafariPlus_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unguarded-availability-new
SafariPlus_FILES = SafariPlus.xm
SafariPlus_FILES += $(wildcard Hooks/*.xm Classes/*.mm Classes/*.xm ../Shared/*.mm)

ifeq ($(NO_CEPHEI),0)
SafariPlus_EXTRA_FRAMEWORKS += Cephei
else
SafariPlus_CFLAGS += -D NO_CEPHEI=1
endif

ifeq ($(NO_LIBCSCOLORPICKER),0)
SafariPlus_LIBRARIES += CSColorPicker
else
SafariPlus_CFLAGS += -D NO_LIBCSCOLORPICKER=1
endif

ifeq ($(NO_ROCKETBOOTSTRAP),0)
SafariPlus_LIBRARIES += rocketbootstrap
else
SafariPlus_CFLAGS += -D NO_ROCKETBOOTSTRAP=1
endif

ifeq ($(DEBUG_LOGGING),1)
	SafariPlus_CFLAGS += -D DEBUG_LOGGING=1
endif

ifeq ($(SIMJECT),1)
	dir_string := @"\"$(CURDIR)\""
	SafariPlus_CFLAGS += -D SIMJECT=1 -D CUR_DIR=$(dir_string)
endif

SafariPlus_PRIVATE_FRAMEWORKS = MediaRemote

include $(THEOS_MAKE_PATH)/tweak.mk
