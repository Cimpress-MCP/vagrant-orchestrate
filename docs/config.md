# Configuration Options

All configuration options start with `config.orchestrate`

## `disable_commit_guard`

By default, Vagrant Orchestrate has protection to disallow a push action to managed
servers if there are any uncommitted or untracked files in your git repository. Setting
the `disable_commit_guard` configuration option will disable this protection.

    config.orchestrate.disable_commit_guard = true

## `take_synced_folder_ownership`

When multiple users are using Vagrant Orchestrate to push to the same target servers,
there can arise permission issues for folders that are synced. When `true`, Vagrant
Orchestrate will change ownership of the guestpath of all synced folders to be the
`owner` specified in the `synced_folder` or the `ssh_info.username`. Has no affect
for Windows guests. Default is `true`.
