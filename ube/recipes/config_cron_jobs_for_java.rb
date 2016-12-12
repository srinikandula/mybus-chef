# Recipe name: config_cron_jobs_for_java
#
# This will configure cron jobs for the jetty server. 
# It will only run on the OpsWorks jetty layer
#

# only run this recipe on a jetty layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:jetty_layer_name] rescue false

ube = node['ube']
scripts_dir = ube[:scripts_dir]

# this job got moved to the mongo server
cron "reap screens and sessions" do
  action :delete
end
