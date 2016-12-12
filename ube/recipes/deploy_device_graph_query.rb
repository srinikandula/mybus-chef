# Recipe name: deploy_device_graph_query
#
#
disabled = true

if disabled
  Chef::Log.warn('ube::deploy_device_graph_query is currently disabled.')
  return
end


node.set[:ube][:dev_graph_app_name] = 'query'

include_recipe 'ube::config_dev_graph_service'
include_recipe 'ube::deploy_device_graph_app'