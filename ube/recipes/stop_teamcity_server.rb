# Recipe name: stop_teamcity_server
#
# This will STOP the TeamCity server and the agent using TeamCity's runAll.sh script, which
# is their recommended way for startup/shutdown.
#

#only run this recipe on a teamcity server layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:teamcity_server_layer_name] rescue false


execute 'start teamcity (as the teamcity user)' do
  cwd "#{node[:ube][:teamcity][:root_installation_dir]}/TeamCity/bin"
  command './runAll.sh stop'
end