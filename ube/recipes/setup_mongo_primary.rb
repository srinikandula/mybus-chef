# Recipe name: setup_mongo_primary
#
# This will configure the Mongo layer.
# It installs mongo and if necessary, configures it as a replica set
# based on the value in node['mongodb']['config']['replSet']
#
# It also includes the recipe ube::config_cron_jobs_for_mongo
#

# only run this recipe on a mongo master layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:mongo_master_layer_name] rescue false

directory "#{node[:ube][:ubuntu_home]}" do
  action :create
  owner "ubuntu"
  group "ubuntu"
  mode "0755"
end

cookbook_file "#{node[:ube][:ubuntu_home]}/mongo_backup.sh" do
  owner "ubuntu"
  group "ubuntu"
  source "mongo_backup.sh"
  mode 0755
end

include_recipe 'ube::config_cron_jobs_for_mongo' unless node[:ube][:skip_mongo_cron_jobs]

include_recipe 'mongodb::mongodb_org_3_repo'

if node['mongodb']['config']['replSet'].to_s.strip.empty?
  include_recipe 'mongodb::default'
else
  node.set[:mongodb][:replica_priority] = node[:ube][:mongo_primary_priority]
  include_recipe 'mongodb::replicaset'
end
