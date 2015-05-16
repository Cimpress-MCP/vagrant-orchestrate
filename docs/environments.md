# Environments
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

## Init

Vagrant Orchestrate will template the Vagrantfile and servers.json using `vagrant orchestrate init --environments dev,test,prod`. You will need to specify the servers that exist in each environment in the servers.json file and also create each of the appropriate branches.

## Merge conflicts

Early in the development process, we experimented with a different servers.json file per branch, meaning that the servers.json in the dev branch would only list servers that existed in dev. This created many merge conflicts and this friction quickly led to frustration. In the end, we asserted that the servers.json file should be the same across environments in order to remove the merge conflicts from the equation. This means there is a higher cost to adding a new server because it needs to be added to all environment branches, but in my experience, servers change less often than code. 
