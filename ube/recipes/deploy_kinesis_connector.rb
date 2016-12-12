# Recipe name: deploy_kinesis_connector
#
# This recipe will download the kinesis code and the bin/scripts code for the
# specified build number.  It then extracts the archives.  It also creates
# (or updates) the configuration files that are read by the kinesis-redshift connector app.
#

# only run this recipe on an analytics xformer layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:analytics_layer_name] rescue false

include_recipe 'aws'  # install right_aws gem for aws_s3_file


ube = node['ube']
aws_access_key_token = node[:ube][:s3_access_key]
aws_secret_key = node[:ube][:s3_secret_key]
ube_deployments_dir = ube['deployments_dir']
ube_kinesis_deployments_dir = "#{ube_deployments_dir}/kinesis-redshift-client"
ube_scripts_deployments_dir = "#{ube_deployments_dir}/scripts"
archive_destination_dir = "#{ube_kinesis_deployments_dir}/#{ube['build_number']}"
archive_destination_file = "#{archive_destination_dir}.zip"
scripts_archive_dest_dir = "#{ube_scripts_deployments_dir}/#{ube['build_number']}"
scripts_archive_dest_file = "#{scripts_archive_dest_dir}.zip"
kinesis_archive_s3_path = "ube-archives/kinesis-redshift-client-#{ube['build_number']}.zip"
scripts_archive_s3_path = "ube-archives/bin_and_db_migrations-#{ube['build_number']}.zip"
ubuntu_home = ube[:ubuntu_home]

include_recipe 'ube::deploy_scripts'
include_recipe 'ube::setup_kinesis_connector_config_files'


directory "#{ube_deployments_dir}" do
  action :create
  mode '0755'
end

directory "#{ube_scripts_deployments_dir}" do
  action :create
  mode '0755'
  end

directory "#{scripts_archive_dest_dir}" do
  action :create
  mode '0755'
end

directory "#{ube_kinesis_deployments_dir}" do
  action :create
  mode '0755'
end

directory "#{archive_destination_dir}" do
  action :create
  mode '0755'
end


aws_s3_file "#{archive_destination_file}" do
  action :create_if_missing
  bucket "#{ube['s3_deployment_archives_bucket']}"
  remote_path "#{kinesis_archive_s3_path}"
  aws_access_key_id aws_access_key_token
  aws_secret_access_key aws_secret_key
end


execute "unzip kinesis-redshift client archive" do
  cwd archive_destination_dir
  command "unzip -o #{archive_destination_file}"
end


aws_s3_file "#{scripts_archive_dest_file}" do
  action :create_if_missing
  bucket "#{ube['s3_deployment_archives_bucket']}"
  remote_path "#{scripts_archive_s3_path}"
  aws_access_key_id aws_access_key_token
  aws_secret_access_key aws_secret_key
end

execute "unzip scripts archive" do
  cwd scripts_archive_dest_dir
  command "unzip -o #{scripts_archive_dest_file}"
end

link "create a symlink to the current installation dir for the scripts" do
  target_file "#{ubuntu_home}/scripts"
  link_type :symbolic
  to scripts_archive_dest_dir
end

include_recipe 'ube::stop_kinesis_connector'

include_recipe 'ube::start_kinesis_connector'