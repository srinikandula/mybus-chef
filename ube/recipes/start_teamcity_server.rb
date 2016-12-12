# Recipe name: start_teamcity_server
#
# This will start the TeamCity server (with one agent) on the same instance.
#

#only run this recipe on a teamcity server layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:teamcity_server_layer_name] rescue false

tc_env_vars = {
    'GRADLE_HOME' => '/usr/lib/gradle/default'
}

execute 'start teamcity (as the "not-opsworks" user, not root)' do
  cwd "#{node[:ube][:teamcity][:root_installation_dir]}/TeamCity/bin"
  user 'not-opsworks'
  environment tc_env_vars
  command './runAll.sh start'
end