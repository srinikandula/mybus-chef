# Recipe name: install_packages_for_kinesis
#
#

# only run this recipe on an analytics xformer layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:analytics_layer_name] rescue false

Chef::Log.info 'installing packages for the kinesis / analytics transformer layer'

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
