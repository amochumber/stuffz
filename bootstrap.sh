#!/bin/bash

###
# Shell script for bootstrapping a new laptop
###

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
  echo "caught CTRL-C - EXITING!"
  exit 1
}

lockfile=/var/lock/sysadmiral.lock
bootstrapFile=/root/.sysadmiral.bootstrap
myPuppetRepoLocation="https://github.com/sysadmiral/sysadmiral_puppet.git"
preReqPkgs="ca-certificates git"
internetCheckURL="www.google.com" # make this changeable just in case google goes down!

delLockfile ()
{
  if [[ -f ${lockfile} ]]; then
    rm -f ${lockfile}
  fi
}

cleanup ()
{
  delLockfile
  exit 1
}

thereCanBeOnlyOne ()
{
  if [[ -f ${lockfile} ]]; then
    echo "Cannot run more than one instance"
    exit 1
  else
    touch ${lockfile}
  fi
}

areWeRoot ()
{
  if [[ ${EUID} != "0" ]]; then
    echo "This script must be run as root" 1>&2;
    cleanup
  fi
}

areWeBootstrapped ()
{
  if [[ -f ${bootstrapFile} ]]; then
    echo "This machine has already been bootstrapped the sysadmiral way. Exiting.";
    cleanup
  fi
}

getVars ()
{
  if [[ -f /etc/os-release ]]; then
    myostype=$(sed -n -e 's/^ID=//p' /etc/os-release | sed -e 's/\"//g')
  elif [[ -f  /etc/centos-release ]]; then
    myostype=centos
  elif [[ -f /etc/debian_version ]]; then
    myostype=debian
  else
    echo "Unable to determine OS. This script has been tested with debian jessie and centos 7 only."
    cleanup
  fi

  case $myostype in
    debian)
      installer=$(which apt-get)
      installerOpts="install -qq"
      pkgInstaller=$(which dpkg)
      pkgInstallerOpts="-i"
      puppetRepo="https://apt.puppetlabs.com/"
      puppetRepoPkg="puppetlabs-release-pc1-jessie.deb"
      fetcher=$(which wget)
      fetcherOpts="-P /tmp/"
      fetcherInternetCheckOpts="-q --spider"
      preReqPkgs="${preReqPkgs} lsb-release"
      ;;
    centos)
      installer=$(which yum)
      installerOpts="install -q -y"
      pkgInstaller=${installer}
      pkgInstallerOpts="install -y"
      puppetRepo="https://yum.puppetlabs.com/"
      puppetRepoPkg="puppetlabs-release-pc1-el-7.noarch.rpm"
      fetcher=$(which curl)
      fetcherOpts="-o /tmp/${puppetRepoPkg}"
      fetcherInternetCheckOpts="--silent --head"
      preReqPkgs="${preReqPkgs} redhat-lsb" 
      ;;
    *)
      echo "myostype not found"
      cleanup
      ;;    
  esac
}

internetCheck ()
{
  internetCheckCommand="${fetcher} ${fetcherInternetCheckOpts} ${internetCheckURL}"
  echo "Checking we are online..."
  ${internetCheckCommand} 1> /dev/null
  if [ $? == 0 ]; then
    echo "We are online! \o/";
  else
    echo "Get some internet all up in here!";
    cleanup
  fi
}

installPreReqs ()
{
  echo "Installing required packages. Please wait..."
  ${installer} ${installerOpts} ${preReqPkgs}
  echo "Required packages installed"
}

getEnv ()
{
  echo;
  echo "What Puppet environment will this machine use?"
  read puppetEnv
  echo;
}

installPuppet ()
{
  echo "Installing puppet repo and puppet-agent"
  ${fetcher} ${fetcherOpts} ${puppetRepo}${puppetRepoPkg}
  ${pkgInstaller} ${pkgInstallerOpts} /tmp/${puppetRepoPkg}
  ${installer} update -y && ${installer} install -y puppet-agent
  echo "[main]
  environment = $puppetEnv" >> /etc/puppetlabs/puppet/puppet.conf
  echo "puppet-agent is installed"
  puppetBinDir="/opt/puppetlabs/puppet/bin/"
}

installR10K ()
{
  echo "Installing r10k"
  ${puppetBinDir}gem install r10k
  mkdir /etc/puppetlabs/r10k

  echo "# The location to use for storing cached Git repos
  :cachedir: '/opt/puppetlabs/r10k/cache'
  
  # A list of git repositories to create
  :sources:
  # This will clone the git repository and instantiate an environment per
  # branch in /etc/puppetlabs/code/environments
    :sysadmiral:
       remote: '${myPuppetRepoLocation}'
       basedir: '/etc/puppetlabs/code/environments'
  
  :git:
    provider: 'shellgit'" > /etc/puppetlabs/r10k/r10k.yaml
  echo "r10k installed and config file created"
}

bootstrap ()
{
  ${puppetBinDir}r10k deploy environment ${puppetEnv} -v --puppetfile
  ${puppetBinDir}puppet apply --verbose --hiera_config=/etc/puppetlabs/code/environments/${puppetEnv}/hiera.yaml /etc/puppetlabs/code/environments/$puppetEnv/site.pp
}

youveBeenBootstrapped ()
{
  echo "This file stops the sysadmiral bootstrap from being run more times than the initial run which may have undesirable effects" > ${bootstrapFile};
}

thereCanBeOnlyOne
areWeRoot
areWeBootstrapped
getVars
internetCheck
installPreReqs
getEnv
installPuppet
installR10K
bootstrap
youveBeenBootstrapped
