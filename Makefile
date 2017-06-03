include $(THEOS)/makefiles/common.mk

export SYSROOT = $(THEOS)/sdks/iPhoneOS10.1.sdk
#remove the line above, if you have issues compiling

TWEAK_NAME = SafariPlus SafariPlusWK
SafariPlus_CFLAGS = -fobjc-arc
SafariPlus_FILES = SafariPlus.xm LGShared.xm
SafariPlus_TARGET = 10.1:10.1:10.1:10.1
SafariPlus_EXTRA_FRAMEWORKS += Cephei
SafariPlus_LIBRARIES = colorpicker

SafariPlusWK_CFLAGS = -fobjc-arc
SafariPlusWK_FILES = SafariPlusWK.xm filePicker.xm LGShared.xm
SafariPlusWK_TARGET = 10.1:10.1:10.1:10.1
SafariPlusWK_EXTRA_FRAMEWORKS += Cephei

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
