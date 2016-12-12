# Recipe name: deploy_portal_socket
#
# This will download and deploy the portal socket application
#

# only run this recipe on a jetty layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:portal_socket_layer_name] rescue false

ube = node[:ube]


include_recipe 'aws'  # install right_aws gem for aws_s3_file
include_recipe 'ube::deploy_scripts'

aws_access_key_token = node[:ube][:s3_access_key]
aws_secret_key = node[:ube][:s3_secret_key]
ube_deployments_dir = ube['deployments_dir']
portal_socket_deployments_dir = "#{ube_deployments_dir}/portal-socket"
portal_socket_archive_dest_dir = "#{portal_socket_deployments_dir}/#{ube['build_number']}"
portal_socket_archive_dest_file = "#{portal_socket_archive_dest_dir}.zip"
portal_socket_archive_s3_path = "ube-archives/portal-socket-#{ube['build_number']}.zip"

directory "#{ube_deployments_dir}" do
  action :create
  mode '0755'
end

directory "#{portal_socket_deployments_dir}" do
  action :create
  mode '0755'
end

directory "#{portal_socket_archive_dest_dir}" do
  action :create
  mode '0755'
end

directory "#{portal_socket_archive_dest_dir}/log" do
  action :create
  mode '0755'
end

aws_s3_file "#{portal_socket_archive_dest_file}" do
  action :create_if_missing
  bucket "#{ube['s3_deployment_archives_bucket']}"
  remote_path "#{portal_socket_archive_s3_path}"
  aws_access_key_id aws_access_key_token
  aws_secret_access_key aws_secret_key
end


execute "unzip portal socket archive" do
  cwd portal_socket_archive_dest_dir
  command "unzip -o #{portal_socket_archive_dest_file}"
end

# npm install
execute "npm - install dependencies" do
  cwd portal_socket_archive_dest_dir
  command "npm install"
end

# stop old
include_recipe 'ube::stop_portal_socket_server'

include_recipe 'ube::setup_portal_socket_config_files'

# start new
include_recipe 'ube::start_portal_socket_server'
