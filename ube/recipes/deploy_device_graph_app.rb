# Recipe name: deploy_device_graph_app
#
# This will deploy the specified version of a device graph service.
#
# Required:
#   node[:ube][:dev_graph_app_name] - should be one of "collection", "query", or "queue"
#   ube[:device_graph][:cluster]
#   ube[:device_graph][:cluster_region]
#   ube[:build_number]
#   ube[:device_graph][:image_repo]
#
#


ube = node[:ube]


# include_recipe 'aws'  # install right_aws gem for aws_s3_file
include_recipe 'ube::deploy_scripts'

app_name = ube[:dev_graph_app_name]
raise "Invalid app name '#{app_name}'" unless app_name =~ /^collection|query|queue$/

service_name = ube[:device_graph][app_name][:service_name]
raise "Invalid service name '#{service_name}'" if service_name.to_s.strip.empty?

cluster_name = ube[:device_graph][:cluster]
raise "Invalid cluster name '#{cluster_name}'" if cluster_name.to_s.strip.empty?

image_repo = ube[:device_graph][app_name][:image_repo]
raise "Invalid image repo '#{image_repo}'" if image_repo.to_s.strip.empty?

build_number = ube[:build_number]
raise "Invalid build number '#{build_number}'" if build_number.to_s.strip.empty?

cluster_region = node[:ube][:device_graph][:cluster_region] rescue nil
raise "Invalid region for cluster: '#{cluster_region}'" if cluster_region.to_s.strip.empty?


package "jq" do
  action :install
end

include_recipe 'ube::install_aws_cli'

execute "update aws cli" do
  command "pip install --upgrade awscli"
end

ube_deployments_dir = ube['deployments_dir']
ube_scripts_deployments_dir = "#{ube_deployments_dir}/scripts"
scripts_archive_dest_dir = "#{ube_scripts_deployments_dir}/#{ube['build_number']}"

timeout_in_secs = ube[:device_graph][:deployment_timeout].to_i rescue 0
timeout_in_secs = 240 unless timeout_in_secs > 0

# bin/ecs/ecs-deploy.sh -a collection -n dev-graph-collector --cluster ube-dev-dg-cluster --build-number jmw8161058 --image 853097395290.dkr.ecr.us-east-1.amazonaws.com/dev-graph-collector:bjmw8161058
execute "execute deploy" do
  command "#{scripts_archive_dest_dir}/bin/ecs/ecs-deploy.sh -a #{app_name} -n #{service_name} --cluster #{cluster_name} --build-number #{build_number} --region #{cluster_region} --image #{image_repo}:b#{build_number} --timeout #{timeout_in_secs} --verbose"
end
