require "vagrant-orchestrate/command/init"
require "vagrant-spec/unit"

describe VagrantPlugins::Orchestrate::Command::Init do
  include_context "vagrant-unit"

  let(:base_argv)     { ["-f"] }
  let(:argv)          { [] }
  let(:iso_env) do
    env = isolated_environment
    # We need to load an empty vagrantfile in order for things to be initialized
    # properly
    env.vagrantfile("")
    env.create_vagrant_env ui_class: ui_class
  end

  let(:ui_class) { nil }

  subject { described_class.new(base_argv + argv, iso_env) }

  ["-h", "--help"].each do |arg|
    describe "init help message #{arg}" do
      let(:argv) { ["init", arg] }
      let(:ui_class) { Vagrant::UI::Basic }
      it "shows help" do
        output = capture_stdout { subject.execute }
        expect(output).to include("Usage: vagrant orchestrate init [options]")
      end
    end
  end

  describe "no parameters" do
    it "creates basic vagrantfile" do
      subject.execute
      expect(Dir.entries(iso_env.cwd)).to include("Vagrantfile")
    end
  end

  context "shell provisioner" do
    describe "basic operation" do
      let(:argv) { ["--shell"] }
      it "creates a vagrantfile with default shell path" do
        subject.execute
        expect(iso_env.vagrantfile.config.vm.provisioners.first.type).to eq(:shell)
        expect(iso_env.vagrantfile.config.vm.provisioners.first.config.path).to eq(described_class::DEFAULT_SHELL_PATH)
        expect(iso_env.vagrantfile.config.vm.provisioners.count).to eq(1)
      end
    end

    describe "shell path" do
      let(:argv) { ["--shell", "--shell-paths", "foo.sh"] }
      it "creates a vagrantfile with custom shell path" do
        subject.execute
        expect(iso_env.vagrantfile.config.vm.provisioners.first.type).to eq(:shell)
        expect(iso_env.vagrantfile.config.vm.provisioners.first.config.path).to eq("foo.sh")
      end
    end

    describe "shell inline" do
      let(:argv) { ["--shell", "--shell-inline", "echo Hello, World!"] }
      it "is passed through" do
        subject.execute
        expect(iso_env.vagrantfile.config.vm.provisioners.first.config.inline).to eq("echo Hello, World!")
      end
    end

    describe "multiple shell paths" do
      let(:argv) { ["--shell", "--shell-paths", "foo.sh,bar.sh"] }
      it "creates a vagrantfile with custom shell path" do
        subject.execute
        expect(iso_env.vagrantfile.config.vm.provisioners.first.type).to eq(:shell)
        expect(iso_env.vagrantfile.config.vm.provisioners.first.config.path).to eq("foo.sh")
        expect(iso_env.vagrantfile.config.vm.provisioners[1].config.path).to eq("bar.sh")
      end
    end
  end

  context "puppet" do
    describe "basic operation" do
      let(:argv) { ["--provision-with", "puppet"] }
      it "creates a vagrantfile with a puppet provisioner" do
        subject.execute
        expect(iso_env.vagrantfile.config.vm.provisioners.first.type).to eq(:puppet)
      end

      it "creates the default files" do
        subject.execute
        expect(Dir.entries(iso_env.cwd)).to include("puppet")
        expect(Dir.entries(File.join(iso_env.cwd, "puppet"))).to include("manifests")
        expect(Dir.entries(File.join(iso_env.cwd, "puppet", "manifests"))).to include("default.pp")
      end
    end

    describe "shorthand" do
      let(:argv) { ["--puppet"] }
      it "creates a vagrantfile with a puppet provisioner" do
        subject.execute
        expect(iso_env.vagrantfile.config.vm.provisioners.first.type).to eq(:puppet)
      end
    end

    describe "librarian puppet" do
      let(:argv) { ["--puppet", "--puppet-librarian-puppet"] }
      it "is passed into the Vagrantfile" do
        subject.execute
        expect(iso_env.vagrantfile.config.librarian_puppet.placeholder_filename).to eq(".gitignore")
      end

      it "creates the modules directory and placeholder" do
        subject.execute
        expect(Dir.entries(File.join(iso_env.cwd, "puppet"))).to include("modules")
        expect(Dir.entries(File.join(iso_env.cwd, "puppet", "modules"))).to include(".gitignore")
      end

      it "creates the Puppetfile" do
        subject.execute
        expect(Dir.entries(File.join(iso_env.cwd, "puppet"))).to include("Puppetfile")
      end

      it "contains the plugin" do
        subject.execute
        pluginsfile = File.readlines(File.join(iso_env.cwd, ".vagrantplugins")).join
        expect(pluginsfile).to include("vagrant-librarian-puppet")
      end

      describe "negative" do
        let(:argv) { ["--puppet", "--no-puppet-librarian-puppet"] }
        it "shouldn't be included" do
          subject.execute
          # This should be the default, as long as the plugin is installed
          expect(iso_env.vagrantfile.config.librarian_puppet.placeholder_filename).to eq(".PLACEHOLDER")
        end
      end
    end

    describe "hiera" do
      let(:argv) { ["--puppet", "--puppet-hiera"] }
      it "is passed into the Vagrantfile" do
        subject.execute
        expect(iso_env.vagrantfile.config.vm.provisioners.first.config.hiera_config_path).to eq("puppet/hiera.yaml")
      end

      it "creates the file" do
        subject.execute
        expect(Dir.entries(File.join(iso_env.cwd, "puppet"))).to include("hiera.yaml")
        expect(Dir.entries(File.join(iso_env.cwd, "puppet"))).to include("hieradata")
        expect(Dir.entries(File.join(iso_env.cwd, "puppet", "hieradata"))).to include("common.yaml")
      end

      describe "hiera.yaml" do
        it "declares a datadir contains a common.yaml file" do
          subject.execute
          hiera_obj = YAML.load(File.read(File.join(iso_env.cwd, "puppet", "hiera.yaml")))
          datadir = hiera_obj[:yaml][:datadir]
          expect(datadir).to start_with("/vagrant")
          datadir_path = File.join(iso_env.cwd, datadir.sub("/vagrant/", ""))
          expect(datadir_path).to satisfy { |path| Dir.exist?(path) }
          expect(Dir.entries(datadir_path)).to include("common.yaml")
        end
      end
    end
  end

  context "winrm" do
    describe "basic" do
      let(:argv) { ["--winrm"] }
      it "creates a vagrantfile with the winrm communicator" do
        subject.execute
        expect(iso_env.vagrantfile.config.vm.communicator).to eq(:winrm)
        expect(iso_env.vagrantfile.config.winrm.username).to eq(described_class::DEFAULT_WINRM_USERNAME)
        expect(iso_env.vagrantfile.config.winrm.password).to eq(described_class::DEFAULT_WINRM_PASSWORD)
        expect(iso_env.vagrantfile.config.winrm.transport).to eq(:plaintext)
      end
    end

    describe "sspinegotiate" do
      let(:argv) { ["--winrm", "--servers", "server1"] }
      it "creates a vagrantfile with the winrm communicator" do
        subject.execute
        config = iso_env.vagrantfile.machine_config(:server1, :managed, nil)[:config]
        expect(config.winrm.transport).to eq(:sspinegotiate)
      end
    end

    describe "winrms" do
      let(:argv) { ["--winrm"] }
      it "includes the vagrant-winrm-s plugin"do
        subject.execute
        pluginsfile = File.readlines(File.join(iso_env.cwd, ".vagrantplugins")).join
        expect(pluginsfile).to include("vagrant-winrm-s")
      end
    end

    describe "username" do
      let(:argv) { ["--winrm", "--winrm-username", "WINRM_USERNAME"] }
      it "is parsed correctly" do
        subject.execute
        expect(iso_env.vagrantfile.config.winrm.username).to eq("WINRM_USERNAME")
      end
    end

    describe "password" do
      let(:argv) { ["--winrm", "--winrm-password", "WINRM_PASSWORD"] }
      it "is parsed correctly" do
        subject.execute
        expect(iso_env.vagrantfile.config.winrm.password).to eq("WINRM_PASSWORD")
      end
    end
  end

  context "ssh" do
    describe "default" do
      it "has default username and password" do
        subject.execute
        expect(iso_env.vagrantfile.config.ssh.username).to eq(described_class::DEFAULT_SSH_USERNAME)
        private_key_path = iso_env.vagrantfile.config.ssh.private_key_path.first
        expect(private_key_path).to eq(described_class::DEFAULT_SSH_PRIVATE_KEY_PATH)
      end
    end

    describe "username" do
      let(:argv) { ["--ssh-username", "SSH_USERNAME"] }
      it "is passed through" do
        subject.execute
        expect(iso_env.vagrantfile.config.ssh.username).to eq("SSH_USERNAME")
      end
    end

    describe "password" do
      let(:argv) { ["--ssh-password", "SSH_PASSWORD"] }
      it "is passed through" do
        subject.execute
        expect(iso_env.vagrantfile.config.ssh.password).to eq("SSH_PASSWORD")
      end
    end

    describe "private key path" do
      let(:argv) { ["--ssh-private-key-path", "SSH_PRIVATE_KEY_PATH"] }
      it "is passed through" do
        subject.execute
        expect(iso_env.vagrantfile.config.ssh.private_key_path.first).to eq("SSH_PRIVATE_KEY_PATH")
        expect(iso_env.vagrantfile.config.ssh.password).to be_nil
      end
    end
  end

  context "plugins" do
    describe "default" do
      it "has default plugins in .vagrantplugins" do
        subject.execute
        # Since the plugin stuff isn't part of the actual Vagrantfile spec, we'll
        # just peek at the text of the file
        pluginsfile = File.readlines(File.join(iso_env.cwd, ".vagrantplugins")).join
        described_class::DEFAULT_PLUGINS.each do |plugin|
          expect(pluginsfile).to include("required_plugins[\"#{plugin}\"]")
        end
      end
    end

    describe "specified plugins" do
      let(:argv) { ["--plugins", "plugin1,plugin2"] }
      it "are required" do
        subject.execute
        pluginsfile = File.readlines(File.join(iso_env.cwd, ".vagrantplugins")).join
        expect(pluginsfile).to include("required_plugins[\"plugin1\"]")
        expect(pluginsfile).to include("required_plugins[\"plugin2\"]")
      end
    end
  end

  context "servers" do
    describe "default" do
      it "has no servers in vagrantfile" do
        subject.execute
        vagrantfile = File.readlines(File.join(iso_env.cwd, "Vagrantfile")).join
        expect(vagrantfile).to include("managed_servers = %w( )")
      end
    end

    describe "specified servers" do
      let(:argv) { ["--servers", "server1,server2"] }
      it "are required" do
        subject.execute
        vagrantfile = File.readlines(File.join(iso_env.cwd, "Vagrantfile")).join
        expect(vagrantfile).to include("managed_servers = %w( server1 server2 )")
        expect(iso_env.vagrantfile.machine_config(:server1, :managed, nil)).to_not be_nil
        expect(iso_env.vagrantfile.machine_config(:server2, :managed, nil)).to_not be_nil
      end
    end
  end

  context "environments" do
    let(:argv) { ["--environments", "a,b,c"] }
    describe "vagrantfile" do
      it "should contain the loading code" do
        subject.execute
        vagrantfile = File.readlines(File.join(iso_env.cwd, "Vagrantfile")).join
        expect(vagrantfile).to include("managed_servers = VagrantPlugins::Orchestrate::Plugin.load_servers_for_branch")
      end
    end

    describe "servers.json" do
      it "should exist in the target directory" do
        subject.execute
        expect(Dir.entries(iso_env.cwd)).to include("servers.json")
      end
    end
  end

  context "git" do
    describe ".gitignore" do
      it "is written" do
        subject.execute
        expect(Dir.entries(iso_env.cwd)).to include(".gitignore")
      end

      it "contains ignored paths" do
        subject.execute
        contents = File.readlines(File.join(iso_env.cwd, ".gitignore")).join
        expect(contents).to include(".vagrant/")
      end
    end
  end

  context "box" do
    describe "dummy.box" do
      it "winds up in the target directory" do
        subject.execute
        expect(Dir.entries(iso_env.cwd)).to include("dummy.box")
      end
    end
  end

  context "orchestrate config" do
    describe "filter_managed_servers" do
      it "is set to true" do
        subject.execute
        expect(iso_env.vagrantfile.config.orchestrate.filter_managed_commands).to be true
      end
    end
  end
end
