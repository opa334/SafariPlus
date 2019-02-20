export SIMJECT ?= 0
export ROOTLESS ?= 0
export NO_DEPENDENCIES ?= 0
export DEBUG_LOGGING ?= 0
export NO_CEPHEI ?= 0
export NO_ROCKETBOOTSTRAP ?= 0
export NO_LIBCOLORPICKER ?= 0
export NO_LIBBULLETIN ?= 0

ifeq ($(ROOTLESS),1)
export NO_DEPENDENCIES = 1
endif

ifeq ($(NO_DEPENDENCIES),1)
export NO_CEPHEI = 1
export NO_ROCKETBOOTSTRAP = 1
export NO_LIBCOLORPICKER = 1
export NO_LIBBULLETIN = 1
endif

ifeq ($(SIMJECT),1)
	export NO_CEPHEI = 1
	export NO_ROCKETBOOTSTRAP = 1
	export NO_LIBCOLORPICKER = 1
	export NO_LIBBULLETIN = 1
	export TARGET = simulator:clang:9.2:8.0
	export ARCHS = x86_64 i386
else
	export TARGET = iphone:clang:11.2:8.0
	export ARCHS = arm64 armv7
endif

include $(THEOS)/makefiles/common.mk

after-install::
	install.exec "killall -9 MobileSafari"

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += MobileSafari

ifeq ($(NO_ROCKETBOOTSTRAP),0)
		SUBPROJECTS += SpringBoard
endif

SUBPROJECTS +=  Preferences

include $(THEOS_MAKE_PATH)/aggregate.mk
