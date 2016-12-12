# Recipe name: config_ube_mongo_properties
#
# This will generate the .ube.mongo.properties files on a layer running the ube or the kinesis/redshift connector
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


primary_layer_name = node[:ube][:mongo_master_layer_name]
secondary_layer_name = node[:ube][:mongo_secondary_layer_name]
Chef::Log.info("primary_layer_name: '#{primary_layer_name}', secondary_layer_name: '#{secondary_layer_name}'")
primary_instances = (node['opsworks']['layers'][primary_layer_name]['instances'] rescue {}) || {}
Chef::Log.info("primary_instances: #{primary_instances}")
secondary_instances = (node['opsworks']['layers'][secondary_layer_name]['instances'] rescue {}) || {}
Chef::Log.info("secondary_instances: #{secondary_instances}")
all_mongo_instances = primary_instances.merge(secondary_instances)
Chef::Log.info("all_mongo_instances: #{all_mongo_instances}")

instances = []

all_mongo_instances.each do |name, instance|
  instances << {:host => instance['private_dns_name'], :port => node[:ube][:mongo_port]}
end


home_dirs_for_props_file.each do |directory|
  template "#{directory}/.ube.mongo.properties" do
    source "ube.mongo.properties.erb"
    owner "jetty"
    group "jetty"
    mode "0644"
    variables({
                  :mongo_port => node[:ube][:mongo_port],
                  # :mongo_host => mongo_host_name,
                  :mongo_db => node[:ube][:mongo_database],
                  :mongo_user => node[:ube][:mongo_user],
                  :mongo_password => node[:ube][:mongo_password],
                  :hosts => instances
              })
  end
end

