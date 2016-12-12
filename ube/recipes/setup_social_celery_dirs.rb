# Recipe name: setup_social_celery_dirs
#
# This will create directories needed by the Celery Social Data Miner application.
#

# only run this recipe on a celery layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:celery_layer_name] rescue false

ube = node['ube']
build_number = ube['build_number']
ubuntu_home = ube[:ubuntu_home]

ube_deployments_dir = ube['deployments_dir']
social_celery_dir = "#{ube_deployments_dir}/social-celery"
social_celery_deployments_dir = "#{social_celery_dir}/#{build_number}"


directory "#{social_celery_deployments_dir}" do
  action :create
  mode '0755'
  recursive true
end

directory "#{social_celery_deployments_dir}/log" do
  action :create
  mode '0755'
  owner 'ubuntu'
  group 'ubuntu'
  recursive true
end

# the ~ubuntu/.social-celery dir is used to hold pid files
directory "#{ubuntu_home}/.social-celery" do
  action :create
  mode '0755'
  owner 'ubuntu'
  group 'ubuntu'
  recursive true
end
