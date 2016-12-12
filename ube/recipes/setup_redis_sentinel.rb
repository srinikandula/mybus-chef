# Recipe name: setup_redis_sentinel
#
# This will install and configure a redis sentinel instance
#
# only run this recipe on a redis sentinel layer
return unless node[:opsworks][:instance][:layers].include? 'redis_sentinel' rescue false

#only if the master instance is running
return unless node[:opsworks][:layers][:redis_master][:instances].any rescue false

redis_master_ip = node[:opsworks][:layers][:redis_master][:instances].first[1][:private_ip] rescue nil

log "Running recipe setup_redis_sentinel"

redis_master_port =  node[:ube][:redis_master_port] || 6379

node[:redisio] ||= {}
node.default[:redisio][:sentinels] ||= []
node.default[:redisio][:sentinels] << {'port' => '26379', 'name' => 'mycluster', 'master_ip' => redis_master_ip, 'master_port' => redis_master_port, 'logfile' => '/var/log/redis_sentinel.log' }

include_recipe 'redisio::sentinel'
include_recipe 'redisio::sentinel_enable'
