# Recipe name: start_jetty
#
# This will start up the jetty server.  If jetty is already running, it
# will be stopped first.
#

# only run this recipe on a jetty layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:jetty_layer_name] rescue false

ube = node['ube']
scripts_dir = ube[:scripts_dir]
war_file_full_path = ube[:war_file_full_path]
build_number = ube[:build_number]
ubuntu_etc_dir = ube[:ubuntu_etc_dir]
jetty_user_home = ube[:jetty_user_home]

include_recipe 'ube::setup_java_server_config_files'

cookbook_file "#{scripts_dir}/start_jetty.sh" do
  source "start_jetty.sh"
  mode '0755'
end

execute "start jetty" do
  command "bash #{scripts_dir}/start_jetty.sh #{war_file_full_path}"
end
