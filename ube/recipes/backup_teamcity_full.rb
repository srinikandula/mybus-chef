# Recipe name: backup_teamcity_full
#
# This will perform a full backup of TeamCity and optionally upload the archive to S3.
#

#only run this recipe on a teamcity server layer
return unless node[:opsworks][:instance][:layers].include? node[:ube][:teamcity_server_layer_name] rescue false

tc_bin = "#{node[:ube][:teamcity][:app_root]}/bin"

