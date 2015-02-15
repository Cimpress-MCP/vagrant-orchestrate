# Vagrant Orchestrate

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
  config.vm.provision "shell", path: "{{YOUR_SCRIPT_PATH}}"
  config.ssh.username = "{{YOUR_SSH_USERNAME}}"
  config.ssh.private_key_path = "{{YOUR_SSH_PRIVATE_KEY_PATH}}"

  managed_servers.each do |instance|
    config.vm.define "managed-#{instance}" do |box|
      box.vm.box = "tknerr/managed-server-dummy"
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

This also supports a self-contained way to install plugins, just list them in the required_plugins section

```ruby
required_plugins = %w( vagrant-managed-servers vagrant-hostsupdater )
```

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

The following files and folders will be placed in the current directory

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
Go ahead and push changes to your managed servers, one at a time. Support for parallel deployments is planned.

    $ vagrant orchestrate push

The push command is currently limited by convention to vagrant machines that start with the "managed-" prefix. So if you have other, local machines defined in the Vagrantfile, `vagrant orchestrate push` will not operate on those, but be cautioned that `vagrant up`, `provision` and `destroy` will by default.

You can run vagrant with increased verbosity if you run into problems

    $ vagrant orchestrate push --debug

## Branching strategy

If you have several environments (e.g. dev, test, prod), it is recommended to create
a separate branch for each environment and put the appropriate servers into the
managed_servers array at the top of the Vagrantfile for each. To move a change
across branches, simply create a feature branch from your earliest branch and then
merge that feature into downstream environments to avoid conflicts.

## Tips for Windows hosts

* Need rsync? Install [OpenSSH](http://www.mls-software.com/opensshd.html) and then run this [script](https://github.com/joefitzgerald/packer-windows/blob/master/scripts/rsync.bat) to install rsync. Vagrant managed servers currently only works with cygwin based rsync implementations.

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
