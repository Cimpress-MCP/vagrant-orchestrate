Vagrant::Spec::Acceptance.configure do |c|
  c.component_paths << File.join("acceptance")
  c.skeleton_paths << File.join("acceptance", "support-skeletons")
end
