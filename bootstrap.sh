#!/bin/bash

###
# Shell script for bootstrapping a new laptop
###

lockfile=/var/lock/sysadmiral.lock
preReqPkgs="ca-certificates git"
puppetAptDeb="puppetlabs-release-pc1-jessie.deb"
puppetAptRepo="https://apt.puppetlabs.com/$puppetAptDeb"
puppetRepoLocation="https://github.com/sysadmiral/sysadmiral_puppet.git"

function cleanup {
if [ -e $lockfile ]; then
	rm $lockfile
fi
}

function thereCanBeOnlyOne {
if [ -e $lockfile ]; then
	echo "Cannot run more than one instance"
	exit 1
else
	touch $lockfile
fi
}

function areWeRoot {
if [ $EUID != "0" ]; then
	echo "This script must be run as root" 1>&2;
	cleanup
	exit 1;
fi
}

function areWeBootstrapped {
if [ -e /root/sysadmiral.bootstrap ]; then
	echo "This machine has already been bootstrapped the sysadmiral way. Exiting.";
	cleanup
	exit 1;
else
	echo "This file stops the sysadmiral bootstrap from being run more than once which may have undesirable effects" > /root/sysadmiral.bootstrap;
fi
}

function internetCheck {
echo -n "Checking we are online..."
nc -zw 1 8.8.8.8 53  >/dev/null 2>&1
if [ $? == 0 ]; then
	echo "We are online! \o/";
else
	echo "Get some internet all up in here!";
	cleanup
	exit 1;
fi
}

function getEnv {
echo "\nWhat Puppet environment will this machine use?"
read puppetEnv
echo
}

function facterVars {
if [ -z $SUDO_USER ]; then
	echo "Cannot determine user. Make sure that:\n
	1 - You have setup your own user\n
	2 - You are not logging in directly as root\n
	3 - You have sudo installed and '$SUDO_USER' exists\n";
	cleanup
	exit 1;
  else FACTER_user=$SUDO_USER;
fi

if [ -d /home/$SUDO_USER ]; then
	FACTER_home=/home/$SUDO_USER;
else
	echo "Can't find your home dir in /home/. Does it exist?"
	cleanup
	exit 1;
fi
}

function youveBeenBootstrapped {
echo "This file stops the sysadmiral bootstrap from being run more than once which may have undesirable effects" > /root/sysadmiral.bootstrap;
cleanup
}

thereCanBeOnlyOne
areWeRoot
areWeBootstrapped
internetCheck
getEnv
echo "Setting up new $puppetEnv machine..."
facterVars
echo "\nInstalling pre-reqs..."
apt-get -qq update && apt-get install -y -q $preReqPkgs
wget -P /tmp/ $puppetAptRepo
dpkg -i /tmp/$puppetAptDeb
apt-get update -qq && apt-get install -y puppet-agent
/opt/puppetlabs/puppet/bin/gem install r10k
mkdir /etc/puppetlabs/r10k

echo "# The location to use for storing cached Git repos
:cachedir: '/opt/puppetlabs/r10k/cache'

# A list of git repositories to create
:sources:
# This will clone the git repository and instantiate an environment per
# branch in /etc/puppetlabs/code/environments
  :sysadmiral:
     remote: '$puppetRepoLocation'
     basedir: '/etc/puppetlabs/code/environments'

:git:
  provider: 'shellgit'" > /etc/puppetlabs/r10k/r10k.yaml

echo "[main]
environment = $puppetEnv" >> /etc/puppetlabs/puppet/puppet.conf

/opt/puppetlabs/puppet/bin/r10k deploy environment $puppetEnv -v --puppetfile
/opt/puppetlabs/bin/puppet apply --verbose --hiera_config=/etc/puppetlabs/code/environments/$puppetEnv/hiera.yaml /etc/puppetlabs/code/environments/$puppetEnv/site.pp
