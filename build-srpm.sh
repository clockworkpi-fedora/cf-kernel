#!/bin/sh
set -e

# Requirements: sh, rpmdevtools, wget, git, patch

# Configuration
GIT_SOURCE_URL="https://github.com/clockworkpi-fedora/cf-kernel"
GIT_SOURCE_DIR="cf-kernel"
UPSTREAM_COPR="kwizart/kernel-longterm-6.12"
BUILD_ID="09758162"
KERNEL_VERSION="6.12.57"
KERNEL_RELEASE="200"
SRPM_FILE_NAME="kernel-longterm.src.rpm"
BUILD_DIR="srpm"
RPM_BASE_BRANCH="$KERNEL_VERSION-rpm-base"
RPM_PATCH_BRANCH="$KERNEL_VERSION-rpm-patch"
KERNEL_BASE_BRANCH="$KERNEL_VERSION-kernel-base"
KERNEL_PATCH_BRANCH="$KERNEL_VERSION-kernel-patch"

rm -rf $GIT_SOURCE_DIR || true
rm -r $BUILD_DIR || true
mkdir $BUILD_DIR

echo "Downloading base kernel-longterm src.rpm..."
BASE_SRPM_URL="https://download.copr.fedorainfracloud.org/results/$UPSTREAM_COPR/fedora-43-aarch64/$BUILD_ID-kernel-longterm/kernel-longterm-$KERNEL_VERSION-$KERNEL_RELEASE.fc43.src.rpm"
wget -q "$BASE_SRPM_URL" -O $SRPM_FILE_NAME

echo "Extracting src rpm..."
rpmdev-extract -C $BUILD_DIR $SRPM_FILE_NAME 
pushd $BUILD_DIR
EXTRACT_FILENAME=$(ls)
mv $EXTRACT_FILENAME/* .
rmdir $EXTRACT_FILENAME
popd

git clone $GIT_SOURCE_URL $GIT_SOURCE_DIR

pushd $GIT_SOURCE_DIR
echo "Computing kernel patch..."
git checkout $KERNEL_BASE_BRANCH
git checkout $KERNEL_PATCH_BRANCH
git diff $KERNEL_BASE_BRANCH $KERNEL_PATCH_BRANCH -p > kernel-patch
echo "Computing rpm patch..."
git checkout $RPM_BASE_BRANCH
git checkout $RPM_PATCH_BRANCH
git diff $RPM_BASE_BRANCH $RPM_PATCH_BRANCH -p > rpm-patch
popd

cp $GIT_SOURCE_DIR/kernel-patch $BUILD_DIR/linux-kernel-test.patch
cp $GIT_SOURCE_DIR/rpm-patch $BUILD_DIR/

pushd $BUILD_DIR
echo "Applying repo diff as a patch to src rpm..."
patch -p1 < rpm-patch
rm rpm-patch
popd

rm -rf $GIT_SOURCE_DIR
rm $SRPM_FILE_NAME

echo "Done!"
