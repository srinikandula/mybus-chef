# Recipe name: install_packages_for_mongo
#
# This will install packages needed by the server running mongo
#

# only run this recipe on a mongo master layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:mongo_master_layer_name] rescue false

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
