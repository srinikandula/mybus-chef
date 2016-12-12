# Recipe name: create_admin_user
#
# This will create an admin user in the mongo database
#

ube = node['ube']
admin_user_seed_file_full_path = "#{ube[:seed_data_dir]}/admin-user.json"

directory "#{ube[:seed_data_dir]}" do
  action :create
end

# only run this recipe on a mongo master layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:mongo_master_layer_name] rescue false

cookbook_file "#{admin_user_seed_file_full_path}" do
  source "db/admin-user.json"
  mode '0644'
end

execute "mongoimport the admin user" do
  command "mongoimport --db #{ube[:mongo_database]} --collection user --file #{admin_user_seed_file_full_path} --jsonArray"
end

