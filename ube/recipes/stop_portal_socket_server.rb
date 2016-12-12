# Recipe name: stop_portal_socket_server
#
# This will stop the portal socket server application.
#

# only run this recipe on a jetty layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:portal_socket_layer_name] rescue false

ube = node[:ube]
ubuntu_home = ube[:ubuntu_home]

# stop old
execute "stop old server" do
  command "#{ubuntu_home}/scripts/bin/stop_portal_socket.rb"
end
