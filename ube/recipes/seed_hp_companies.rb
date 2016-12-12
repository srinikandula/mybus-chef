# Recipe name: seed_hp_companies
#
# This will seed HP company data and 1 child company (Comport) into a fresh mongo database.
#

ube = node['ube']
seed_file_full_path = "#{ube[:seed_data_dir]}/seed_hp_company.js"

# only run this recipe on a mongo master layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:mongo_master_layer_name] rescue false

directory "#{ube[:seed_data_dir]}" do
  action :create
end

cookbook_file "#{seed_file_full_path}" do
  source "seed_hp_company.js"
  mode '0644'
end

execute "run seed data script" do
  command "mongo #{ube[:mongo_database]} #{seed_file_full_path}"
end
