require "vagrant-orchestrate/command/root"
require "vagrant-orchestrate/command/init"
require "vagrant-spec/unit"

describe VagrantPlugins::Orchestrate::Command::Root do
  include_context "vagrant-unit"

  let(:argv) { [] }
  let(:iso_env) do
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env ui_class: Vagrant::UI::Basic
  end

  subject { described_class.new(argv, iso_env) }

  ["", "-h", "--help"].each do |arg|
    describe "root help message #{arg}" do
      let(:argv) { [arg] }
      it "shows help" do
        output = capture_stdout { subject.execute }
        expect(output).to \
          include("Usage: vagrant orchestrate <subcommand> [<args>]")
      end
    end
  end
end
