include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = SafariPlusPrefs
SafariPlusPrefs_CFLAGS = -fobjc-arc -D PREFERENCES=1
SafariPlusPrefs_FILES = ../MobileSafari/Classes/SPFileManager.mm ../MobileSafari/Classes/SPFileBrowserTableViewController.mm ../MobileSafari/Classes/SPFileBrowserNavigationController.mm ../MobileSafari/Classes/SPFileTableViewCell.mm ../MobileSafari/Classes/SPFile.mm ../MobileSafari/Classes/SPLocalizationManager.mm
SafariPlusPrefs_FILES += $(wildcard *.mm)
SafariPlusPrefs_INSTALL_PATH = /Library/PreferenceBundles
SafariPlusPrefs_FRAMEWORKS = UIKit
SafariPlusPrefs_LIBRARIES = colorpicker

SafariPlusPrefs_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/SafariPlusPrefs.plist$(ECHO_END)
