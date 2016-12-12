# Recipe name: config_dev_graph_service
#
# Generates a config file for the device graph services and then copies
# it to the appropriate location on all ECS instances in the specified cluster.
#
# It requires the following properties to be passed in node[:ube]:
#
# build_number - the build number
# dev_graph_cluster_name - the AWS cluster name
# dev_graph_app_name - a string with value of 'collection', 'queue', or 'query'

build_number = node[:ube][:build_number] rescue nil
cluster_name = node[:ube][:device_graph][:cluster] rescue nil
cluster_region = node[:ube][:device_graph][:cluster_region] rescue nil
dev_graph_app_name = node[:ube][:dev_graph_app_name] rescue nil

valid_app_name_values = %w(collection query queue)
config_file_directory = '/root/device-graph-config'

raise 'cluster_region cannot be null' if cluster_region.to_s.empty?
raise 'build_number cannot be null' if build_number.to_s.empty?
raise 'cluster_name cannot be null' if cluster_name.to_s.empty?
raise "dev_graph_app_name must be one of #{valid_app_name_values}" unless valid_app_name_values.include?(dev_graph_app_name)


directory config_file_directory do
  action :create
  owner 'root'
end

# let the user put common values in the ube.device_graph object and specific overrides
# in ube.device_graph.[app_name]
dg = node[:ube][:device_graph].merge(node[:ube][:device_graph][dev_graph_app_name])

config_filename = "dev_graph_#{cluster_name}_#{dev_graph_app_name}_b#{build_number}.js"
config_filename_full_path = "#{config_file_directory}/#{config_filename}"

template "#{config_filename_full_path}" do
  source "dev_graph_service_config.js.erb"
  owner "root"
  group "root"
  mode "0644"
  variables({:verify_hmac_secret => dg[:verify_hmac_secret],
             :verify_ust_url => dg[:verify_ust_url],
             :port => dg[:port],
             :queue_write_raw_dg_data => dg[:queue_write_raw_dg_data],
             :queue_read_raw_dg_data => dg[:queue_read_raw_dg_data],
             :queue_apache_spark_exports => dg[:queue_apache_spark_exports],
             :queue_data_sync_user => dg[:queue_data_sync_user],
             :queue_data_sync_mco_app => dg[:queue_data_sync_mco_app],
             :queue_data_sync_tx_dev => dg[:queue_data_sync_tx_dev],
             :ssl_enabled => dg[:ssl_enabled],
             :ssl_private_key_filename => dg[:ssl_private_key_filename],
             :ssl_certificate_filename => dg[:ssl_certificate_filename],
             :db_host => dg[:db_host],
             :db_port => dg[:db_port],
             :db_user => dg[:db_user],
             :db_password => dg[:db_password],
             :db_name => dg[:db_name],
             :useTestEnvironment => dg[:useTestEnvironment]
            })
end


include_recipe 'ube::deploy_scripts'

ube_deployments_dir = node['ube']['deployments_dir']
ube_scripts_deployments_dir = "#{ube_deployments_dir}/scripts"
scripts_archive_dest_dir = "#{ube_scripts_deployments_dir}/#{build_number}"
config_file_remote_destination = "/root/#{config_filename}"
aws_access_key_token = node[:ube][:s3_access_key]
aws_secret_key = node[:ube][:s3_secret_key]

ssh_pem_file_location_local = '/root/ecs-device-graph-201607.pem'

aws_s3_file "#{ssh_pem_file_location_local}" do
  action :create_if_missing
  bucket 'shodogg-chef'
  remote_path 'pem/ecs-device-graph-201607.pem'
  mode '0400'
  aws_access_key_id aws_access_key_token
  aws_secret_access_key aws_secret_key
end


execute 'copy the newly generated config file to all instances in the cluster' do
  command "#{scripts_archive_dest_dir}/bin/ecs/copy_config_file_to_cluster.rb #{cluster_name} #{cluster_region} #{config_filename_full_path} #{config_file_remote_destination} #{ssh_pem_file_location_local} ec2-user"
end
