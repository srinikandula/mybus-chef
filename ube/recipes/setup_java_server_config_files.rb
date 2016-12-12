# Recipe name: setup_java_server_config_files
#
# This will install all configuration files needed for the UBE
#
# One significant thing to point out is the property node["ube"]["jetty_java_opts"],
# which you can use to set JVM options for Jetty.  This is very valuable if you wish to
# specify parameters such as Xmx or the log4j.properties file location.  For example,
# -Dlog4j.configuration=file:/home/ubuntu/log4j.properties
#

# only run this recipe on a jetty layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:jetty_layer_name] rescue false

ube = node[:ube]
ubuntu_etc_dir = ube[:ubuntu_etc_dir]
jetty_user_home = ube[:jetty_user_home]
jetty_home = ube[:jetty_home]
mongo_server_dns = (node[:opsworks][:layers][:mongo][:instances].first[1][:private_dns_name] rescue nil)
mongo_host_name = mongo_server_dns || ube[:mongo_host]
jetty_tmp_dir = ube[:jetty_tmp_dir].to_s.strip.empty? ? nil : ube[:jetty_tmp_dir]
ubuntu_home = ube[:ubuntu_home]
scripts_dir = "#{ubuntu_home}/chef-scripts"

log "mongo host: #{mongo_host_name}"

# log "mongo instance info: #{node[:opsworks][:layers][:mongo][:instances].first.inspect rescue nil}"
# example output -- notice that the result is a 2-element array:
# mongo instance info: ["mongo1-opsworks", {"status"=>"online", "private_dns_name"=>"ip-10-28-120-36.ec2.internal", "availability_zone"=>"us-east-1a", "id"=>"f741a3fd-a647-4d8d-8efd-14b38da11080", "ip"=>"54.224.196.45", "booted_at"=>"2013-11-05T14:21:20+00:00", "created_at"=>"2013-10-11T18:27:50+00:00", "instance_type"=>"m1.small", "region"=>"us-east-1", "private_ip"=>"10.28.120.36", "elastic_ip"=>nil, "backends"=>5, "aws_instance_id"=>"i-990359e1", "public_dns_name"=>"ec2-54-224-196-45.compute-1.amazonaws.com"}]

directory "#{ubuntu_etc_dir}" do
  action :create
end

directory "#{jetty_user_home}" do
  action :create
  owner "jetty"
  group "jetty"
  mode "0755"
end

directory "#{jetty_tmp_dir}" do
  action :delete
  recursive true
end

directory "#{jetty_tmp_dir}" do
  action :create
  owner "jetty"
  group "jetty"
  mode "0777"
end

include_recipe 'ube::config_ube_mongo_properties'
include_recipe 'ube::config_ube_redis_properties'
include_recipe 'ube::config_ube_redshift_properties'

websocket_server_dns = node[:websocket_elb] || node[:opsworks][:layers]['nodejs-app'][:instances].first[1][:public_dns_name] rescue nil
websocket_host = websocket_server_dns || ube[:websocket_host]
log "websocket_host: #{websocket_host}"


template "/etc/s3cfg" do
  source "s3cfg.erb"
  owner "root"
  group "root"
  mode "0644"
end

template "#{jetty_user_home}/.aws.properties" do
  source "aws.properties.erb"
  owner "jetty"
  group "jetty"
  mode "0644"
end

template "#{jetty_user_home}/.crocodoc.properties" do
  source "crocodoc.properties.erb"
  owner "jetty"
  group "jetty"
  mode "0644"
end

include_recipe 'ube::setup_app_config_props'

template "#{ubuntu_etc_dir}/ube-jetty.xml" do
  source "ube-jetty.xml.erb"
  owner "jetty"
  group "jetty"
  mode "0644"
  variables({
    :jetty_tmp_dir => jetty_tmp_dir
  })
end

template "#{jetty_home}/etc/jetty-rewrite.xml" do
  source "jetty-rewrite.xml.erb"
  owner "jetty"
  group "jetty"
  mode "0644"
end

template "#{jetty_home}/etc/jetty.conf" do
  source "jetty.conf.erb"
  owner "jetty"
  group "jetty"
  mode "0644"
end

template "#{jetty_home}/start.ini" do
  source "start.ini.erb"
  owner "jetty"
  group "jetty"
  mode "0644"
end

template "#{jetty_user_home}/log4j.properties" do
  source "log4j.properties.erb"
  owner "jetty"
  group "jetty"
  mode "0644"
end

directory "#{scripts_dir}" do
  action :create
  mode '0755'
  owner "ubuntu"
  group "ubuntu"
end

cookbook_file "#{scripts_dir}/set_jetty_java_options.sh" do
  source "set_jetty_java_options.sh"
  mode '0755'
end

if ube.has_key?('jetty_java_opts')
  execute 'setup jetty JAVA_OPTIONS' do
    command "bash #{scripts_dir}/set_jetty_java_options.sh #{ube['jetty_java_opts']}"
  end
end

include_recipe 'ube::setup_rabbitmq_properties'
