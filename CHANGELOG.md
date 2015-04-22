0.5.0 (April 22, 2015)

  - Add guard_clean so that a push will fail if there are uncommitted files. Override with VAGRANT_ORCHESTRATE_NO_GUARD_CLEAN
  - Push a status file including git remote url, ref, user, and date on a successful provision to /var/status/vagrant_orchestrate (c:\programdata\vagrant_orchestrate)
  - Retrieve status using `vagrant orchestrate status`
