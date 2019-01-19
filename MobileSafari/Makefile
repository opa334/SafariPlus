include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SafariPlus
SafariPlus_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
SafariPlus_FILES = SafariPlus.xm
SafariPlus_FILES += $(wildcard Hooks/*.xm)
SafariPlus_FILES += $(wildcard Classes/*.mm)
SafariPlus_FILES += $(wildcard Classes/*.xm)

ifeq ($(SIMJECT),1)
	dir_string := @"\"$(CURDIR)\""
	username_string := @"\"$(USER)\""
	SafariPlus_CFLAGS += -D SIMJECT=1 -D CUR_DIR=$(dir_string) -D USER=$(username_string)
else
	SafariPlus_EXTRA_FRAMEWORKS += Cephei
	SafariPlus_LIBRARIES = colorpicker rocketbootstrap
endif

ifeq ($(DEBUG_LOGGING),1)
	SafariPlus_CFLAGS += -D DEBUG_LOGGING=1
endif

SafariPlus_PRIVATE_FRAMEWORKS = MediaRemote

include $(THEOS_MAKE_PATH)/tweak.mk
