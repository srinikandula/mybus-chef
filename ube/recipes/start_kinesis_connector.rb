# Recipe name: start_kinesis_connector
#
#

# only run this recipe on an analytics xformer layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:analytics_layer_name] rescue false

include_recipe 'ube::setup_kinesis_connector_config_files'

ube = node['ube']
build_number = ube[:build_number]
ubuntu_home = ube[:ubuntu_home]

ube_deployments_dir = ube['deployments_dir']
ube_scripts_deployments_dir = "#{ube_deployments_dir}/scripts"
scripts_archive_dest_dir = "#{ube_scripts_deployments_dir}/#{build_number}"
scripts_bin_dir = "#{scripts_archive_dest_dir}/bin"

ube_kinesis_deployments_dir = "#{ube_deployments_dir}/kinesis-redshift-client"
archive_destination_dir = "#{ube_kinesis_deployments_dir}/#{ube['build_number']}"

link "create a symlink to the current installation dir for the kinesis client" do
  target_file "#{ubuntu_home}/kinesis-redshift-client"
  link_type :symbolic
  to archive_destination_dir
end

execute "start kinesis-redshift connector" do
  command "bash #{scripts_bin_dir}/start_kinesis_client.sh #{build_number}"
end