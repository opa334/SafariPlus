include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SafariPlusSB
SafariPlusSB_CFLAGS = -fobjc-arc
SafariPlusSB_FILES += $(wildcard Hooks/*.xm)

ifeq ($(SIMJECT),1)
SafariPlusSB_CFLAGS += -D SIMJECT=1
else
SafariPlusSB_LIBRARIES = bulletin rocketbootstrap sandbox# system_sandbox
endif

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	echo make finish
	install.exec "killall -9 SpringBoard"
