# Recipe name: setup_node_config
#
# This will create/update the .ube_node_config.js file used by the node.js server
#

# only run this recipe if this instance is in the node.js layer
is_node_js = node[:opsworks][:instance][:layers].include? 'nodejs-app' rescue false
return unless is_node_js

redis_server_dns = node[:opsworks][:layers][:redis_hub][:instances].first[1][:private_dns_name] rescue nil
redis_host = redis_server_dns || node[:ube][:redis_host]
log "redis host: #{redis_host}"

template "/etc/.ube_node_config.js" do  
  source "ube_node_config.js.erb"
  owner "root"
  group "root"
  mode "0644"
  variables({:redis_host => redis_host, :redis_port => node[:ube][:redis_port]})
end
  

