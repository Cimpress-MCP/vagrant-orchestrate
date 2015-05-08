require "vagrant-spec"

describe "vagrant orchestrate provision", component: "orchestrate/provision" do
  include_context "acceptance"

  # This unique string gets echo'd as part of the provisioning process, so we
  # can check the output for this string. See ../support-skeletons/provision/Vagrantfile
  # for more info.
  PROVISION_STRING = "6etrabEmU8ru8hapheph"

  before do
    environment.skeleton("provision")
  end

  it "Runs the shell provisioner" do
    result = execute("vagrant", "orchestrate", "push", "managed-1")
    expect(result.stdout).to include(PROVISION_STRING)
  end

  it "Doesn't run with --no-provision" do
    result = execute("vagrant", "orchestrate", "push", "managed-1", "--no-provision")
    expect(result.stdout).not_to include(PROVISION_STRING)
  end
end
