# Recipe name: deploy_war
#
# This will copy the war file for the specified build #
# to the server and extract it into the proper directory.
# It then shuts down jetty if necessary, configures it to
# use the new .war file, and then starts it back up again.
#

# only run this recipe on a jetty layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:jetty_layer_name] rescue false

ube = node['ube']
jetty_tmp_dir = ube[:jetty_tmp_dir]

include_recipe 'ube::copy_war_build'

service "jetty" do
  action :stop
end

include_recipe 'ube::start_jetty'