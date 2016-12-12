# Recipe name: mongo_db_migrate
#
# This will download the bin + DB zip file for specified build number, extract it,
# and execute DB migrations against the database running on localhost.
#
# It will also run the import_hp_styles recipe, which imports the skinning/branding.
#

# only run this recipe on a mongo master layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:mongo_master_layer_name] rescue false

include_recipe 'ube::install_packages_for_mongo'

scripts_dir = node[:ube]['scripts_dir']
ube_deployments_dir = node[:ube]['deployments_dir']

directory "#{scripts_dir}" do
  action :create
end

directory "#{ube_deployments_dir}" do
  action :create
  mode '0755'
end

cookbook_file "#{scripts_dir}/db_download_and_run_migrations.sh" do
  source "db_download_and_run_migrations.sh"
  mode '0755'
end

execute "download, extract, and run migrations" do
  command "bash #{scripts_dir}/db_download_and_run_migrations.sh #{node[:ube]['build_number']}"
end

# include_recipe 'ube::import_hp_styles'
include_recipe 'ube::import_style_templates'
include_recipe 'ube::seed_mongo_data'
