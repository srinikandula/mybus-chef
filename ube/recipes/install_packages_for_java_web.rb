# Recipe name: install_packages_for_java_web
#
# This will install several packages needed by the jetty server and nginx.
#

# only run this recipe on a jetty layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:jetty_layer_name] rescue false

package "perl" do
  action :install
end

package "luajit" do
  action :install
end

# package "nginx" do
#   action :install
# end

package "nginx-extras" do
  action :install
end

package "zip" do
  action :install
end

package "s3cmd" do
  action :install
end

template "/etc/s3cfg" do
  source "s3cfg.erb"
  owner "root"
  group "root"
  mode "0644"
end

include_recipe 'ube::config_nginx'
