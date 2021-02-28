make clean
cp -f control_normal control
make package FINALPACKAGE=1
make clean
cp -f control_cepheiless control
make package FINALPACKAGE=1 NO_CEPHEI=1
cp -f control_normal control
make clean