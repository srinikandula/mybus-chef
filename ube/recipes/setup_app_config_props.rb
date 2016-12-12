# Recipe name: setup_app_config_props
#
# This will update the custom .ube.properties file used by jetty/kinesis connector.
# THIS IS ONLY FOR EITHER THE JETTY LAYER OR FOR THE ANALYTICS / KINESIS LAYER.  IT WORKS ON BOTH.
#

# only run this recipe on a jetty layer or analytics (kinesis->redshift) layer
is_jetty_layer = node[:opsworks][:instance][:layers].include? node[:ube][:jetty_layer_name] rescue false
is_analytics_layer = node[:opsworks][:instance][:layers].include? node[:ube][:analytics_layer_name] rescue false
return unless is_jetty_layer || is_analytics_layer

ube = node[:ube]
jetty_user_home = ube[:jetty_user_home]
jetty_user = ube[:jetty_user]
ubuntu_user_home = ube[:ubuntu_home]
ubuntu_user = ube[:ubuntu_user]
kinesis_user = ubuntu_user

if is_jetty_layer
  directory "#{jetty_user_home}" do
    action :create
    owner jetty_user
    group jetty_user
    mode "0755"
  end

  template "#{jetty_user_home}/.ube.properties" do
    source "ube.properties.generic.erb"
    owner jetty_user
    group jetty_user
    mode "0644"
  end
end

if is_analytics_layer
  directory "#{ubuntu_user_home}" do
    action :create
    owner ubuntu_user
    group ubuntu_user
    mode "0755"
  end

  template "#{ubuntu_user_home}/.ube.properties" do
    source "ube.properties.generic.erb"
    owner kinesis_user
    group kinesis_user
    mode "0644"
  end
end


