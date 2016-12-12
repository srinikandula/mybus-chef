# Recipe name: setup_mongo_secondary
#
# installs mongo and configures this node as a secondary in a replicaset

# only run this recipe on an analytics xformer layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:mongo_secondary_layer_name] rescue false

node.set[:mongodb][:replica_priority] = node[:ube][:mongo_secondary_priority]

include_recipe 'mongodb::mongodb_org_3_repo'
include_recipe 'mongodb::replicaset'

