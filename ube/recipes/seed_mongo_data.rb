# Recipe name: seed_mongo_data
#
# This will seed data into a fresh mongo database.
#

ube = node['ube']
seed_file_full_path = "#{ube[:seed_data_dir]}/mongo_seed_indexes_and_config.js"
scripts_dir = ube['scripts_dir']
ube_deployments_dir = ube['deployments_dir']

log "current instance's layers are: #{node[:opsworks][:instance][:layers].inspect}"
#[2013-11-15T17:25:56+00:00] INFO: current instance's layers are: ["mongo"]
log "The OpsWorks layer name for the mongo master is '#{node[:ube][:mongo_master_layer_name]}'"

log "Instance info: #{node[:opsworks][:instance].inspect}"

# only run this recipe on a mongo master layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:mongo_master_layer_name] rescue false

# -----------------------------------------------------------------------------
# Part 1 -- run the script for seeding indexes and other configuration settings
# -----------------------------------------------------------------------------

directory "#{scripts_dir}" do
  action :create
end

directory "#{ube_deployments_dir}" do
  action :create
  mode '0755'
end

directory "#{ube[:seed_data_dir]}" do
  action :create
end

cookbook_file "#{seed_file_full_path}" do
  source "mongo_seed_indexes_and_config.js"
  mode '0644'
end

log 'running seed data script...'

execute "run seed data script" do
  command "mongo #{ube[:mongo_database]} #{seed_file_full_path}"
end


# -----------------------------------------------------------------------------
# Part 2 -- run imports (upserts) for all files with seed data for collections
# -----------------------------------------------------------------------------

# first download the archive with the db seed data
scripts_dir = ube[:scripts_dir]
cookbook_file "#{scripts_dir}/bin_and_db_archive_download.sh" do
  source "bin_and_db_archive_download.sh"
  mode '0755'
end

build_number = node[:ube]['build_number']
log "attempting to download db archive for build #{build_number}"
# execute "download db archive" do
#   command "bash #{scripts_dir}/bin_and_db_archive_download.sh #{build_number}"
# end

archive_full_path = "#{ube_deployments_dir}/ube-db-#{build_number}/bin_and_db_migrations-#{build_number}.zip"

[ube_deployments_dir, "#{ube_deployments_dir}/ube-db-#{build_number}"].each do |dir|
  directory dir do
    owner 'root'
    group 'root'
    action :create
    mode "0755"
  end
end

aws_access_key_token = node[:ube][:s3_access_key]
aws_secret_key = node[:ube][:s3_secret_key]

include_recipe 'aws'  # install right_aws gem for aws_elastic_lb

aws_s3_file "#{archive_full_path}" do
  bucket "shodogg-repository"
  remote_path "ube-archives/bin_and_db_migrations-#{build_number}.zip"
  aws_access_key_id aws_access_key_token
  aws_secret_access_key aws_secret_key
end

ruby_block "check if zip file downloaded" do
  block do
    Chef::Log.debug "Archive '#{archive_full_path}' exists? #{::File.exists?(archive_full_path)}"
  end
end

execute "extract zip file" do
  command "unzip -uo #{archive_full_path}"
  cwd "#{ube_deployments_dir}/ube-db-#{build_number}"
  only_if { ::File.exists?(archive_full_path) }
end

log 'upserting seed data...'

json_data_dir = "#{ube_deployments_dir}/ube-db-#{build_number}/db/data/seed"
log "json_data_dir is #{json_data_dir}"

ruby_block "glob json seed files" do
  block do
    json_seed_files = ::Dir.glob("#{json_data_dir}/*.json")
    Chef::Log.debug("json_seed_files : #{json_seed_files.inspect}")
    json_seed_files.each do |collection_seed_file|
      Chef::Log.debug "About to import data from file: '#{collection_seed_file}'"
      collection_name = collection_seed_file[/.+\/(.+)\.json/, 1]
      output = `mongoimport --db #{ube[:mongo_database]} --collection #{collection_name} --file #{collection_seed_file} --upsert`
      Chef::Log.debug "output from mongoimport:  #{output}"
    end
  end
  action :create
end



