# Recipe name: deploy_mco_mid_auth_service
#
# This will download and deploy the MCO-MID Auth Service
#

# only run this recipe on a mco-mid auth service layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:mco_mid_auth_service_layer_name] rescue false

auth_service = node[:mco_mid_auth_service]
ube = node[:ube]

include_recipe 'aws'  # install right_aws gem for aws_s3_file
include_recipe 'ube::deploy_scripts'

aws_access_key_token = node[:ube][:s3_access_key]
aws_secret_key = node[:ube][:s3_secret_key]
auth_service_deployments_dir = auth_service['mco_mid_auth_service_deployments_dir']
auth_service_archive_dest_dir = "#{auth_service_deployments_dir}/#{ube['build_number']}"
auth_service_archive_dest_file = "#{auth_service_archive_dest_dir}.zip"
auth_service_archive_s3_path = "ube-archives/mid-auth-service-#{ube['build_number']}.zip"

directory "#{auth_service_deployments_dir}" do
  action :create
  mode '0755'
end

directory "#{auth_service_archive_dest_dir}" do
  action :create
  mode '0755'
end

directory "#{auth_service_archive_dest_dir}/log" do
  action :create
  mode '0755'
end

aws_s3_file "#{auth_service_archive_dest_file}" do
  action :create_if_missing
  bucket "#{ube['s3_deployment_archives_bucket']}"
  remote_path "#{auth_service_archive_s3_path}"
  aws_access_key_id aws_access_key_token
  aws_secret_access_key aws_secret_key
end


execute "unzip portal socket archive" do
  cwd auth_service_archive_dest_dir
  command "unzip -o #{auth_service_archive_dest_file}"
end

# npm install
execute "npm - install dependencies" do
  cwd auth_service_archive_dest_dir
  command "npm install"
end

# stop old
include_recipe 'ube::stop_mco_mid_auth_service'

include_recipe 'ube::setup_mco_mid_auth_service_config_files'

# start new
include_recipe 'ube::start_mco_mid_auth_service'
