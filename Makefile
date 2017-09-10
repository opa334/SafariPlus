include $(THEOS)/makefiles/common.mk

SIMJECT ?= 0;

ifeq ($(SIMJECT),1)

export SIMJECT = 1
export TARGET = simulator:latest:9.2
export ARCHS = x86_64 i386

else

export SIMJECT = 0
export TARGET = iphone:latest:10.1
export ARCHS = arm64 armv7

endif

after-install::
	install.exec "killall -9 SpringBoard"

SUBPROJECTS += MobileSafari SpringBoard

include $(THEOS_MAKE_PATH)/tweak.mk

ifeq ($(SIMJECT),0)
SUBPROJECTS += Preferences
endif

include $(THEOS_MAKE_PATH)/aggregate.mk
