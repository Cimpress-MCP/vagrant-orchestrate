require "vagrant-spec"
require "vagrant-orchestrate/repo_status"

describe "vagrant orchestrate status", component: "orchestrate/status" do
  include_context "acceptance"

  TEST_REF = "050bfd9c686b06c292a9614662b0ab1bbf652db3"
  TEST_REMOTE_ORIGIN_URL = "http://github.com/Cimpress-MCP/vagrant-orchestrate.git"

  before do
    environment.skeleton("basic")
  end

  it "handles no status file gracefully" do
    # Make sure we're starting from a clean slate, rspec order isn't guaranteed.
    execute("vagrant", "ssh", "-c", "\"rm -rf /var/state/vagrant_orchestrate\" managed-1")
    # All commands are executed against a single machine to reduce variability
    result = execute("vagrant", "orchestrate", "status", "/managed-1/")
    expect(result.stdout).to include("Status unavailable.")
  end

  it "can push and retrieve status" do
    # Because vagrant-spec executes in a clean tmp folder, it isn't a git repo,
    # and the normal git commands don't work. We'll inject some test data using
    # environment variables. See vagrant-orchestrate/repo_status.rb for impl.
    ENV["VAGRANT_ORCHESTRATE_STATUS_TEST_REF"] = TEST_REF
    ENV["VAGRANT_ORCHESTRATE_STATUS_TEST_REMOTE_ORIGIN_URL"] = TEST_REMOTE_ORIGIN_URL
    ENV["VAGRANT_ORCHESTRATE_NO_GUARD_CLEAN"] = "true"
    execute("vagrant", "orchestrate", "push", "/managed-1/")
    result = execute("vagrant", "orchestrate", "status", "/managed-1/")
    status = VagrantPlugins::Orchestrate::RepoStatus.new
    # Punting on date. Can always add it later if needed
    expect(result.stdout).to include(status.ref)
    expect(result.stdout).to include(status.user)
  end
end
