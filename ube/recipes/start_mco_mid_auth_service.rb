# Recipe name: start_mco_mid_auth_service
#
# This will start the MCO-MID Auth Service.  If it is already running,
# this will exit with an error.
#

# only run this recipe on a mco-mid auth service layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:mco_mid_auth_service_layer_name] rescue false

auth_service = node[:mco_mid_auth_service]
ube = node[:ube]
ubuntu_home = ube[:ubuntu_home]

auth_service_deployments_dir = auth_service['mco_mid_auth_service_deployments_dir']

auth_service_archive_dest_dir = "#{auth_service_deployments_dir}/#{ube['build_number']}"

link 'create a symlink to the current installation dir for the MCO-MID Auth Service' do
  target_file "#{ubuntu_home}/mco-mid-auth-service"
  link_type :symbolic
  to auth_service_archive_dest_dir
end

# start new
execute "start new server" do
  command "#{ubuntu_home}/scripts/bin/start_mco_mid_auth_service.rb #{auth_service_archive_dest_dir}"
end