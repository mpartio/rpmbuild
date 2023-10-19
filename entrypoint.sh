#!/bin/bash
set -xe
SPEC_FILE="$1"
ADDITIONAL_REPOS="$2"
ENABLE_REPOS="$3"
ENABLE_MODULES="$4"
DISABLE_MODULES="$5"

dnf -y install rpm-build rpmdevtools git yum-utils dnf-plugins-core

if [ "$ADDITIONAL_REPOS" != "none" ]; then
  for i in $(echo $ADDITIONAL_REPOS | tr ',' ' '); do
    dnf -y install $i
  done
fi

if [ "$ENABLE_REPOS" != "none" ]; then
  for i in $(echo $ENABLE_REPOS | tr ',' ' '); do
    dnf config-manager --set-enabled $i
  done
fi

if [ "$ENABLE_MODULES" != "none" ]; then
  for i in $(echo $ENABLE_MODULES | tr ',' ' '); do
    dnf -y module enable $i
  done
fi

if [ "$DISABLE_MODULES" != "none" ]; then
  for i in $(echo $DISABLE_MODULES | tr ',' ' '); do
    dnf -y module disable $i
  done
fi

rpmdev-setuptree

name=$(rpmspec --parse $SPEC_FILE --query --queryformat "%{Name}" --srpm)
version=$(rpmspec --parse $SPEC_FILE --query --queryformat "%{Version}" --srpm)

git archive --output=/github/home/rpmbuild/SOURCES/${name}-${version}.tar.gz --prefix=${name}/ HEAD

ls -lah /github/workspace/ /github/workspace/dist/ /github/home/rpmbuild/SOURCES/
cp /github/workspace/dist/*.tar.gz /github/home/rpmbuild/SOURCES/
ls -lah /github/workspace/dist/ /github/home/rpmbuild/SOURCES/

dnf builddep -y $SPEC_FILE
rpmbuild -ba $SPEC_FILE

ls -lah /github/home/rpmbuild/BUILD/ /github/home/rpmbuild/BUILD/yafti-0.1.0/

ls -lah /github/home/rpmbuild/RPMS
mkdir -p /github/workspace/rpmbuild/SRPMS
mkdir -p /github/workspace/rpmbuild/RPMS
cp /github/home/rpmbuild/SRPMS/* /github/workspace/rpmbuild/SRPMS
cp -R /github/home/rpmbuild/RPMS/. /github/workspace/rpmbuild/RPMS/
ls -la /github/workspace/rpmbuild/SRPMS /github/workspace/rpmbuild/RPMS

echo "source_rpm_dir_path=rpmbuild/SRPMS/" >> $GITHUB_OUTPUT
echo "source_rpm_path=rpmbuild/SRPMS/$(ls /github/workspace/rpmbuild/SRPMS)" >> $GITHUB_OUTPUT
echo "source_rpm_name=$(ls /github/workspace/rpmbuild/SRPMS)" >> $GITHUB_OUTPUT
echo "rpm_dir_path=rpmbuild/RPMS/" >> $GITHUB_OUTPUT
