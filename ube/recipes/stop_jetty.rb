# Recipe name: stop_jetty
#
# This will stop the jetty server.
#

# only run this recipe on a jetty layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:jetty_layer_name] rescue false

ube = node['ube']
scripts_dir = ube[:scripts_dir]

cookbook_file "#{scripts_dir}/stop_jetty.sh" do
  source "stop_jetty.sh"
  mode '0755'
end

execute "stop jetty" do
  command "bash #{scripts_dir}/stop_jetty.sh"
end
