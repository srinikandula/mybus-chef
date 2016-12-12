# Recipe name: import_style_templates
#
# This will upsert branding/styling templates into the database
#

ube = node['ube']
ube_deployments_dir = node[:ube]['deployments_dir']
style_data_dir = "#{ube_deployments_dir}/ube-db-#{node[:ube]['build_number']}/db/data"

template_style_file = "#{style_data_dir}/recscreenTemplate1.json"

log "current instance's layers are: #{node[:opsworks][:instance][:layers].inspect}"
#[2013-11-15T17:25:56+00:00] INFO: current instance's layers are: ["mongo"]
log "The OpsWorks layer name for the mongo master is '#{node[:ube][:mongo_master_layer_name]}'"

# only run this recipe on a mongo master layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:mongo_master_layer_name] rescue false

[template_style_file].each do |style_file|
  log "About to import template styles from file: '#{style_file}'"
  collection_name = 'style_template'
  execute "mongoimport #{style_file}" do
    command "mongoimport --db #{ube[:mongo_database]} --collection #{collection_name} --file #{style_file} --upsert" 
  end
end

