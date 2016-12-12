# Recipe name: deploy_scripts
#
# This recipe will download the bin/scripts code for the
# specified build number.  It then extracts the archives.  It also creates
# a symlink to the scripts for the current build, which is in ~ubuntu/scripts
#

include_recipe 'aws'  # install right_aws gem for aws_s3_file

ube = node['ube']
aws_access_key_token = node[:ube][:s3_access_key]
aws_secret_key = node[:ube][:s3_secret_key]
ube_deployments_dir = ube['deployments_dir']
ube_scripts_deployments_dir = "#{ube_deployments_dir}/scripts"
scripts_archive_dest_dir = "#{ube_scripts_deployments_dir}/#{ube['build_number']}"
scripts_archive_dest_file = "#{scripts_archive_dest_dir}.zip"
scripts_archive_s3_path = "ube-archives/bin_and_db_migrations-#{ube['build_number']}.zip"
ubuntu_home = ube[:ubuntu_home]

package "zip" do
  action :install
end

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
