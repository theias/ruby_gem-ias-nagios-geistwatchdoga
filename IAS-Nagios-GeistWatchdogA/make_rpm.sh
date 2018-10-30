#!/bin/bash

HERE=`pwd`
SPEC_FILE=IAS-Nagios-GeistWatchdogA.rpm_spec
BUILD_DIR="$HERE/build"
ROOT_DIR="$BUILD_DIR/root"

echo "Root dir: " $ROOT_DIR
echo "Spec file: " $SPEC_FILE
echo "Build dir: " $BUILD_DIR
mkdir $BUILD_DIR

fakeroot rpmbuild --buildroot $ROOT_DIR \
-bb $SPEC_FILE \
--define "_topdir $BUILD_DIR" \
--define "_rpmtopdir $BUILD_DIR"
