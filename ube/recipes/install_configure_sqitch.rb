# Recipe name: install_configure_sqitch
#
# installs and configures sqitch
# sudo apt-get update
# sudo apt-get install build-essential cpanminus perl perl-doc
# sudo cpanm --quiet --notest App::Sqitch
#


include_recipe 'apt'
include_recipe 'build-essential'

package "cpanminus" do
  action :install
end

package "perl" do
  action :install
end

package "perl-doc" do
  action :install
end

package "mysql-client-core-5.6" do
  action :install
end

#install mysql drivers for perl
package "libdbd-mysql-perl" do
  action :install
end

execute "install sqitch using 'cpanm'" do
  command "sudo cpanm --quiet --notest App::Sqitch"
end

execute "configure sqitch to use mysql client " do
  command "sqitch config --user engine.mysql.client `which mysql`"
end

aws_access_key_token = node[:ube][:s3_access_key]
aws_secret_key = node[:ube][:s3_secret_key]
scripts_dir = node[:ube]['scripts_dir']
ube_deployments_dir = node[:ube]['deployments_dir']

package "s3cmd" do
  action :install
end

template "/etc/s3cfg" do
  source "s3cfg.erb"
  owner "root"
  group "root"
  mode "0644"
end

package "zip" do
  action :install
end

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

Chef::Log.info("finished configuring sqitch")