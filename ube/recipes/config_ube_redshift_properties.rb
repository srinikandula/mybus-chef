# Recipe name: config_ube_redshift_properties
#
# This will generate the .ube.redshift.properties file on the ube layer
#

# only run this recipe on a jetty layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:jetty_layer_name] rescue false

ube = node[:ube]
jetty_user_home = ube[:jetty_user_home]


template "#{jetty_user_home}/.ube.redshift-config.properties" do
  source 'ube.redshift.properties.erb'
  owner 'jetty'
  group 'jetty'
  mode '0644'
  variables({
      :url => node[:ube][:redshift][:url],
      :user => node[:ube][:redshift][:user],
      :password => node[:ube][:redshift][:password]
  })
end
