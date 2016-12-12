
require 'chef/node'

class Chef::ResourceDefinitionList::OpsWorksHelper

  # true if we're on opsworks, false otherwise
  def self.opsworks?(node)
    node['opsworks'] != nil
  end

  # return Chef Nodes for this replicaset / layer
  def self.replicaset_members(node)
    members = []

    primary_layer_name = node[:ube][:mongo_master_layer_name]
    secondary_layer_name = node[:ube][:mongo_secondary_layer_name]
    Chef::Log.info("primary_layer_name: '#{primary_layer_name}', secondary_layer_name: '#{secondary_layer_name}'")
    primary_instances = (node['opsworks']['layers'][primary_layer_name]['instances'] rescue nil) || {}
    Chef::Log.info("primary_instances: #{primary_instances}")
    secondary_instances = (node['opsworks']['layers'][secondary_layer_name]['instances'] rescue nil) || {}
    Chef::Log.info("secondary_instances: #{secondary_instances}")
    instances = primary_instances.merge(secondary_instances)
    Chef::Log.info("instances: #{instances}")

    instances.each do |name, instance|
      if instance['status'] == 'online'
        member = Chef::Node.new
        member.name(name)
        member.default['fqdn'] = instance['private_dns_name']
        member.default['ipaddress'] = instance['private_ip']
        member.default['hostname'] = name
        mongodb_attributes = {
          'config' => {
            'port' => node['mongodb']['config']['port'],
          },
          'replica_arbiter_only' => node['mongodb']['replica_arbiter_only'],
          'replica_build_indexes' => node['mongodb']['replica_build_indexes'],
          'replica_hidden' => node['mongodb']['replica_hidden'],
          'replica_slave_delay' => node['mongodb']['replica_slave_delay'],
          'replica_priority' => node['mongodb']['replica_priority'],
          'replica_tags' => node['mongodb']['replica_tags'],
          'replica_votes' => node['mongodb']['replica_votes']
        }
        member.default['mongodb'] = mongodb_attributes
        members << member
      end
    end
    members
  end

end
