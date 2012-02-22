function install_chef {

local INSTALL_TYPE=${1:-"CLIENT"} # CLIENT/SERVER

# cached RPMs from ELFF
local CDN_BASE="http://c1849332.r32.cf0.rackcdn.com"
local CHEF_VERSION="0.9.8"
local CHEF_TYPE=$(echo $INSTALL_TYPE | tr [:upper:] [:lower:])
local RH_RELEASE=$(awk '{print $3}' < /etc/redhat-release)
local ARCH=$(uname -p)

TARBALL="chef-${CHEF_TYPE}-${CHEF_VERSION}-centos${RH_RELEASE}-${ARCH}.tar.gz"

rpm -q rsync &> /dev/null || yum install -y -q rsync
rpm -q wget &> /dev/null || yum install -y -q wget

if ! rpm -q rubygem-chef &> /dev/null; then

	local CHEF_RPM_DIR=$(mktemp -d)

	wget "$CDN_BASE/$TARBALL" -O "$CHEF_RPM_DIR/chef.tar.gz" &> /dev/null \
		|| { echo "Failed to download Chef RPM tarball."; exit 1; }
	cd $CHEF_RPM_DIR

	tar xzf chef.tar.gz || { echo "Failed to extract Chef tarball."; exit 1; }
	rm chef.tar.gz
	cd chef*
	yum install -q -y --nogpgcheck */*.rpm
	if [[ "$INSTALL_TYPE" == "SERVER" ]]; then
		rpm -q rubygem-chef-server &> /dev/null || { echo "Failed to install chef."; exit 1; }
	else
		rpm -q rubygem-chef &> /dev/null || { echo "Failed to install chef."; exit 1; }
	fi
	cd /tmp
	rm -Rf "$CHEF_RPM_DIR"

fi

}
