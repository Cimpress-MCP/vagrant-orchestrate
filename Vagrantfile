managed_servers = %w( )

required_plugins = %w( vagrant-managed-servers )
required_plugins.each do |plugin|
  system "vagrant plugin install #{plugin}" unless Vagrant.has_plugin? plugin
end
Vagrant.configure("2") do |config|
  config.vm.provision "shell", path: "a"
  config.vm.provision "shell", path: "b"
  config.vm.provision "shell", path: "c"
  config.vm.provision "shell", inline: "foo"
  config.ssh.username = "{{YOUR_SSH_USERNAME}}"
  config.ssh.password = "{{YOUR_SSH_PASSWORD}}"

  managed_servers.each do |instance|
    config.vm.define "managed-#{instance}" do |box|
      box.vm.box = "tknerr/managed-server-dummy"
      box.vm.box_url = "./dummy.box"
      box.vm.provider :managed do |provider|
        provider.server = instance
      end
    end
  end
end
