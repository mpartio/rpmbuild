#!/bin/bash
set -xe
SPEC_FILE="$1"
ADDITIONAL_REPOS="$2"
ENABLE_REPOS="$3"
ENABLE_MODULES="$4"
DISABLE_MODULES="$5"
DNF_COMMANDS="$6"

dnf -y install rpm-build rpmdevtools git yum-utils dnf-plugins-core findutils

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

if [ "$DNF_COMMANDS" != "none" ]; then
  eval "$DNF_COMMANDS"
fi


rpmdev-setuptree

name=$(rpmspec --parse $SPEC_FILE --query --queryformat "%{Name}" --srpm)
version=$(rpmspec --parse $SPEC_FILE --query --queryformat "%{Version}" --srpm)

tar -C /github/workspace/ --transform "s,^./,$name/," -czf /github/home/rpmbuild/SOURCES/${name}-${version}.tar.gz .
ln -sf /github/home/rpmbuild/SOURCES/${name}-${version}.tar.gz /github/home/rpmbuild/SOURCES/${name}.tar.gz

ls -lah /github/workspace/ /github/home/rpmbuild/SOURCES/

dnf builddep -y $SPEC_FILE

commit_id=$(echo "$GITHUB_SHA" | cut -c1-8) # short commit id

export VERSION=$(date -u +%y).$(date -u +%m | sed 's/^0*//').$(date -u +%d | sed 's/^0*//')
export RELEASE=$(date -u +%H%M).$commit_id

rpmbuild --define="version $VERSION" --define="release $RELEASE" -ba $SPEC_FILE

mkdir -p /github/workspace/rpmbuild/SRPMS  /github/workspace/rpmbuild/RPMS
find /github/home/rpmbuild/SRPMS/ -type f -name "*.src.rpm" -exec cp {} /github/workspace/rpmbuild/SRPMS \;
find /github/home/rpmbuild/RPMS/ -type f -name "*.rpm" -exec cp {} /github/workspace/rpmbuild/RPMS \;
ls -la /github/workspace/rpmbuild/SRPMS /github/workspace/rpmbuild/RPMS

echo "srpm_dir_path=rpmbuild/SRPMS/" >> "$GITHUB_OUTPUT"
echo "rpm_dir_path=rpmbuild/RPMS/" >> "$GITHUB_OUTPUT"
