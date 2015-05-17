# Puppet

Experimental puppet templating support is available with the `--puppet` flag and associated options

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
hieradata/
  common.yaml
hiera.yaml
manifests/
  default.pp
modules/
  .gitignore
```

For a full list of init options, run `vagrant orchestrate init --help`
