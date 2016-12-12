# Recipe name: install_fonts
#
# This will install some TTF fonts into ubuntu
#

include_recipe 'aws'  # install right_aws gem for aws_s3_file

apt_package "s3cmd" do
  action :install
end

template "/etc/s3cfg" do
  source "s3cfg.erb"
  owner "root"
  group "root"
  mode "0644"
end


bash 'extract_module' do
  cwd '/tmp'
  code <<-EOH
    mkdir -p /tmp/ttf-fonts
    s3cmd get s3://shodogg-repository/pptviewer-fonts.tar.gz /tmp/ttf-fonts/pptviewer-fonts.tar.gz
    s3cmd get s3://shodogg-repository/hp-fonts/*.ttf /tmp/ttf-fonts
    sudo mkdir -p /usr/local/share/fonts/truetype
    tar -xvf pptviewer-fonts.tar.gz
    sudo cp /tmp/ttf-fonts/*.TTF /usr/local/share/fonts/truetype
    sudo cp /tmp/ttf-fonts/*.ttf /usr/local/share/fonts/truetype
    sudo fc-cache -fv
    touch /etc/.jobrunner-fonts-installed
  EOH
  not_if { ::File.exists?('/etc/.jobrunner-fonts-installed') }
end

