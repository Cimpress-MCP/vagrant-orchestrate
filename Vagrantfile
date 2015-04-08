managed_servers = %w( 192.168.10.80 192.168.10.81 192.168.10.82 192.168.10.83)

Vagrant.configure(2) do |config|
  # These boxes are defined locally to enable acceptance testing. Spinning up
  # real boxes in the vagrant-spec environment was expensive because it ignored
  # the cache and didn't expose a facility to view the vagrant output as it ran.
  # These machines get spun up in the rake task and then the vagrant-spec tests
  # connect to them by IP address.
  managed_servers.each_with_index do |ip, index|
    config.vm.define "local-#{index+1}" do |ubuntu|
      # minimize clock skew, since we're using the `date` command to measure
      # clock skew.
      ubuntu.vm.provision :shell, inline: "ntpdate pool.ntp.org"
      ubuntu.vm.box = "ubuntu/trusty64"
      ubuntu.vm.network "private_network", ip: ip
    end
  end

  # These managed boxes connect to the local boxes defined above by ip address.
  managed_servers.each_with_index do |server, index|
    config.vm.define "managed-#{index+1}" do |managed|
      managed.vm.box = "managed-server-dummy"
      managed.vm.box_url = "./dummy.box"
      managed.ssh.password = "vagrant"
      managed.vm.provider :managed do |provider|
        provider.server = server
      end
    end
  end
end
