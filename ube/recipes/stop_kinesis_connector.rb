# Recipe name: stop_kinesis_connector
#
#

# only run this recipe on an analytics xformer layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:analytics_layer_name] rescue false


ube = node['ube']
build_number = ube[:build_number]

ube_deployments_dir = ube['deployments_dir']
ube_scripts_deployments_dir = "#{ube_deployments_dir}/scripts"
scripts_archive_dest_dir = "#{ube_scripts_deployments_dir}/#{build_number}"
scripts_bin_dir = "#{scripts_archive_dest_dir}/bin"

execute "stop kinesis-redshift connector" do
  command "bash #{scripts_bin_dir}/stop_kinesis_client.sh"
end