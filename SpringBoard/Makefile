include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SafariPlusSB
SafariPlusSB_CFLAGS = -fobjc-arc
SafariPlusSB_FILES += $(wildcard Hooks/*.xm)
SafariPlusSB_FILES += $(wildcard Classes/*.mm)

ifeq ($(NO_ROCKETBOOTSTRAP),0)
SafariPlusSB_LIBRARIES += rocketbootstrap
endif

ifeq ($(NO_LIBBULLETIN),0)
SafariPlusSB_WEAK_LIBRARIES += $(THEOS)/lib/libbulletin.dylib
endif

SafariPlusSB_PRIVATE_FRAMEWORKS = StoreServices

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	echo make finish
	install.exec "killall -9 SpringBoard"
