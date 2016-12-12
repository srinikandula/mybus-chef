# Recipe name: setup_rabbitmq_properties_teamcity
#
# This will update the custom .ube.rabbitmq.test.properties file used by java for communicating
# with RabbitMQ.  But this is specifically for TeamCity, which uses the test version.

ube = node[:ube]

rabbit_host = 'localhost'
rabbitmq_username = ube[:rabbitmq][:username]
rabbitmq_password = ube[:rabbitmq][:password]

rabbit_template_vars = {
    :host => rabbit_host,
    :username => rabbitmq_username,
    :password => rabbitmq_password
}

# TeamCity servers need the 'test' version of the file
template "/home/not-opsworks/.ube.rabbitmq.test.properties" do
  source 'ube.rabbitmq.properties.erb'
  owner 'not-opsworks'
  group 'opsworks'
  mode '0640'
  variables(rabbit_template_vars)
end


