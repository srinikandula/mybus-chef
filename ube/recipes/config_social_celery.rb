# Recipe name: config_social_celery
#
# This will configure the Celery Social Data Miner application by
# generating a configuration file in the ubuntu home directory.
# It contains info for connecting to RabbitMQ as well as the names
# of relevant resources, such as queues, exchanges, and routing keys.
#

# only run this recipe on a celery layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:celery_layer_name] rescue false

ube = node['ube']
ubuntu_home = ube[:ubuntu_home]
rabbitmq_layer_name = ube[:rabbitmq_layer_name]
rabbit_instances = (node['opsworks']['layers'][rabbitmq_layer_name]['instances'] rescue {}) || {}
Chef::Log.info("rabbit_instances: #{rabbit_instances}")

include_recipe 'ube::setup_social_celery_dirs'

raise 'No RabbitMQ instances found.' if rabbit_instances.nil? || rabbit_instances.empty?

should_detect_host = ube[:rabbitmq][:host].to_s.strip.empty?

if should_detect_host
  Chef::Log.info('A RabbitMQ host will be searched for, because none was specified in the node configuration.')
else
  Chef::Log.info("Using RabbitMQ host #{ube[:rabbitmq][:host]}, defined in the node configuration.")
end

rabbitmq_cfg = ube[:rabbitmq]
rabbit_host = ube[:rabbitmq][:host]

if should_detect_host
  rabbit_instance = nil
  if rabbit_instances.size == 1
    rabbit_instance = rabbit_instances.first[1]
  else
    online_instances = []
    Chef::Log.info('Searching for online RabbitMQ instances...')
    rabbit_instances.each do |name, instance|
      if instance['status'] == 'online'
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


template "/#{ubuntu_home}/.social-celery-config.json" do
  source "social-celery-config.json.erb"
  owner "ubuntu"
  group "ubuntu"
  mode '0644'
  variables({
                :rabbit_host => rabbit_host,
                :rabbitmq => rabbitmq_cfg,
                :resource_names => ube[:social_celery_resource_names]
            })
end