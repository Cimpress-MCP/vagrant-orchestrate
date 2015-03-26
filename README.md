[![Build Status](https://travis-ci.org/Cimpress-MCP/vagrant-orchestrate.svg?branch=master)](https://travis-ci.org/Cimpress-MCP/vagrant-orchestrate)
[![Gem Version](https://badge.fury.io/rb/vagrant-orchestrate.svg)](http://badge.fury.io/rb/vagrant-orchestrate)

# Vagrant Orchestrate

![](http://i.imgur.com/71yAw5v.gif)

This is a Vagrant 1.6+ plugin that allows orchestrated deployments
to already provisioned (non-elastic) servers on top of the excellent vagrant-managed-servers plugin.
It features a powerful templating `init` command and is designed from the
ground up to be cross-platform, with first class support for **Windows,
Linux, and Mac**.

## Quick start

```
$ vagrant orchestrate init --shell --shell-inline "echo Hello" \
  --servers myserver1.mydomain.com,myserver2.mydomain.com \
  --ssh-username USERNAME --ssh-private-key-path PATH
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

This also works for Windows with the `--winrm --winrm-username --wirnm-password` parameters, but currently must be initiated from a Windows host.

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
line with `--ssh-username` and `--ssh-private-key-path`. The first line of the file defines an array of
managed servers that the `push` command will operate on.

```ruby
managed_servers = %w( myserver1.mydomain.com myserver2.mydomain.com )
```
#### Windows

This works for Windows managed servers using WinRM as well

    $ vagrant orchestrate init --winrm [--winrm-username USERNAME --winrm-password PASSWORD]

```ruby
  required_plugins = %w( vagrant-managed-servers vagrant-winrm-s )

...

  config.vm.communicator = "winrm"
  config.winrm.username = "{{YOUR_WINRM_USERNAME}}"
  config.winrm.password = "{{YOUR_WINRM_PASSWORD}}"
  config.winrm.transport = :sspinegotiate
```

#### Plugins

This also supports a self-contained way to install plugins, just list them in the required_plugins section

```ruby
required_plugins = %w( vagrant-managed-servers vagrant-hostsupdater )
```

#### Working with multiple environments
It is a very common pattern in software development to have separate environments - e.g. dev, test, and prod.
Vagrant Orchestrate offers a way to manage multiple environments using a combination of a single servers.json
file and the name of the current git branch to know which the current environment is.

```javascript
# servers.json
{
  "environments": {
    "dev": {
      "servers": [
        "dev.myapp.mydomain.com"
      ]
    },
    "test": {
      "servers": [
        "test1.myapp.mydomain.com",
        "test2.myapp.mydomain.com"
      ]
    },
    "prod": {
      "servers": [
        "prod1.myapp.mydomain.com",
        "prod2.myapp.mydomain.com",
        "prod3.myapp.mydomain.com"
      ]
    }
  }
}
```

Add the following line to the top of your `Vagrantfile`

```ruby
managed_servers = VagrantPlugins::Orchestrate::Plugin.load_servers_for_branch
```

If you create git branches named `dev`, `test`, and `prod`, your vagrantfile will become environment aware and
you'll only be able to see the servers appropriate for that environment.

```
$ git branch
* dev
  test
  prod
$ vagrant status
Current machine states:

local                     not created (virtualbox)
dev.myapp.mydomain.com    not created (managed)

$ git checkout test
Switched to branch 'test'
$ vagrant status
Current machine states:

local                     not created (virtualbox)
test1.myapp.mydomain.com  not created (managed)
test2.myapp.mydomain.com  not created (managed)

$ git checkout prod
Switched to branch 'prod'
$ vagrant status
Current machine states:

local                     not created (virtualbox)
prod1.myapp.mydomain.com  not created (managed)
prod2.myapp.mydomain.com  not created (managed)
prod3.myapp.mydomain.com  not created (managed)
```

Any branch that doesn't have a matching environment in the servers.json file will
not list any managed servers.

```
$ git checkout -b my_feature_branch
Switched to a new branch 'my_feature_branch'
$ vagrant status
Current machine states:

local                     not created (virtualbox)
```

#### Credentials

Vagrant orchestrate offers the capability to prompt for credentials from the command
line at the time of a push. You can initialize your Vagrantfile to declare this
by passing the `--credentials-prompt` flag to the `vagrant orchestrate init` command,
or add the following to your Vagrantfile.

```ruby
Vagrant.configure("2") do |config|

  ...

  config.orchestrate.credentials do |creds|
    creds.prompt = true
  end
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

Experimental puppet templating support is available as well with the `--puppet` flag and associated options

```ruby
  required_plugins = %w( vagrant-managed-servers vagrant-librarian-puppet )

  ...

  config.librarian_puppet.placeholder_filename = ".gitignore"
  config.vm.provision "puppet" do |puppet|
    puppet.module_path = 'modules'
    puppet.hiera_config_path = 'hiera.yaml'
  end
```

The following files and folders will be placed in the puppet directory

```
Puppetfile
Vagrantfile
dummy.box
hiera/
  common.yaml
hiera.yaml
manifests/
  default.pp
modules/
  .gitignore
```

For a full list of init options, run `vagrant orchestrate init --help`

### Pushing changes
Go ahead and push changes to your managed servers, in serial by default.

    $ vagrant orchestrate push

The push command is currently limited by convention to vagrant machines that use the `:managed` provider. So if you have other, local machines defined in the Vagrantfile, `vagrant orchestrate push` will not operate on those.

#### Deployment Strategy

Vagrant Orchestrate supports several deployment [strategies](docs/strategy.md) including parallel, canary, and
half and half.

You can push changes to all of your servers in parallel with

    $ vagrant orchestrate push --strategy parallel

## Filtering managed commands
It can be easy to make mistakes such as rebooting production if you have managed long-lived servers as well as local VMs defined in your Vagrantfile. We add some protection with the `orchestrate.filter_managed_commands` configuration setting, which will cause up, provision, reload, and destroy commands to be ignored for servers with the managed provider.

```ruby
  config.orchestrate.filter_managed_commands = true
```

## Branching strategy

If you have several environments (e.g. dev, test, prod), it is recommended to create
a separate branch for each environment and put the appropriate servers into the
managed_servers array at the top of the Vagrantfile for each. To move a change
across branches, simply create a feature branch from your earliest branch and then
merge that feature into downstream environments to avoid conflicts.

## Tips for Windows hosts

* Need rsync? Install [OpenSSH](http://www.mls-software.com/opensshd.html) and then run this [script](https://github.com/joefitzgerald/packer-windows/blob/master/scripts/rsync.bat) to install rsync. Vagrant managed servers currently only works with cygwin based rsync implementations.
* If you're using winrm-s as your communicator, you'll need to configure it first on the target machine! Check out [the plugin readme](https://github.com/Cimpress-MCP/vagrant-winrm-s/blob/master/README.md#setting-up-your-server) for instructions on how to set this up.

## Contributing

1. Fork it ( https://github.com/Cimpress-MCP/vagrant-orchestrate/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Development Tips

You'll want Ruby v2.0.0* and bundler for developing changes.

During the course of development you'll want to run the code you're working on,
not the version of Vagrant Orchestrate you've installed. In order to accomplish
this, run your vagrant orchestrate commands in the bundler environment.

In your shell:

    $ bundle exec vagrant orchestrate
