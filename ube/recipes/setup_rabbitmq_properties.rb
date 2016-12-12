# Recipe name: setup_rabbitmq_properties
#
# This will update the custom .ube.rabbitmq.properties file used by java for communicating
# with celery.
# THIS IS ONLY FOR EITHER THE JAVA / JETTY LAYER.
#

# only run this recipe on a jetty layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:jetty_layer_name] rescue false

ube = node[:ube]

jetty_user_home = ube[:jetty_user_home]
jetty_user = ube[:jetty_user]
rabbitmq_layer_name = ube[:rabbitmq_layer_name]
search('aws_opsworks_layer').each do |layer|
  Chef::Log.info("layer: #{layer.inspect}")
end

=begin
return unless search('aws_opsworks_layer').any? { |l| l['shortname'] == node[:ube][:rabbitmq_layer_name] }

rabbit_instances = (node[:opsworks][:layers][rabbitmq_layer_name]['instances'] rescue {}) || {}
Chef::Log.info("rabbit_instances: #{rabbit_instances}")

should_detect_host = ube[:rabbitmq][:host].to_s.strip.empty?
raise 'No RabbitMQ instances found.' if should_detect_host && (rabbit_instances.nil? || rabbit_instances.empty?)

if should_detect_host
  Chef::Log.info('A RabbitMQ host will be searched for, because none was specified in the node configuration.')
else
  Chef::Log.info("Using RabbitMQ host #{ube[:rabbitmq][:host]}, defined in the node configuration.")
end

rabbit_host = ube[:rabbitmq][:host]

rabbitmq_username = ube[:rabbitmq][:username]
rabbitmq_password = ube[:rabbitmq][:password]

if should_detect_host
  rabbit_instance = nil
  if rabbit_instances.size == 1
    rabbit_instance = rabbit_instances.first[1]
  else
    online_instances = []
    Chef::Log.info('Searching for online RabbitMQ instances...')
    rabbit_instances.each do |name, instance|
      # Possible status values are:
      # "requested"
      # "booting"
      # "running_setup"
      # "online"
      # "setup_failed"
      # "start_failed"
      # "terminating"
      # "terminated"
      # "stopped"
      # "connection_lost"
      unless %w(terminating terminated stopped).include?(instance['status'])
        online_instances << instance
        Chef::Log.info("Found RabbitMQ online instance: #{name}, instance id: #{instance['id']}")
      end
    end
    raise "No online RabbitMQ instances were found in the layer #{rabbitmq_layer_name}" if online_instances.empty?
    raise "Too many (#{online_instances.size}) online RabbitMQ instances were found in the layer #{rabbitmq_layer_name}" if online_instances.size > 1
    rabbit_instance = online_instances[0]
  end
  if rabbit_instance.nil?
    raise 'Unable to find a suitable host for rabbitmq.'
  end
  Chef::Log.info("Discovered 1 RabbitMQ host: #{rabbit_instance}")
  rabbit_host = rabbit_instance['private_ip']
end
=end

rabbit_host = ube[:rabbitmq][:host]

rabbitmq_username = ube[:rabbitmq][:username]
rabbitmq_password = ube[:rabbitmq][:password]

directory "#{jetty_user_home}" do
  action :create
  owner jetty_user
  group jetty_user
  mode '0755'

end

template "#{jetty_user_home}/.ube.rabbitmq.properties" do
  source 'ube.rabbitmq.properties.erb'
  owner jetty_user
  group jetty_user
  mode '0644'
  variables({
      :host => rabbit_host,
      :username => rabbitmq_username,
      :password => rabbitmq_password
  })
end

