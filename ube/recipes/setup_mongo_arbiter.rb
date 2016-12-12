# Recipe name: setup_mongo_arbiter
#
# installs mongo and configures this node as an arbiter

# only run this recipe on an analytics xformer layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:mongo_arbiter_layer_name] rescue false

node.override[:mongodb][:replica_arbiter_only] = true

include_recipe 'mongodb::mongodb_org_3_repo'
include_recipe 'mongodb::replicaset'

