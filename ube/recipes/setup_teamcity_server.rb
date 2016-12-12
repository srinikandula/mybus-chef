# Recipe name: setup_teamcity_server
#
# This will install TeamCity and configure it
#

#only run this recipe on a teamcity server layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:teamcity_server_layer_name] rescue false


include_recipe 'aws'  # install right_aws gem for aws_s3_file

aws_access_key_token = node[:ube][:s3_access_key]
aws_secret_key = node[:ube][:s3_secret_key]
# https://s3.amazonaws.com/shodogg-repository/TeamCity-9.1.6.tar.gz

teamcity_installation_archive_s3_key = node[:ube][:teamcity][:installation_file]
teamcity_archive_s3_bucket = node[:ube][:teamcity][:installation_file_s3_bucket]
archive_name_no_path = teamcity_installation_archive_s3_key.split('/')[-1]
tc_local_tarball = "/tmp/#{archive_name_no_path}"
tc_base_inst_dir = node[:ube][:teamcity][:root_installation_dir]
tc_installation_dir = node[:ube][:teamcity][:app_root]
teamcity_user = node[:ube][:teamcity][:teamcity_user]
teamcity_group = node[:ube][:teamcity][:teamcity_user_group]
teamcity_user_home = "/home/#{teamcity_user}"
tc_data_directory = node[:ube][:teamcity][:data_directory]


aws_s3_file "#{tc_local_tarball}" do
  action :create_if_missing
  bucket teamcity_archive_s3_bucket
  remote_path teamcity_installation_archive_s3_key
  aws_access_key_id aws_access_key_token
  aws_secret_access_key aws_secret_key
end


execute 'unzip TeamCity installation tarball' do
  cwd '/tmp'
  command "tar xvzf #{tc_local_tarball} -C #{tc_base_inst_dir}"
  only_if { ::Dir["#{tc_installation_dir}/*"].empty? }
end

# execute 'change ownership of TeamCity installation to teamcity user' do
#   command "chown -R #{teamcity_user}:#{teamcity_group} #{tc_base_inst_dir}"
# end

execute 'change ownership of TeamCity installation to proper user' do
  command "chown -R #{teamcity_user}:#{teamcity_group} #{tc_base_inst_dir}"
end

# Startup the TeamCity server only if this is not a fresh installation.
# If the data directory exists and is not empty, then this recipe will interpret
# that as a TeamCity instance that has already been installed and configured.
unless ::Dir["#{tc_data_directory}/*"].empty?
  Chef::Log::debug("TeamCity data directory (#{tc_data_directory}) was found and is not empty, so TeamCity will be started.")
  include_recipe 'ube::start_teamcity_server'
end


include_recipe 'ube::setup_rabbitmq_properties_teamcity'

template "#{teamcity_user_home}/.s3cfg" do
  source "s3cfg.erb"
  owner teamcity_user
  group teamcity_group
  mode '0600'
end


directory "#{teamcity_user_home}/.aws" do
  action :create
  owner teamcity_user
  group teamcity_group
  mode '0755'
end

teamcity_aws_access_key = node[:ube][:teamcity][:aws_access_key]
teamcity_aws_secret_key = node[:ube][:teamcity][:aws_secret_key]
teamcity_aws_default_region = node[:ube][:teamcity][:aws_default_region]


template "#{teamcity_user_home}/.aws/credentials" do
  source 'aws_cli_credentials.erb'
  owner teamcity_user
  group teamcity_group
  mode '0600'
  variables({
    :access_key => teamcity_aws_access_key,
    :secret_key => teamcity_aws_secret_key
  })
end

template "#{teamcity_user_home}/.aws/config" do
  source 'aws_cli_config.erb'
  owner teamcity_user
  group teamcity_group
  mode '0600'
  variables({
      :region => teamcity_aws_default_region
  })
end