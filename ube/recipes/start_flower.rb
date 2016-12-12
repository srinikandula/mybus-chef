# Recipe name: start_flower
#
# This will start flower on an instance that is part of the celery layer
#

# only run this recipe on a celery layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:celery_layer_name] rescue false

ube = node['ube']
ubuntu_home = ube[:ubuntu_home]
app_name = ube[:social_celery_app_name]

celery_dir_for_current_build = "#{ubuntu_home}/social-celery"

auth_user = ube[:social_celery_flower_auth_username]
auth_pw = ube[:social_celery_flower_auth_password]
basic_auth_params = "--basic_auth='#{auth_user}:#{auth_pw}'"

execute 'start flower and run in the background' do
  cwd celery_dir_for_current_build
  command "sudo -u ubuntu -H celery -A #{app_name} flower #{basic_auth_params} &"
  timeout 60
end