include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SafariPlusSB
SafariPlusSB_CFLAGS = -fobjc-arc -include ../Prefix.pch -D SPRINGBOARD=1
SafariPlusSB_FRAMEWORKS = Security
SafariPlusSB_FILES += $(wildcard Hooks/*.xm)
SafariPlusSB_FILES += ../Shared/SPFile.mm ../Shared/NSFileManager+DirectorySize.mm

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	echo make finish
	install.exec "killall -9 SpringBoard"
