require "vagrant-orchestrate/command/init"
require "vagrant-spec/unit"
require "pp"

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

  context "puppet provisioner" do
    describe "basic operation" do
      let(:argv) { ["--provision-with", "puppet"] }
      it "creates a vagrantfile with a puppet provisioner" do
        subject.execute
        expect(iso_env.vagrantfile.config.vm.provisioners.first.type).to eq(:puppet)
      end
    end

    describe "shorthand" do
      let(:argv) { ["--puppet"] }
      it "creates a vagrantfile with a puppet provisioner" do
        subject.execute
        expect(iso_env.vagrantfile.config.vm.provisioners.first.type).to eq(:puppet)
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
        expect(iso_env.vagrantfile.config.ssh.password).to eq(described_class::DEFAULT_SSH_PASSWORD)
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
      end
    end
  end

  context "plugins" do
    describe "default" do
      it "has default plugins in vagrantfile" do
        subject.execute
        # Since the plugin stuff isn't part of the actual Vagrantfile spec, we'll
        # just peek at the text of the file
        vagrantfile = File.readlines(File.join(iso_env.cwd, "Vagrantfile")).join
        expect(vagrantfile).to include("required_plugins = %w( #{described_class::DEFAULT_PLUGINS.join(' ')} )")
      end
    end

    describe "specified plugins" do
      let(:argv) { ["--plugins", "plugin1,plugin2"] }
      it "are required" do
        subject.execute
        expected = "required_plugins = %w( #{described_class::DEFAULT_PLUGINS.join(' ')} plugin1 plugin2 )"
        vagrantfile = File.readlines(File.join(iso_env.cwd, "Vagrantfile")).join
        expect(vagrantfile).to include(expected)
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
      end
    end
  end
end
