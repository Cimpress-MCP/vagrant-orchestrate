# Deployment Strategies

Vagrant Orchestrate supports several deployment strategies that allow you to orchestrate the behavior pushes to remote servers. Here we'll cover how to use the various strategies as well as describing
situations when each might be useful.

## Strategies

### Serial (default)
Deploy to the target servers one at a time. This can be useful if you
have a small number servers, or if you need to keep the majority of your servers
online in order to support your application's load.

    $ vagrant orchestrate push --strategy serial

    config.orchestrate.strategy = :serial


### Parallel
Deploy to all of the target servers at the same time. This is
useful if you want to minimize the total amount of time that an deployment takes.
Depending on how you've written your provisioners, this could cause downtime for
the application that is being deployed.

    $ vagrant orchestrate push --strategy parallel

    config.orchestrate.strategy = :parallel

### Canary
Deploy to a single server, pause to allow for testing, and then deploy the remainder of the servers in parallel.
This is a great opportunity to test one node of your cluster before blasting your
changes out to them all. This can be particularly useful when combined with post
provision [trigger](https://github.com/emyl/vagrant-triggers) to run a smoke test.

    $ vagrant orchestrate push --strategy canary

    config.orchestrate.strategy = :canary

The prompt can be surpressed with the `--force` (`-f`) flag.

### Half and Half
Deploys to half of the cluster in parallel, then the other half, with
a pause in between. This won't manage any of your load balancing or networking
configuration for you, but if your application has a healthcheck that your load
balancer respects, it should be easy to turn it off at the start of your provisioning
and back on at the end. If your application can serve the load on half of its nodes
then this will be the best blend of getting the deployment done quickly and maintaining
a running application. If the total number of target servers is odd then the smaller
number will be deployed to first.

    $ vagrant orchestrate push --strategy half_half

    config.orchestrate.strategy = :half_half

### Canary Half and Half
Combines the two immediately above - deploying to a single
server, pausing, then to half of the remaining cluster in parallel, pausing, and then the other half,
also in parallel. This is good if you have a large number of servers and want to do a
smoke test of a single server before committing to pushing to half of your farm.

    $ vagrant orchestrate push --strategy canary_half_half

		config.orchestrate.strategy = :canary_half_half

## Specifying a strategy

### Command line

Strategies can be passed on the command line with the `--strategy` parameter

    $ vagrant orchestrate push --strategy parallel

### Vagrantfile configuration

Alternatively, you can specify the deployment strategy in your Vagrantfile

    config.orchestrate.strategy = :parallel

Command line parameters take precedence over configuration values set in the Vagrantfile.

## Suppressing Prompts
In order to automate the deployment process, you'll need to suppress
prompts. You can achieve that in two ways:

From the command line, add the `--force` or `-f` parameters

    $ vagrant orchestrate push --strategy canary -f


Within your Vagrantfile, set the `force_push` setting to true

    config.orchestrate.force_push = true

## Support for other strategies
If you have ideas for other strategies that you think would be broadly useful,
open an issue and we'll discuss.
