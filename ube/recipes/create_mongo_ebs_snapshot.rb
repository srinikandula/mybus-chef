# Recipe name: create_mongo_ebs_snapshot
#
# deregisters the instance from its ELB
#

# only run this recipe on a mongo master layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:mongo_master_layer_name] rescue false

log "instance info: #{node[:opsworks][:instance].inspect}"

aws_access_key_token = node[:ube][:s3_access_key]
aws_secret_key = node[:ube][:s3_secret_key]

if aws_access_key_token && aws_secret_key
  instance_host_name = node[:opsworks][:instance][:hostname] rescue 'mongodb'

  include_recipe 'aws'

  if node[:ube][:mongo_ebs_volume_id]
    # take a snapshot
    aws_ebs_volume "create ebs snapshot of database" do
      aws_access_key aws_access_key_token
      aws_secret_access_key aws_secret_key
      volume_id node[:ube][:mongo_ebs_volume_id]
      description "#{instance_host_name}-#{Time.now.strftime("%Y%m%d-%H%M")}"
      action :snapshot
    end

    # prune old snapshots
    aws_ebs_volume "prune old snapshots" do
      aws_access_key aws_access_key_token
      aws_secret_access_key aws_secret_key
      volume_id node[:ube][:mongo_ebs_volume_id]
      snapshots_to_keep (node[:ube][:mongo_ebs_snapshot_count] || 3)
      action :prune
    end
  end
end