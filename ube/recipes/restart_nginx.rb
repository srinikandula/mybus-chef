# Recipe name: restart_nginx
#
# This will restart the nginx service
#

# only run this recipe on a jetty layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:jetty_layer_name] rescue false

include_recipe 'ube::config_nginx'

service "nginx" do
  action :restart
  supports :status => true, :start => true, :stop => true, :restart => true
end