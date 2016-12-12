# Recipe name: deploy_social_celery
#
# This will deploy the Celery Social Data Miner application.
#

# only run this recipe on a celery layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:celery_layer_name] rescue false

include_recipe 'aws'  # install right_aws gem for aws_s3_file
include_recipe 'ube::deploy_scripts'

ube = node['ube']
build_number = ube['build_number']
ubuntu_home = ube[:ubuntu_home]

ube_deployments_dir = ube['deployments_dir']
social_celery_dir = "#{ube_deployments_dir}/social-celery"
social_celery_deployments_dir = "#{social_celery_dir}/#{build_number}"
social_celery_archive_name = "social-celery-#{build_number}.zip"
social_celery_archive_dest_file = "#{social_celery_deployments_dir}/#{social_celery_archive_name}"

aws_access_key_token = node[:ube][:s3_access_key]
aws_secret_key = node[:ube][:s3_secret_key]

social_celery_archive_s3_path = "ube-archives/#{social_celery_archive_name}"

include_recipe 'ube::setup_social_celery_dirs'

aws_s3_file "#{social_celery_archive_dest_file}" do
  action :create_if_missing
  bucket "#{ube['s3_deployment_archives_bucket']}"
  remote_path "#{social_celery_archive_s3_path}"
  aws_access_key_id aws_access_key_token
  aws_secret_access_key aws_secret_key
end


execute "unzip portal socket archive" do
  cwd social_celery_deployments_dir
  command "unzip -o #{social_celery_archive_dest_file}"
end


# stop the old one
include_recipe 'ube::stop_social_celery'


link "create a symlink to the new installation dir for social celery app" do
  target_file "#{ubuntu_home}/social-celery"
  link_type :symbolic
  to social_celery_deployments_dir
end


# reconfigure
include_recipe 'ube::config_social_celery'

# start up the new one
include_recipe 'ube::start_social_celery'

