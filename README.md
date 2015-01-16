# Vagrant Orchestrate

This is a Vagrant 1.6+ plugin that allows orchestrated deployments
to existing servers on top of the excellent vagrant-managed-servers plugin.
It features a powerful templating `init` command and is designed from the
ground up to be cross-platform, with first class support for Windows,
Linux, and Mac.

## Usage

Install using the standard Vagrant plugin installation method:

    $ vagrant plugin install vagrant-orchestrate

### Initialization
Initialize a Vagrantfile to orchestrate running a script on multiple managed servers

    $ vagrant orchestrate init --shell

You'll need to edit your Vagrantfile and replace some variables, such as ssh username and
password, and the path to the script to run. The first line of the file defines an array of
managed servers that the `push` command will operate on.

This works for Windows managed servers as well

    $ vagrant orchestrate init --winrm [--winrm-username USERNAME --winrm-password PASSWORD]

For a full list of init options, run `vagrant orchestrate init --help`

### Pushing changes
Go ahead and push changes to your managed servers

    $ vagrant orchestrate push

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
