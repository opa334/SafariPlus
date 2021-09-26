include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SafariPlusSB
SafariPlusSB_CFLAGS = -fobjc-arc -D SPRINGBOARD=1
SafariPlusSB_FRAMEWORKS = Security
SafariPlusSB_PRIVATE_FRAMEWORKS = AppSupport
SafariPlusSB_FILES += $(wildcard Hooks/*.xm Classes/*.mm)
SafariPlusSB_FILES += ../Shared/SPFile.mm ../Shared/NSFileManager+DirectorySize.mm

ifeq ($(NO_ROCKETBOOTSTRAP),0)
SafariPlusSB_LIBRARIES += rocketbootstrap
endif

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	echo make finish
	install.exec "killall -9 SpringBoard"
