set -e

make SIMJECT=1

THEOS_OBJ_DIR=./.theos/obj/iphone_simulator/debug

#install tweak into simject folder

rm -rf /opt/simject/SafariPlus.plist ||:
cp -rfv ./MobileSafari/SafariPlus.plist /opt/simject
rm -rf /opt/simject/SafariPlus.dylib ||:
cp -rfv $THEOS_OBJ_DIR/SafariPlus.dylib /opt/simject

rm -rf /opt/simject/SafariPlusWC.plist ||:
cp -rfv ./WebContent/SafariPlusWC.plist /opt/simject
rm -rf /opt/simject/SafariPlusWC.dylib ||:
cp -rfv $THEOS_OBJ_DIR/SafariPlusWC.dylib /opt/simject

#install PreferenceBundle into all additionally installed simulators

for runtime in /Library/Developer/CoreSimulator/Profiles/Runtimes/*
do
  if [ -d "$runtime" ]; then
    echo "Installing PreferenceBundle to $runtime"

    SIMULATOR_ROOT=$runtime/Contents/Resources/RuntimeRoot
    SIMULATOR_BUNDLES_PATH=$SIMULATOR_ROOT/Library/PreferenceBundles
    SIMULATOR_PLISTS_PATH=$SIMULATOR_ROOT/Library/PreferenceLoader/Preferences

    if [ -d "$SIMULATOR_BUNDLES_PATH" ]; then
      rm -rf "$SIMULATOR_BUNDLES_PATH/SafariPlusPrefs.bundle" ||:
      cp -rf "$THEOS_OBJ_DIR/SafariPlusPrefs.bundle" "$SIMULATOR_BUNDLES_PATH"
    fi

    if [ -d "$SIMULATOR_PLISTS_PATH" ]; then
      rm -rf "$SIMULATOR_PLISTS_PATH/SafariPlusPrefs.plist" ||:
      cp -rf "./Preferences/entry.plist" "$SIMULATOR_PLISTS_PATH/SafariPlusPrefs.plist"
    fi
  fi
done

#install PreferenceBundle into the simulator that ships with Xcode

for SIMULATOR_ROOT in /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot /Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot /Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot
do
  if [ -d "$SIMULATOR_ROOT" ]; then
    echo "Installing PreferenceBundle to $SIMULATOR_ROOT"
    SIMULATOR_BUNDLES_PATH=$SIMULATOR_ROOT/Library/PreferenceBundles
    SIMULATOR_PLISTS_PATH=$SIMULATOR_ROOT/Library/PreferenceLoader/Preferences

    if [ -d "$SIMULATOR_BUNDLES_PATH" ]; then
      sudo rm -rf "$SIMULATOR_BUNDLES_PATH/SafariPlusPrefs.bundle" ||:
      sudo cp -rf "$THEOS_OBJ_DIR/SafariPlusPrefs.bundle" "$SIMULATOR_BUNDLES_PATH"
    fi

    if [ -d "$SIMULATOR_PLISTS_PATH" ]; then
      sudo rm -rf "$SIMULATOR_PLISTS_PATH/SafariPlusPrefs.plist" ||:
      sudo cp -rf "./Preferences/entry.plist" "$SIMULATOR_PLISTS_PATH/SafariPlusPrefs.plist"
    fi
  fi
done

resim all
