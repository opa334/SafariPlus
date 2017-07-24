include $(THEOS)/makefiles/common.mk

export SYSROOT = $(THEOS)/sdks/iPhoneOS10.1.sdk
#remove the line above if you have issues while compiling

TWEAK_NAME = SafariPlus SafariPlusWK SafariPlusSB
SafariPlus_CFLAGS = -fobjc-arc
SafariPlus_FILES = SafariPlusUtil.xm SafariPlus.xm downloadManager.xm fileBrowser.xm downloadsView.xm filePicker.xm directoryPicker.xm lib/CWStatusBarNotification.m
SafariPlus_EXTRA_FRAMEWORKS += Cephei
SafariPlus_LIBRARIES = colorpicker rocketbootstrap

SafariPlusWK_CFLAGS = -fobjc-arc
SafariPlusWK_FILES = SafariPlusWK.xm
SafariPlusWK_EXTRA_FRAMEWORKS += Cephei

SafariPlusSB_CFLAGS = -fobjc-arc
SafariPlusSB_FILES = SafariPlusSB.xm
SafariPlusSB_LIBRARIES = bulletin rocketbootstrap

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
