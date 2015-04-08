require "vagrant-spec"

describe "vagrant orchestrate push", component: "orchestrate/push" do
  include_context "acceptance"

  before do
    environment.skeleton("basic")
  end

  it "can push to a set of managed servers" do
    assert_execute("vagrant", "orchestrate", "push")
  end

  describe "strategies" do
    it "can push in parallel" do
      assert_execute("vagrant", "orchestrate", "push", "--strategy", "parallel")

      machine_names = (1..4).collect { |i| "managed-#{i}" }
      datetimes = get_sync_times(machine_names)
      execute("vagrant", "destroy", "-f")

      # Parallel provisioning should happen within a few seconds.
      ensure_datetimes_within(datetimes, 5)
    end

    it "can push with carary strategy" do
      assert_execute("vagrant", "orchestrate", "push", "--strategy", "canary", "-f")
      canary = get_sync_times(["managed-1"]).first
      the_rest = get_sync_times((2..4).collect { |i| "managed-#{i}" })
      execute("vagrant", "destroy", "-f")
      ensure_datetimes_within(the_rest, 5)
      expect(diff_seconds(canary, the_rest.min)).to be >= 3
    end

    it "can push with half_half strategy" do
      assert_execute("vagrant", "orchestrate", "push", "--strategy", "half_half", "-f")
      first_half = get_sync_times(["managed-1", "managed-2"])
      second_half = get_sync_times(["managed-3", "managed-4"])
      execute("vagrant", "destroy", "-f")
      ensure_datetimes_within(first_half, 5)
      ensure_datetimes_within(second_half, 5)
      expect(diff_seconds(first_half.max, second_half.min)).to be >= 3
    end

    it "can push with carary_half_half strategy" do
      assert_execute("vagrant", "orchestrate", "push", "--strategy", "canary_half_half", "-f")
      canary = get_sync_times(["managed-1"]).first
      first_half = get_sync_times(["managed-2"])
      second_half = get_sync_times(["managed-3", "managed-4"])
      execute("vagrant", "destroy", "-f")
      ensure_datetimes_within(first_half, 5)
      expect(diff_seconds(canary, first_half.min)).to be > 3
      expect(diff_seconds(first_half.max, second_half.min)).to be >= 3
    end
  end

  def get_sync_times(machines)
    datetimes = []
    machines.each do |machine|
      execute("vagrant", "up", machine)
      # This file is written by the shell provisioner in ../support-skeletons/basic/Vagrantfile
      result = execute("vagrant", "ssh", "-c", "cat /tmp/sync_time", machine)
      datetimes << DateTime.parse(result.stdout.chomp)
    end
    datetimes
  end

  # Ensure that the range (max - min) of the datetime objects passed in are within
  # the given number of seconds.
  def ensure_datetimes_within(datetimes, seconds)
    expect(diff_seconds(datetimes.min, datetimes.max)).to be < seconds
  end

  # The difference between two datetimes in seconds
  def diff_seconds(start, finish)
    ((finish - start) * 86_400).to_i
  end
end
