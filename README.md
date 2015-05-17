[![Build Status](https://travis-ci.org/Cimpress-MCP/vagrant-orchestrate.svg?branch=master)](https://travis-ci.org/Cimpress-MCP/vagrant-orchestrate)
[![Gem Version](https://badge.fury.io/rb/vagrant-orchestrate.svg)](http://badge.fury.io/rb/vagrant-orchestrate)

# Vagrant Orchestrate

![](http://i.imgur.com/71yAw5v.gif)

This is a Vagrant 1.6+ plugin that allows orchestrated deployments
to already provisioned (non-elastic) servers on top of the excellent [Vagrant Managed Servers](http://github.com/tknerr/vagrant-managed-servers) plugin.
It features a powerful templating `init` command, support for multiple environments, several deployment strategies
and is designed from the ground up to be cross-platform, with first class support for **Windows,
Linux, and Mac**.

## Quick start

```
$ vagrant orchestrate init --servers myserver1.mydomain.com,myserver2.mydomain.com \
  --ssh-username USERNAME --ssh-private-key-path PATH \
  --shell --shell-inline "echo Hello"

$ ls
Vagrantfile	  dummy.box
$ vagrant orchestrate push
==> managed-myserver1.mydomain.com: Linking vagrant with managed server myserver1.mydomain.com
==> managed-myserver1.mydomain.com:  -- Server: myserver1.mydomain.com
==> managed-myserver1.mydomain.com: Rsyncing folder: ~/dev/demo => /vagrant
==> managed-myserver1.mydomain.com: Running provisioner: shell...
==> managed-myserver1.mydomain.com: Running: inline script
==> managed-myserver1.mydomain.com: Hello
==> managed-myserver1.mydomain.com: Unlinking vagrant from managed server myserver1.mydomain.com
==> managed-myserver1.mydomain.com:  -- Server: myserver1.mydomain.com
==> managed-myserver2.mydomain.com: Linking vagrant with managed server myserver2.mydomain.com
==> managed-myserver2.mydomain.com:  -- Server: myserver2.mydomain.com
==> managed-myserver2.mydomain.com: Rsyncing folder: ~/dev/demo => /vagrant
==> managed-myserver2.mydomain.com: Running provisioner: shell...
==> managed-myserver2.mydomain.com: Running: inline script
==> managed-myserver2.mydomain.com: Hello
==> managed-myserver2.mydomain.com: Unlinking vagrant from managed server myserver2.mydomain.com
==> managed-myserver2.mydomain.com:  -- Server: myserver2.mydomain.com
```

This also works for Windows with the `--winrm --winrm-username USERNAME --wirnm-password PASSWORD` parameters, but  must be initiated from a Windows host.

## Usage

Install using the standard Vagrant plugin installation method:

    $ vagrant plugin install vagrant-orchestrate

### Initialization
Initialize a Vagrantfile to orchestrate running a script on multiple managed servers

    $ vagrant orchestrate init --shell

Which produces a simple default Vagrantfile that can push to managed servers:
```ruby
managed_servers = %w( )

required_plugins = %w( vagrant-managed-servers )
required_plugins.each do |plugin|
  system "vagrant plugin install #{plugin}" unless Vagrant.has_plugin? plugin
end
Vagrant.configure("2") do |config|
  # This disables up, provision, reload, and destroy for managed servers. Use
  # `vagrant orchestrate push` to communicate with managed servers.
  config.orchestrate.filter_managed_commands = true

  config.vm.provision "shell", path: "{{YOUR_SCRIPT_PATH}}"
  config.ssh.username = "{{YOUR_SSH_USERNAME}}"
  config.ssh.private_key_path = "{{YOUR_SSH_PRIVATE_KEY_PATH}}"

  config.vm.define "local", primary: true do |local|
    local.vm.box = "ubuntu/trusty64"
  end

  managed_servers.each do |instance|
    config.vm.define instance, autostart: false do |box|
      box.vm.box = "managed-server-dummy"
      box.vm.box_url = "./dummy.box"
      box.vm.provider :managed do |provider|
        provider.server = instance
      end
    end
  end
end
```

You'll need to edit your Vagrantfile and replace some variables, such as ssh username and
private key, and the path to the script to run. Alternatively, you can pass them on the command
line with `--ssh-username` and `--ssh-private-key-path`. The first line of the file defines an whitespace delimeted
array of managed servers that the `push` command will operate on.

```ruby
managed_servers = %w( myserver1.mydomain.com myserver2.mydomain.com )
```
#### Windows

This works for Windows managed servers using WinRM as well

    $ vagrant orchestrate init --winrm --winrm-username USERNAME --winrm-password PASSWORD

```ruby
  required_plugins = %w( vagrant-managed-servers vagrant-winrm-s )

...

  config.vm.communicator = "winrm"
  config.winrm.username = "USERNAME"
  config.winrm.password = "PASSWORD"
```

#### Plugins

This also supports a portable and repeatable way to install plugins, just list them in the required_plugins section

```ruby
required_plugins = %w( vagrant-managed-servers vagrant-hostsupdater )
```

#### Working with multiple environments

Vagrant Orchestrate offers a way to manage multiple environments using a combination of a single servers.json file and the name of the current git branch as an indicator of the current environment.

To initialize an environment aware Vagrantfile, use

    $ vagrant orchestrate init --environments dev,test,prod

You'll need to create git branches with matching names and enter data into the the servers.json
file in order for the Vagrantfile to be git branch aware.

Learn more about [environments](docs/environments.md).

#### Credentials

Vagrant orchestrate offers the capability to prompt for credentials from the command
line at the time of a push. You can initialize your Vagrantfile to declare this
by passing the `--credentials-prompt` flag to the `vagrant orchestrate init` command,
or add the following to your Vagrantfile.

```ruby
  config.orchestrate.credentials.prompt = true
```

The credentials config object can accept one additional parameter, `file_path`. Setting
`creds.file_path = path/to/username_password.yaml` tells vagrant-orchestrate to
look for a file at the given path, and read from its :username and :password fields
('username' and 'password' are also accepted). Additionally, you can pass the username
and password in using the `VAGRANT_ORCHESTRATE_USERNAME` and `VAGRANT_ORCHESTRATE_PASSWORD`
environment variables. Environment variables take precedence over the file, and the file
takes precedence over the prompting. It is possible to set `prompt` to `false`, or leave
it unset, in which case only environment variables and the credentials file (if provided)
will be checked.

#### Puppet

Experimental [puppet templating](docs/puppet.md) support is available as well with the `--puppet` flag and associated options

### Pushing changes
Go ahead and push changes to your managed servers, in serial by default.

    $ vagrant orchestrate push

The push command is currently limited to vagrant machines that use the `:managed` provider. So if you have other, local machines defined in the Vagrantfile, `vagrant orchestrate push` will not operate on those.

### Filtering managed commands
It can be easy to make mistakes such as rebooting a production server if you have managed long-lived servers as well as local VMs defined in your Vagrantfile. We add some protection with the `orchestrate.filter_managed_commands` configuration setting, which will cause up, provision, reload, and destroy commands to be ignored for servers with the managed provider. This can be disabled by setting the variable to false in the Vagrantfile.

```ruby
  config.orchestrate.filter_managed_commands = true
```

#### Deployment Strategy

Vagrant Orchestrate supports several deployment [strategies](docs/strategy.md) including parallel, canary, and half and half.

You can push changes to all of your servers in parallel with

    $ vagrant orchestrate push --strategy parallel

### Status
The `vagrant orchestrate status` command will reach out to each of the defined
managed servers and print information about the last successful push from this
repo, including date, ref, and user that performed the push.

```
$ vagrant orchestrate status
Current managed server states:

managed-1  2015-04-19 00:46:22 UTC  e983dddd8041c5db77494266328f1d266430f57d  cbaldauf
managed-2  2015-04-19 00:46:22 UTC  e983dddd8041c5db77494266328f1d266430f57d  cbaldauf
managed-3  Status unavailable.
managed-4  2015-04-19 00:43:07 UTC  e983dddd8041c5db77494266328f1d266430f57d  cbaldauf
```

## Windows

### Host

* Need rsync? Install [OpenSSH](http://www.mls-software.com/opensshd.html) and then run this [script](https://github.com/joefitzgerald/packer-windows/blob/master/scripts/rsync.bat) to install rsync. Vagrant managed servers currently only works with cygwin based rsync implementations.

### Managed Guest
You'll need to bootstrap the target machine. The following script should get you there.

```
winrm quickconfig
winrm set winrm/config/service/auth @{Negotiate="true"}
winrm set winrm/config/service @{AllowUnencrypted="false"}
winrm set winrm/config/winrs @{MaxShellsPerUser="25"}
winrm set winrm/config/winrs @{MaxConcurrentUsers="25"}
sc config winrm start= auto
sc config winrm type= own
```
* Check out [the winrm-s readme](https://github.com/Cimpress-MCP/vagrant-winrm-s/blob/master/README.md#setting-up-your-server) for more information

## Contributing

1. Fork it ( https://github.com/Cimpress-MCP/vagrant-orchestrate/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Run locally with `bundle exec vagrant orchestrate [init|push|status]`
5. `bundle exec rake build`
6. `bundle exec rake acceptance`, which will take a few minutes
7. Push to the branch (`git push origin my-new-feature`)
8. Create a new Pull Request

Prerequisites:
* Ruby 2.0 or greater
