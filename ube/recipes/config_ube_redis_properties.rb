# Recipe name: config_ube_redis_properties
#
# This will generate the .ube.redis.properties files on a layer running the ube or the kinesis/redshift connector
#

# only run this recipe on a jetty layer or analytics layer
is_jetty_layer = node[:opsworks][:instance][:layers].include? node[:ube][:jetty_layer_name] rescue false
is_analytics_layer = node[:opsworks][:instance][:layers].include? node[:ube][:analytics_layer_name] rescue false

return unless is_jetty_layer || is_analytics_layer

ube = node[:ube]
jetty_user_home = ube[:jetty_user_home]
ubuntu_user_home = ube[:ubuntu_home]

home_dirs_for_props_file = []
home_dirs_for_props_file << jetty_user_home if is_jetty_layer
home_dirs_for_props_file << ubuntu_user_home if is_analytics_layer


redis_server_dns = node[:opsworks][:layers][:redis_hub][:instances].first[1][:private_dns_name] rescue nil
redis_host = redis_server_dns || node[:ube][:redis_host]
log "redis host: #{redis_host}"
unless redis_server_dns.nil?
  template "#{jetty_user_home}/.ube.redis.properties" do
    source "ube.redis.properties.erb"
    owner "jetty"
    group "jetty"
    mode "0644"
    variables({
                  :redis_host => redis_host,
                  :redis_port => node[:ube][:redis_port],
                  :hosts => []
              })
  end
end

if redis_server_dns.nil?
  master_layer_name = node[:ube][:redis_master_layer_name]
  slave_layer_name = node[:ube][:redis_slave_layer_name]
  Chef::Log.info("master_layer_name: '#{master_layer_name}', slave_layer_name: '#{slave_layer_name}'")
  master_instances = (node['opsworks']['layers'][master_layer_name]['instances'] rescue {}) || {}
  Chef::Log.info("master_instances: #{master_instances}")
  slave_instances = (node['opsworks']['layers'][slave_layer_name]['instances'] rescue {}) || {}
  Chef::Log.info("slave_instances: #{slave_instances}")
  all_redis_instances = master_instances.merge(slave_instances)
  Chef::Log.info("all_redis_instances: #{all_redis_instances}")

  instances = []

  all_redis_instances.each do |name, instance|
    instances << {:host => instance['private_ip'], :port => node[:ube][:redis_sentinel_port]}
  end


  home_dirs_for_props_file.each do |directory|
    template "#{directory}/.ube.redis.properties" do
      source "ube.redis.properties.erb"
      owner "jetty"
      group "jetty"
      mode "0644"
      variables({
                    :redis_sentinel_name => node[:ube][:redis_sentinel_name],
                    :hosts => instances
                })
    end
  end
end
