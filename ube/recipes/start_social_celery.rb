# Recipe name: start_social_celery
#
# This will start the Celery Social Data Miner application.
#

# only run this recipe on a celery layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:celery_layer_name] rescue false

include_recipe 'ube::setup_social_celery_dirs'

ube = node['ube']
ubuntu_home = ube[:ubuntu_home]
app_name = ube[:social_celery_app_name]

# reconfigure
include_recipe 'ube::config_social_celery'

celery_dir_for_current_build = "#{ubuntu_home}/social-celery"
pid_file = "#{ubuntu_home}/.social-celery/%n.pid"
log_file = "#{celery_dir_for_current_build}/log/social-celery-%n%I.log"
worker_count = ube[:social_celery_worker_count] || 2
log_level = ube[:social_celery_log_level] || 'INFO'

command_line = "sudo -u ubuntu HOME=#{ubuntu_home} celery multi start #{worker_count} -A #{app_name} --loglevel=#{log_level} --pidfile=#{pid_file} --logfile=#{log_file} > /tmp/celery_worker_stderrout.log 2>&1"

Chef::Log.info "Starting up celery workers (from #{celery_dir_for_current_build}) with the following command: #{command_line}"

execute 'start up celery workers in background' do
  cwd celery_dir_for_current_build
  command command_line
  user 'ubuntu'
end
