make package FINALPACKAGE=1
mv control control_normal
mv control_cepheiless control
make clean
make package FINALPACKAGE=1 NO_CEPHEI=1
mv control control_cepheiless
mv control_normal control