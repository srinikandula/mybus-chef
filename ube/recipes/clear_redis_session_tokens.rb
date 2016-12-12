# Recipe name: clear_redis_session_tokens
#
# This will delete all of the session tokens that are stored in redis


# only run this recipe on a redis
return unless node[:opsworks][:instance][:layers].include? node[:ube][:redis_layer_name] rescue false


execute "clear session info from redis" do
  command 'redis-cli KEYS "sesTok:*" | xargs redis-cli DEL'
end

execute "clear session info from redis for API Key users" do
  command 'redis-cli KEYS "apiKey:*" | xargs redis-cli DEL'
end