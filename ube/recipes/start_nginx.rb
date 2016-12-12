# Recipe name: start_nginx
#
# This will start the nginx server.  This is intended only for 
# use on the jetty OpsWorks layers.
#

# only run this recipe on a jetty layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:jetty_layer_name] rescue false

include_recipe 'ube::config_nginx'

service "nginx" do
  action :start
  supports :status => true, :start => true, :stop => true, :restart => true
end