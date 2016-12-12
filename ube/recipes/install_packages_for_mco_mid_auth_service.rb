# Recipe name: install_packages_for_mco_mid_auth_service
#
# This will install packages needed by the MCO-MID Auth Service
#

# only run this recipe on a mco-mid auth service layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:mco_mid_auth_service_layer_name] rescue false

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

