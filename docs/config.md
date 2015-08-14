# Configuration Options

All configuration options start with `config.orchestrate`

## `disable_commit_guard`

By default, Vagrant Orchestrate has protection to disallow a push action to managed
servers if there are any uncommitted or untracked files in your git repository. Setting
the `disable_commit_guard` configuration option will disable this protection.

    config.orchestrate.disable_commit_guard = true
