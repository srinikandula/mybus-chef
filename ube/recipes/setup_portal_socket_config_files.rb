# Recipe name: setup_portal_socket_config_files
#
# This will create/update the .ube_portal_socket_config.js file used by the node.js server
#

# only run this recipe on a portal socket layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:portal_socket_layer_name] rescue false

redis_server_dns = node[:opsworks][:layers][:redis_hub][:instances].first[1][:private_dns_name] rescue nil
redis_host = redis_server_dns || node[:ube][:redis_host]

template "/etc/.ube_portal_socket_config.js" do
  source "ube_portal_socket_config.js.erb"
  owner "root"
  group "root"
  mode "0644"
  variables({:redis_host => redis_host, :redis_port => node[:ube][:redis_port]})
end