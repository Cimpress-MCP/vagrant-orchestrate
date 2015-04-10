require "vagrant-spec"

describe "vagrant orchestrate prompt", component: "orchestrate/prompt" do
  include_context "acceptance"

  before do
    environment.skeleton("prompt")
  end

  # Vagrant throws with the error message below if a prompt is encountered. We need
  # to make sure that non-push commands don't prompt
  # Vagrant is attempting to interface with the UI in a way that requires
  #     a TTY. Most actions in Vagrant that require a TTY have configuration
  #     switches to disable this requirement. Please do that or run Vagrant
  #     with TTY.
  it "doesn't prompt with non-push commands" do
    assert_execute("vagrant", "status")
  end

  # TODO: I wish there was a way to simulate prompting, but for now, that is left
  # to the user as a manual exercise.
end
