set -e

make SIMJECT=1

THEOS_OBJ_DIR=./.theos/obj/iphone_simulator/debug

#install tweak into simject folder

rm -rf /opt/simject/SafariPlus.plist ||:
cp -rfv ./MobileSafari/SafariPlus.plist /opt/simject
rm -rf /opt/simject/SafariPlus.dylib ||:
cp -rfv $THEOS_OBJ_DIR/SafariPlus.dylib /opt/simject

#install PreferenceBundle into all additionally installed simulators

for runtime in /Library/Developer/CoreSimulator/Profiles/Runtimes/*
do
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
done

#install PreferenceBundle into the simulator that ships with Xcode

SIMULATOR_ROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot
SIMULATOR_BUNDLES_PATH=$SIMULATOR_ROOT/Library/PreferenceBundles
SIMULATOR_PLISTS_PATH=$SIMULATOR_ROOT/Library/PreferenceLoader/Preferences

echo "Installing PreferenceBundle to $SIMULATOR_ROOT"

if [ -d "$SIMULATOR_BUNDLES_PATH" ]; then
  rm -rf "$SIMULATOR_BUNDLES_PATH/SafariPlusPrefs.bundle" ||:
  cp -rf "$THEOS_OBJ_DIR/SafariPlusPrefs.bundle" "$SIMULATOR_BUNDLES_PATH"
fi

if [ -d "$SIMULATOR_PLISTS_PATH" ]; then
  rm -rf "$SIMULATOR_PLISTS_PATH/SafariPlusPrefs.plist" ||:
  cp -rf "./Preferences/entry.plist" "$SIMULATOR_PLISTS_PATH/SafariPlusPrefs.plist"
fi

respring_simulator all
