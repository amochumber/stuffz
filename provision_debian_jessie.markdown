# Set up your Debian Jessie machine the sysadmiral way

### What are we doing?

We're going to use Puppet and R10K to fetch our puppet repo and deploy the appropriate environment!

### If you're running a VM to make copy paste easier...

```
sudo apt-get install openssh-server
ip addr show
```

Then SSH from a terminal on your host.

### Run these commands first to get what we need

```
sudo apt-get update && sudo apt-get install ca-certificates git
wget -P /tmp/ https://apt.puppetlabs.com/puppetlabs-release-pc1-jessie.deb
sudo dpkg -i /tmp/puppetlabs-release-pc1-jessie.deb
sudo apt-get update && sudo apt-get install puppet-agent
```

### Add deploy key

Create an ssh keypair for root and add the public key to the deply keys of github.com:sysadmiral/sysadmiral_puppet

### Setup R10K

```
sudo /opt/puppetlabs/puppet/bin/gem install r10k
sudo mkdir /etc/puppetlabs/r10k
```

Insert the next section into `/etc/puppetlabs/r10k/r10k.yaml`:

```
# The location to use for storing cached Git repos
:cachedir: '/opt/puppetlabs/r10k/cache'

# A list of git repositories to create
:sources:
  # This will clone the git repository and instantiate an environment per
  # branch in /etc/puppetlabs/code/environments
  :sysadmiral:
     remote: 'git@github.com:sysadmiral/sysadmiral_puppet'
     basedir: '/etc/puppetlabs/code/environments'

:git:
  provider: 'shellgit'
  private_key: '/root/.ssh/id_rsa'
```

### Setup your "environment"

Edit `/etc/puppetlabs/puppet/puppet.conf` and add your environment.

For example, if it was my working laptop I would use production and if it is a VM for testing a change then localdev:

```
[main]
environment = localdev
```

### Fetch the codebase and run puppet!

```
mypuppetenv=$(grep environment /etc/puppetlabs/puppet/puppet.conf | awk {'print $3'})
sudo /opt/puppetlabs/puppet/bin/r10k deploy environment $mypuppetenv -v --puppetfile
sudo /opt/puppetlabs/bin/puppet apply --verbose /etc/puppetlabs/code/environments/$mypuppetenv/site.pp
unset mypuppetenv
```
