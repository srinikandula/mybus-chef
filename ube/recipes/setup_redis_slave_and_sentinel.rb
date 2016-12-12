# Recipe name: setup_redis_slave_and_sentinel
#
# This will configure the a slave and sentinel on the instance.
#
# only run this recipe on a redis slave layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:redis_slave_layer_name] rescue false

#only if the master instance is running
return unless node[:opsworks][:layers][:redis_master][:instances].any rescue false

redis_master_ip = node[:opsworks][:layers][:redis_master][:instances].first[1][:private_ip] rescue nil
redis_master_port =  node[:ube][:redis_master_port] || 6379
redis_log_file = node[:ube][:redis_log_file]
redis_slave_port = node[:ube][:redis_slave_port] || 6379

log "configuring the redis slave now"
node[:redisio] ||= {}
node.default[:redisio][:servers] ||= []
node.default[:redisio][:servers] << {'port' => redis_slave_port, 'slaveof' => { 'address' => redis_master_ip,
                                                                                'port' => redis_master_port},
                                     'logfile' => redis_log_file }
log "node[:redisio][:servers]: \n#{node[:redisio][:servers].inspect}\n\n"
include_recipe 'redisio::default'
include_recipe 'redisio::enable'

log "configuring the redis sentinel now"
redis_sentinel_log_file = node[:ube][:redis_sentinel_log_file]
redis_sentinel_port = node[:ube][:redis_sentinel_port] || 26379
node.default[:redisio][:sentinels] ||= []
node.default[:redisio][:sentinels] << {'port' => redis_sentinel_port, 'name' => node[:ube][:redis_sentinel_name],
                                       'master_ip' => redis_master_ip, 'master_port' => redis_master_port,
                                       'logfile' => redis_sentinel_log_file }
log "sentinel params : \n#{node.default[:redisio][:sentinels].inspect}\n\n"
include_recipe 'redisio::sentinel'
include_recipe 'redisio::sentinel_enable'

