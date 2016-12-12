# Recipe name: install_packages_for_teamcity_server
#
# This will install packages needed by the TeamCity server
#

#only run this recipe on a teamcity server layer
#opsworks databag reference: http://docs.aws.amazon.com/opsworks/latest/userguide/data-bags.html
search('aws_opsworks_layer').each do |layer|
  Chef::Log.info("layer: #{layer.inspect}")
end

return unless search('aws_opsworks_layer').any? { |l| l['shortname'] == node[:ube][:teamcity_server_layer_name] }

# return unless node[:opsworks][:instance][:layers].include? node[:ube][:teamcity_server_layer_name] rescue false

packages_to_install = %w(zip libxpm4 libxrender1 libgtk2.0-0 libnss3 libgconf-2-4
                        xvfb gtk2-engines-pixbuf
                        xfonts-cyrillic xfonts-100dpi xfonts-75dpi xfonts-base xfonts-scalable
                        imagemagick x11-apps x11vnc ruby2.0 ruby2.0-dev build-essential)

packages_to_install.each do |pkg|
  package pkg do
    action :install
  end
end

include_recipe 'aws'  # install right_aws gem for aws_s3_file
firefox_installation_deb = node[:ube][:teamcity][:firefox_installation_deb]
installation_files_s3_bucket = node[:ube][:teamcity][:installation_file_s3_bucket]
firefox_deb_local_dest = "/tmp/#{firefox_installation_deb}"


# For selenium testing, FireFox v 42.0 is required, so we can't use the default ubuntu package.
remote_file "/tmp/#{firefox_installation_deb}" do
  source "https://#{installation_files_s3_bucket}.s3.amazonaws.com:443/#{firefox_installation_deb}"
  mode '0644'
  action :create_if_missing
end


bash 'install FireFox .deb package' do
  code <<-EOH
    dpkg -i #{firefox_deb_local_dest}
    apt-get install -f
    echo "user_pref("app.update.enabled", false);" > /opt/firefox/defaults/pref/shodogg-prefs.js
  EOH
  not_if '[[ $(which firefox) != "" ]] && [[ "$(firefox -v)" =~ 42\.0 ]]'
end


# Good link on installing packages needed for headless selenium testing:
# https://gist.github.com/alonisser/11192482

# Make sure that Xvfb starts everytime the box/vm is booted:
# echo "Starting X virtual framebuffer (Xvfb) in background..."
# Xvfb -ac :99 -screen 0 1280x1024x16 &
#     export DISPLAY=:99

# Optionally, capture screenshots using the command:
#xwd -root -display :99 | convert xwd:- screenshot.png


# https://nodejs.org/en/download/package-manager/
bash 'install node and npm' do
  code <<-EOH
    curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
    sudo apt-get install -y nodejs
    sudo apt-get install -y build-essential
  EOH
  not_if '[[ $(which node) != "" ]] && [[ "$(node -v)" =~ v0\.12\.[0-9]+ ]]'
end

npm_packages_to_install = %w(forever gulp mocha node-gyp eslint@3.0.0)

npm_packages_to_install.each do |npm_package|
  execute "npm - install '#{npm_package}'" do
    command "npm install #{npm_package} -g"
  end
end

execute 'install gems' do
  command 'gem install sass'
end

# http://linuxg.net/how-to-install-gradle-2-1-on-ubuntu-14-10-ubuntu-14-04-ubuntu-12-04-and-derivatives/
bash 'install gradle from ppa' do
  code <<-EOH
    add-apt-repository -y ppa:cwchien/gradle
    apt-get update
    apt-get -y install gradle
  EOH
end
