# Recipe name: start_portal_socket_server
#
# This will start the portal socket server application.  If it is already running,
# this will exit with an error.
#

# only run this recipe on a portal socket server layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:portal_socket_layer_name] rescue false

ube = node[:ube]
ubuntu_home = ube[:ubuntu_home]

ube_deployments_dir = ube['deployments_dir']
portal_socket_deployments_dir = "#{ube_deployments_dir}/portal-socket"
portal_socket_archive_dest_dir = "#{portal_socket_deployments_dir}/#{ube['build_number']}"

# start new
execute "start new server" do
  command "#{ubuntu_home}/scripts/bin/start_portal_socket.rb #{portal_socket_archive_dest_dir}"
end