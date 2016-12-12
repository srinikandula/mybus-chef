# Recipe name: stop_mco_mid_auth_service
#
# This will stop the MCO-MID Auth Service
#

# only run this recipe on a mco-mid auth service layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:mco_mid_auth_service_layer_name] rescue false

ube = node[:ube]
ubuntu_home = ube[:ubuntu_home]

# stop old
execute "stop old server" do
  command "#{ubuntu_home}/scripts/bin/stop_mco_mid_auth_service.rb"
end
