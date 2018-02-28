SIMJECT ?= 0;

ifeq ($(SIMJECT),1)
	export SIMJECT = 1
	export TARGET = simulator:clang:9.2:8.0
	export ARCHS = x86_64 i386
else
	export SIMJECT = 0
	export TARGET = iphone:clang:10.1:8.0
	export ARCHS = arm64 armv7
endif

include $(THEOS)/makefiles/common.mk

after-install::
	install.exec "killall -9 MobileSafari"

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += MobileSafari

ifeq ($(SIMJECT),0)
		SUBPROJECTS += SpringBoard Preferences
endif



include $(THEOS_MAKE_PATH)/aggregate.mk
