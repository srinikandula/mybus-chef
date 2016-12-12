# Recipe name: config_cron_jobs_for_mongo
#
# This will configure cron jobs for the mongo server..
# It will only run on the OpsWorks mongo layer
#
# If the attribute node[:ube][:skip_mongo_cron_jobs] is set to a truthy value, then
# this recipe will be skipped and no cron jobs will be created.
#

# only run this recipe on a mongo master layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:mongo_master_layer_name] rescue false

if node[:ube][:skip_mongo_cron_jobs]
  Chef::Log.info('ube.skip_mongo_cron_jobs was true, so no cron jobs will be setup')
  return
end

ube = node['ube']
scripts_dir = ube[:scripts_dir]
region = node[:opsworks][:instance]['region']
stack_id = node[:opsworks][:stack]['id']
ebs_snapshot_recipe = 'ube::create_mongo_ebs_snapshot'
screen_reaper_recipe = 'ube::reap_screens'
instance_id = node[:opsworks][:instance]['id']
ebs_snapshot_interval = node[:ube][:mongo_ebs_snapshot_interval_hours].to_i
ebs_snapshot_interval = 3 if ebs_snapshot_interval == 0 || ebs_snapshot_interval >= 24
log "ebs_snapshot_interval is #{ebs_snapshot_interval}"

#
# Note: info for how to run recipes from the command line was found here:
# https://forums.aws.amazon.com/thread.jspa?messageID=465591&#465591
#


# ====================== install AWS CLI ====================================

include_recipe 'ube::install_aws_cli'

directory "/root/.aws" do
  action :create
end

template "/root/.aws/config" do
  source "aws_config.erb"
  owner "root"
  group "root"
  mode "0600"
end

# ====================== setup screen reaper job ============================

reaper_command = %Q^/usr/local/bin/aws opsworks create-deployment --region #{region} --stack-id=#{stack_id} --command='{ "Name": "execute_recipes", "Args": {"recipes": ["#{screen_reaper_recipe}"]} }' --instance-ids=#{instance_id}^

log "reaper_command is #{reaper_command}"

# this gets put into /var/spool/cron/crontabs
cron "execute screen reaper task recipe" do
  minute "0,30"
  command reaper_command
  action :create
end


# ====================== setup EBS snapshot job ==============================

ebs_snapshot_command = %Q^/usr/local/bin/aws opsworks create-deployment --region #{region} --stack-id=#{stack_id} --command='{ "Name": "execute_recipes", "Args": {"recipes": ["#{ebs_snapshot_recipe}"]} }' --instance-ids=#{instance_id}^

log "ebs_snapshot_command is #{ebs_snapshot_command}"



# generate the cron hours parameter. e.g.:  "0,3,6,9,12,15,18,21"
cron_hours = []
(24 / ebs_snapshot_interval).times {|v| cron_hours.push v*ebs_snapshot_interval}
cron_hours_param = cron_hours.join ','

# this gets put into /var/spool/cron/crontabs
cron "create EBS snapshot and prune old ones" do
  minute "37"
  hour cron_hours_param
  command ebs_snapshot_command
  action :create
end


# ========================== setup Stuck Asset Fixer =========================

directory scripts_dir do
  action :create
end


cookbook_file "#{scripts_dir}/fix_stuck_conversions.sh" do
  source "fix_stuck_conversions.sh"
  mode '0755'
end

cron "fix stuck asset conversions" do
  minute "15/*"
  command  "#{scripts_dir}/fix_stuck_conversions.sh"
  action :create
end