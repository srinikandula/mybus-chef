# Recipe name: install_packages_for_portal_socket
#
# This will install packages needed by the portal socket app
#

# only run this recipe on a portal socket layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:portal_socket_layer_name] rescue false

ube = node[:ube]

package "zip" do
  action :install
end

package "nodejs" do
  action :install
end

# the nodejs package for the ubuntu 14.04 dist creates a binary in /usr/bin/nodejs instead of /usr/bin/node,
# which causes 'forever' to malfunction
link "/usr/bin/node" do
  action :create
  to '/usr/bin/nodejs'
end

package "npm" do
  action :install
end

execute "npm - install 'forever'" do
  command "sudo npm install forever -g"
end

