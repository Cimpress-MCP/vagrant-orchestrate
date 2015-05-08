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
