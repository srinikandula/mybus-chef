# Recipe name: deploy_jobrunner
#
# This will deploy the specified job runner build
#


# only run this recipe on Job Runner layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:job_runner_layer_name] rescue false


ube = node[:ube]

include_recipe 'aws'  # install right_aws gem for aws_s3_file
# include_recipe 'ube::deploy_scripts'

aws_access_key_token = node[:ube][:s3_access_key]
aws_secret_key = node[:ube][:s3_secret_key]

jr_deployments_dir = ube[:ubuntu_home]
root_home = '/root'

jr_build_number = ube[:job_runner][:build_number]
jr_build_number_dir = "#{jr_deployments_dir}/jobrunner-#{jr_build_number}"

jr_zip_file = "jobrunner-#{jr_build_number}.zip"
jr_archive_s3_path = "ube-archives/#{jr_zip_file}"
jr_archive_dest_file = "#{jr_deployments_dir}/jobrunner-#{jr_build_number}.zip"


# download build archive
aws_s3_file "#{jr_archive_dest_file}" do
  action :create_if_missing
  bucket "#{ube['s3_deployment_archives_bucket']}"
  remote_path "#{jr_archive_s3_path}"
  aws_access_key_id aws_access_key_token
  aws_secret_access_key aws_secret_key
end

directory "#{jr_build_number_dir}" do
  action :create
  mode '0755'
  owner 'ubuntu'
  group 'ubuntu'
end

# extract into dir named w/ build number
execute 'extract archive' do
  cwd "#{jr_deployments_dir}"
  command "unzip -q #{jr_zip_file} -d #{jr_build_number_dir}"
  not_if { ::Dir.exists?("#{jr_build_number_dir}/job_runner/vendor") }
end

execute 'copy over old /vendor gems' do
  cwd "#{jr_deployments_dir}/job_runner/vendor"
  command "cp -a #{jr_deployments_dir}/job_runner/vendor/ #{jr_build_number_dir}/job_runner/vendor/"
  only_if { ::Dir.exists?("#{jr_deployments_dir}/job_runner/vendor") && (::File.readlink("#{jr_deployments_dir}/job_runner") rescue nil) != "#{jr_build_number_dir}/job_runner" }
end

execute 'bundle install' do
  cwd "#{jr_build_number_dir}/job_runner"
  command 'bundle install'
end

# JR variables
jr = ube[:job_runner]

directory '/root/.aws' do
  action :create
  mode '0750'
  owner 'root'
  group 'root'
end

template '/root/.aws/credentials' do
  source 'aws.credentials.erb'
  owner 'root'
  group 'root'
  mode '0640'
end

# generate new config file for app_config.yml
template "#{jr_build_number_dir}/job_runner/config/app_config.yml" do
  source "job_runner_app_config.yml.erb"
  owner "ubuntu"
  group "ubuntu"
  mode "0640"
  variables({
                :callback_queue_method => jr[:callback_queue_method],
                :box_conversion_timeout => jr[:box_conversion_timeout],
                :box_polling_rate => jr[:box_polling_rate],
                :box_non_svg => jr[:box_non_svg],
                :box_enabled => jr[:box_enabled],
                :crocodoc_enabled => jr[:crocodoc_enabled],
                :crocodoc_pdf_enabled => jr[:crocodoc_pdf_enabled],
                :crocodoc_conversion_timeout => jr[:crocodoc_conversion_timeout],
                :crocodoc_polling_rate => jr[:crocodoc_polling_rate],
                :dashboard_username => jr[:dashboard_username],
                :dashboard_password => jr[:dashboard_password],
                :dropbox_consumer_key => jr[:dropbox_consumer_key],
                :dropbox_consumer_secret => jr[:dropbox_consumer_secret],
                :object_store_method => jr[:object_store_method],
                :job_runner_host => jr[:job_runner_host],
                :job_runner_port => jr[:job_runner_port],
                :max_request_retries => jr[:max_request_retries],
                :jaspersoft_host_url => jr[:jaspersoft_host_url],
                :jaspersoft_superuser_name => jr[:jaspersoft_superuser_name],
                :jaspersoft_superuser_password => jr[:jaspersoft_superuser_password]
            })
end


template "#{jr_build_number_dir}/job_runner/config/aws.yml" do
  source "aws.yml.erb"
  owner "ubuntu"
  group "ubuntu"
  mode "0640"
end

file "#{root_home}/.redis.queue.jobrunner.properties" do
  content "redis_incoming_queue_name=#{ube[:job_runner_outgoing_redis_queue_name] || 'xxx'}"
  owner 'ubuntu'
  group 'ubuntu'
  mode '0640'
end


file "#{root_home}/.box.properties" do
  content "api_key=#{ube[:box_api_key]}"
  owner 'ubuntu'
  group 'ubuntu'
  mode '0640'
end

include_recipe 'ube::stop_job_runner_all'

link "update/create a symlink in ~ubuntu/job_runner to point to the new current build" do
  target_file "#{jr_deployments_dir}/job_runner"
  link_type :symbolic
  to "#{jr_build_number_dir}/job_runner"
end


execute 'touch a config file' do
  cwd root_home
  command "touch .crocodoc.properties"
end

template "#{root_home}/.hp_cloud_job_runner.yml" do
  source "hp_cloud_job_runner.yml.erb"
  owner "ubuntu"
  group "ubuntu"
  mode "0640"
end


file "#{root_home}/.sqs.jobrunner.properties" do
  content "sqs_incoming_queue_name=#{ube[:aws_sqs_jobrunner_command_queue]}"
  owner 'ubuntu'
  group 'ubuntu'
  mode '0640'
end


# start up everything (except the stale worker monitoring script)
execute 'start up resque workers' do
  cwd "#{jr_deployments_dir}/job_runner"
  command './bin/start_all_with_forever_workers.sh'
end


# start up stale worker monitoring script
execute 'start up stale worker monitoring script' do
  cwd "#{jr_deployments_dir}/job_runner"
  command './bin/monitor_stale_workers.sh'
end
