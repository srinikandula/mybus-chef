# Recipe name: stop_social_celery
#
# This will stop the Celery Social Data Miner application.
#

# only run this recipe on a celery layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:celery_layer_name] rescue false

ube = node['ube']
ubuntu_home = ube[:ubuntu_home]
scripts_dir = "#{ubuntu_home}/chef-scripts"
app_name = ube[:social_celery_app_name]

celery_dir_for_current_build = "#{ubuntu_home}/social-celery"
pid_file = "#{ubuntu_home}/.social-celery/%n.pid"
worker_count = ube[:social_celery_worker_count] || 2

# this doesn't always work....
# command_line = "celery multi stopwait #{worker_count} -A #{app_name} --pidfile=#{pid_file}"
# execute 'stop all celery workers and wait for them to complete' do
#   cwd celery_dir_for_current_build
#   command command_line
#   only_if { ::Dir.exists?(celery_dir_for_current_build) }
# end


directory "#{scripts_dir}" do
  action :create
  mode '0755'
  owner 'ubuntu'
  group 'ubuntu'
  recursive true
end

cookbook_file "#{scripts_dir}/kill_celery_workers.sh" do
  source 'kill_celery_workers.sh'
  mode '0755'
end

execute 'kill all celery workers' do
  command "bash #{scripts_dir}/kill_celery_workers.sh"
end