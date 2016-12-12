# Recipe name: setup_redis_sentinel
#
# This will install and configure a redis master instance and then
# installs sentinel to monitor the same master
#
# only run this recipe on a redis master layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:redis_master_layer_name] rescue false

redis_log_file = node[:ube][:redis_log_file]
redis_master_port = node[:ube][:redis_master_port] || 6379
node[:redisio] ||= {}
node.default[:redisio][:servers] ||= []
node.default[:redisio][:servers] << {'port' => redis_master_port, 'logfile' => redis_log_file }
include_recipe 'redisio::default'
include_recipe 'redisio::enable'

include_recipe 'ube::no_op'

redis_master_ip = node[:opsworks][:instance][:private_ip] rescue nil

log "configuring the redis sentinel now"

redis_sentinel_log_file = node[:ube][:redis_sentinel_log_file]
redis_sentinel_port = node[:ube][:redis_sentinel_port] || 26379

node.default[:redisio][:sentinels] ||= []
node.default[:redisio][:sentinels] << {'port' => redis_sentinel_port, 'name' => node[:ube][:redis_sentinel_name],
                                       'master_ip' => redis_master_ip, 'master_port' => redis_master_port, 'logfile' => redis_sentinel_log_file }

log "sentinel params : \n#{node.default[:redisio][:sentinels].inspect}\n\n"

include_recipe 'redisio::sentinel'
include_recipe 'redisio::sentinel_enable'
