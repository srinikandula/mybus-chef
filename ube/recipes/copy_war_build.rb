# Recipe name: copy_war_build
#
# This will copy the war file for the specified build # from S3
# to the server and extracts it into the proper directory.
#

# only run this recipe on a jetty layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:jetty_layer_name] rescue false

ube = node['ube']
scripts_dir = ube['scripts_dir']
ube_deployments_dir = ube['deployments_dir']

directory "#{scripts_dir}" do
  action :create
end

directory "#{ube_deployments_dir}" do
  action :create
  mode '0755'
end

cookbook_file "#{scripts_dir}/copy_war_from_s3.sh" do
  source "copy_war_from_s3.sh"
  mode '0755'
end

execute "download and extract build" do
  command "bash #{scripts_dir}/copy_war_from_s3.sh #{ube['build_number']}"
end