0.6.0 (May 15th, 2015)

  - Refactor the push command to compose middleware actions rather than performing
  a bunch of work in the command itself. This means that a push using the `parallel`
  strategy will truly be parallel per box, as opposed to the old implementation where
  the `up`, `provision`, `upload_stats`, and `destroy` phases would each happen in
  parallel, but the phases would be done in series.
  - Change the `vagrant orchestrate status` command so that it will run in parallel.
  - Add `vagrant-orchestrate` as a default required plugin. Someone will have to
  install it "by hand" to access the init functionality, but other users pulling
  down a repo with a committed Vagrantfile will not, making each repo more self-contained.

0.5.3 (May 13th, 2015)

  - Fix a bug where the VAGRANT_ORCHESTRATE_USERNAME and VAGRANT_ORCHESTRATE_PASSWORD
  environment variable overrides weren't being read properly. The bug was repro'd
  on a Windows environment.

0.5.2 (May 8th, 2015)

  - Add the `--no-provision` option to the `orchestrate push` command. Useful for
  first timers to gain confidence in using the tool or to be able to just reboot servers.
  - Move the `winrm.transport = :sspinegotiate` declaration from the config level
  to within the managed server section, allowing local Windows VMs to work again.
  - Change the default for --puppet-librarian-puppet to false, as it was impacting
  many Windows users.

0.5.1 (April 27th, 2015)

  - Also short circuit a push operation with an error message if there are untracked files.

0.5.0 (April 22, 2015)

  - Add guard_clean so that a push will fail if there are uncommitted files. Override with VAGRANT_ORCHESTRATE_NO_GUARD_CLEAN
  - Push a status file including git remote url, ref, user, and date on a successful provision to /var/status/vagrant_orchestrate (c:\programdata\vagrant_orchestrate)
  - Retrieve status using `vagrant orchestrate status`
