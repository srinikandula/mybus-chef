# Recipe name: setup_jobrunner
#
# This will configure the Job Runner layer.
#
# It assumes ruby is already installed (since this is, afterall, a chef script).
# It installs a variety of other packages too, including redis.


# only run this recipe on Job Runner layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:job_runner_layer_name] rescue false

packages = %w(php5 php5-gd php5-curl htop mysql-client unzip diffutils s3cmd default-jre imagemagick cabextract)

packages.each do |p|
  apt_package "#{p}" do
    action :install
  end
end


if node['platform'] =~ /ubuntu/i && node['platform_version'].to_f >= 14.0 && node['platform_version'].to_f < 15.0
  Chef::Log.info("Adding in the ppa repository for ffmpeg")
  execute 'add PPA repo for ffmpeg' do
    command 'sudo add-apt-repository ppa:mc3man/trusty-media && sudo apt-get update'
  end
end

apt_package 'ffmpeg' do
  action :install
end

include_recipe 'redisio::default'
include_recipe 'redisio::install'
include_recipe 'redisio::enable'


package "nodejs" do
  action :install
end

# the nodejs package for the ubuntu 14.04 dist creates a binary in /usr/bin/nodejs instead of /usr/bin/node,
# which causes 'forever' to malfunction
link "/usr/bin/node" do
  action :create
  to '/usr/bin/nodejs'
end

package "npm" do
  action :install
end

execute "npm - install 'forever'" do
  command 'sudo npm install forever -g'
end

execute 'imagemagick configuration change to correctly handle transparency in PDFs' do
  command "[ -f /etc/ImageMagick/delegates.xml ] && sudo cp /etc/ImageMagick/delegates.xml /etc/ImageMagick/delegates.xml.backup && sudo sed --in-place 's/pngalpha/pnmraw/' /etc/ImageMagick/delegates.xml"
end

include_recipe 'ube::install_fonts'


execute 'install bundler' do
  command 'sudo gem install bundler'
end

template "/etc/s3cfg" do
  source "s3cfg.erb"
  owner "root"
  group "root"
  mode "0644"
end

cron "delete temp files from job runner" do
  command 'find /tmp -mtime +2 -exec rm {} \;'
  minute '1'
  hour '0,3,6,9,12,15,18,21'
end

execute 'setup ps-jr alias and RAILS_ENV' do
  command %q^grep "alias ps-jr" /etc/profile || cat << 'EOF' >> /etc/profile
alias ps-jr='ps -ef | grep -e " [s]cript/rails " -e "[r]esque-[0-9]"'
export RAILS_ENV=production
EOF
^
end
