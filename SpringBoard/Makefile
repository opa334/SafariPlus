include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SafariPlusSB
SafariPlusSB_CFLAGS = -fobjc-arc
SafariPlusSB_FILES += $(wildcard Hooks/*.xm)
SafariPlusSB_FILES += $(wildcard Classes/*.mm)
SafariPlusSB_LIBRARIES = bulletin rocketbootstrap
SafariPlusSB_PRIVATE_FRAMEWORKS = StoreServices

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	echo make finish
	install.exec "killall -9 SpringBoard"
