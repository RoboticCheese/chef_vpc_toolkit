function install_chef {

#Check whether chef is already installed
rpm -qa | grep chef
if [ $? == 0 ]; then
	touch /tmp/chef_already_installed
	echo "Chef already installed, exiting"
	return 0
fi

local INSTALL_TYPE=${1:-"CLIENT"} # CLIENT/SERVER

local CDN_BASE="http://c2521002.r2.cf0.rackcdn.com"
local CLIENT_TARBALL="chef-client-0.10.8-rhel5.x86_64.tar.gz"
local SERVER_TARBALL="chef-server-0.10.8-rhel5-x86_64.tar.gz"
local BOOTSTRAP="chef-0.10.8-solo-bootstrap.tar.gz"
local RUBY_VERSION="1.8.7.352"
local RUBYGEMS_VERSION="1.8.10"

rpm -q rsync &> /dev/null || yum install -y -q rsync
rpm -q wget &> /dev/null || yum install -y -q wget

#Download bootstrap script for chef-solo
wget "$CDN_BASE/$BOOTSTRAP" -O "/tmp/bootstrap.tar.gz" &> /dev/null \
	|| { echo "Failed to download bootstrap tarball."; exit 1; }

#Download RPMs for chef-client installation
wget "$CDN_BASE/$CLIENT_TARBALL" -O "/tmp/chef-client.tar.gz" &> /dev/null \
	|| { echo "Failed to download Chef client RPM tarball."; exit 1; }

cd /tmp
tar -zxf chef-client.tar.gz || { echo "Failed to extract Chef client tarball."; exit 1; }

cd /tmp/chef-client*

#Install chef client
yum install --nogpgcheck -q -y \
	ruby-${RUBY_VERSION}-5.x86_64.rpm \
	ruby-devel-${RUBY_VERSION}-5.x86_64.rpm \
	ruby-irb-1.8.7.352-5.x86_64.rpm \
	ruby-ri-${RUBY_VERSION}-5.x86_64.rpm \
	ruby-rdoc-${RUBY_VERSION}-5.x86_64.rpm \
	ruby-libs-${RUBY_VERSION}-5.x86_64.rpm \
	rubygems-${RUBYGEMS_VERSION}-1.el5.noarch.rpm \
	ruby-shadow-1.4.1-7.el5.x86_64.rpm \
	rubygems-chef-0.10.8-1.noarch.rpm \
	rubygems-bunny-0.6.0-1.noarch.rpm \
	rubygems-erubis-2.7.0-1.noarch.rpm \
	rubygems-highline-1.6.11-1.noarch.rpm \
	rubygems-json-1.6.1-1.noarch.rpm \
	rubygems-mime-types-1.17.2-1.noarch.rpm \
	rubygems-mixlib-authentication-1.1.4-1.noarch.rpm \
	rubygems-mixlib-cli-1.2.2-1.noarch.rpm \
	rubygems-mixlib-config-1.1.2-1.noarch.rpm \
	rubygems-mixlib-log-1.3.0-1.noarch.rpm \
	rubygems-moneta-0.6.0-1.noarch.rpm \
	rubygems-net-ssh-2.1.4-1.noarch.rpm \
	rubygems-net-ssh-gateway-1.1.0-1.noarch.rpm \
	rubygems-net-ssh-multi-1.1-1.noarch.rpm \
	rubygems-ohai-0.6.10-1.noarch.rpm \
	rubygems-polyglot-0.3.3-1.noarch.rpm \
	rubygems-rest-client-1.6.7-1.noarch.rpm \
	rubygems-systemu-2.2.0-1.noarch.rpm \
	rubygems-treetop-1.4.10-1.noarch.rpm \
	rubygems-uuidtools-2.1.2-1.noarch.rpm \
	rubygems-yajl-ruby-0.7.9-1.noarch.rpm

rm -rf /tmp/chef-client*

if [[ "$INSTALL_TYPE" == "SERVER" ]]; then

	#Download RPMs for chef server installation
	wget "$CDN_BASE/$SERVER_TARBALL" -O "/tmp/chef-server.tar.gz" &> /dev/null \
		|| { echo "Failed to download Chef server RPM tarball."; exit 1; }

	cd /tmp
	tar -zxf chef-server.tar.gz || { echo "Failed to extract Chef server tarball."; exit 1; }

	cd /tmp/chef-server*

	#Install chef server components.
	yum install --nogpgcheck -q -y \
		couchdb-0.11.2-2.el5.x86_64.rpm \
		erlang-R12B-5.10.el5.x86_64.rpm \
		gecode-3.5.0-1.el5.x86_64.rpm \
		gecode-devel-3.5.0-1.el5.x86_64.rpm \
		java-1.6.0-openjdk-1.6.0.0-1.23.1.9.10.el5_7.x86_64.rpm \
		java-1.6.0-openjdk-devel-1.6.0.0-1.23.1.9.10.el5_7.x86_64.rpm \
		libxml2-devel-2.6.26-2.1.12.x86_64.rpm \
		rabbitmq-server-2.2.0-1.el5.noarch.rpm \
		zlib-devel-1.2.3-4.el5.x86_64.rpm \
		alsa-lib-1.0.17-1.el5.x86_64.rpm \
		erlang-ibrowse-2.1.0-1.el5.x86_64.rpm \
		erlang-mochiweb-1.4.1-5.el5.x86_64.rpm \
		erlang-oauth-1.0.1-1.el5.x86_64.rpm \
		giflib-4.1.3-7.3.3.el5.x86_64.rpm \
		jpackage-utils-1.7.3-1jpp.2.el5.noarch.rpm \
		js-1.70-8.el5.x86_64.rpm \
		libX11-1.0.3-11.el5_7.1.x86_64.rpm \
		libXext-1.0.1-2.1.x86_64.rpm \
		libXi-1.0.1-4.el5_4.x86_64.rpm \
		libXrender-0.9.1-3.1.x86_64.rpm \
		libXtst-1.0.1-3.1.x86_64.rpm \
		libicu-3.6-5.16.1.x86_64.rpm \
		pkgconfig-0.21-2.el5.x86_64.rpm \
		tk-8.4.13-5.el5_1.1.x86_64.rpm \
		tzdata-java-2011l-4.el5.x86_64.rpm \
		unixODBC-2.2.11-7.1.x86_64.rpm \
		rubygems-chef-expander-0.10.8-1.noarch.rpm \
		rubygems-chef-server-api-0.10.8-1.noarch.rpm \
		rubygems-chef-server-webui-0.10.8-1.noarch.rpm \
		rubygems-chef-solr-0.10.8-1.noarch.rpm \
		rubygems-addressable-2.2.6-1.noarch.rpm \
		rubygems-amqp-0.6.7-1.noarch.rpm \
		rubygems-bundler-1.0.21-1.noarch.rpm \
		rubygems-coderay-1.0.5-1.noarch.rpm \
		rubygems-daemons-1.1.6-1.noarch.rpm \
		rubygems-dep_selector-0.0.8-1.noarch.rpm \
		rubygems-em-http-request-0.2.15-1.noarch.rpm \
		rubygems-eventmachine-0.12.10-1.noarch.rpm \
		rubygems-extlib-0.9.15-1.noarch.rpm \
		rubygems-fast_xs-0.7.3-1.noarch.rpm \
		rubygems-haml-3.1.4-1.noarch.rpm \
		rubygems-merb-assets-1.1.3-1.noarch.rpm \
		rubygems-merb-core-1.1.3-1.noarch.rpm \
		rubygems-merb-haml-1.1.3-1.noarch.rpm \
		rubygems-merb-helpers-1.1.3-1.noarch.rpm \
		rubygems-merb-param-protection-1.1.3-1.noarch.rpm \
		rubygems-rack-1.4.1-1.noarch.rpm \
		rubygems-rake-0.9.2.2-1.noarch.rpm \
		rubygems-ruby-openid-2.1.8-1.noarch.rpm \
		rubygems-thin-1.3.1-1.noarch.rpm

	rm -rf /tmp/chef-server*
fi
}
