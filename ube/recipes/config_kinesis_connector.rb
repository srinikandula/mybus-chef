# Recipe name: config_kinesis_connector
#
#

# only run this recipe on an analytics xformer layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:analytics_layer_name] rescue false

include_recipe 'ube::setup_kinesis_connector_config_files'
