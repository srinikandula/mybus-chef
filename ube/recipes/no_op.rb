# Recipe name: no_op
#
# does nothing except log information about the instance
#


log "ube properties: \n#{node[:ube].inspect}\n\n"

log "node[:opsworks]: \n#{node[:opsworks].inspect}\n\n"

log "node[:opsworks][:instance]: \n#{node[:opsworks][:instance].inspect}\n\n"

log "node[:opsworks][:instance][:layers]: \n#{node[:opsworks][:instance][:layers].inspect}\n\n"




