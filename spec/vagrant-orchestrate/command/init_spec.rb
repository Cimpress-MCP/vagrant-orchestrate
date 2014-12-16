require 'vagrant-orchestrate/command/init'
require 'vagrant-spec/unit'
require 'pp'

describe VagrantPlugins::Orchestrate::Command::Init do
  include_context 'vagrant-unit'

  let(:base_argv)     { ['-f'] }
  let(:argv)          { [] }
  let(:iso_env) do
    env = isolated_environment
    # We need to load an empty vagrantfile in order for things to be initialized
    # properly
    env.vagrantfile('')
    env.create_vagrant_env ui_class: Vagrant::UI::Basic
  end

  subject { described_class.new(base_argv + argv, iso_env) }

  ['-h', '--help'].each do |arg|
    describe "init help message #{arg}" do
      let(:argv) { ['init', arg] }
      it 'shows help' do
        output = capture_stdout { subject.execute }
        expect(output).to include('Usage: vagrant orchestrate init [options]')
      end
    end
  end

  describe 'no parameters' do
    it 'creates basic vagrantfile' do
      output = capture_stdout { subject.execute }
      expect(Dir.entries(iso_env.cwd)).to include('Vagrantfile')
    end
  end

  describe 'shell provisioner' do
    let(:argv) { ['--shell', '-f'] }
    it 'creates a vagrantfile with shell provisioner' do
      subject.execute
      expect(iso_env.vagrantfile.config.vm.provisioners.first.type).to eq(:shell)
    end
  end
end
